[🇯🇵 日本語](cicd-guide.md) | [🇬🇧 English](cicd-guide.en.md)

# CI/CD Guide

CI/CD design guide for repositories. Use this to decide the verification and deployment paths when creating a new repo.
Corresponds to Layer 3 (public verification) in `harness-guide.md` and connects with the role separation in `issue-driven-workflow.md`.

Two design principles: **CI runs the same checks the Agent runs locally** (redundancy catches what the Agent missed before PR). **Deployment is automatic push-style after CI passes** (no manual operations).

---

## 1. Two Repo Patterns

New repos fall into two categories, which determine the CI/CD configuration.

| Pattern | Typical Use | CI | Deployment |
|---|---|---|---|
| **Public App** | Web app, portfolio project | GitHub Actions (type check → test → build) | Auto-deploy to self-hosted server → expose via Cloudflare Tunnel |
| **Internal Tool** | Data processing scripts, automation, shell commands | Optional (local verification may suffice) | None (local execution or distributed via dotfiles) |

Public apps are externally visible, so they require CI and deployment. Internal tools are personal-use only, so Layer 2 (local verification) from `harness-guide.md` is sufficient.

---

## 2. CI

`.github/workflows/ci.yml`. Triggered on push / pull_request, runs the same verification defined in `harness-guide.md`.

| Category | CI Runs |
|---|---|
| Config | Syntax check (`flake check` / `zsh -n`, etc.) |
| Logic | Syntax check + test (if available) |
| Web | Type check → test → build |

```yaml
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4   # swap for appropriate language
        with: { node-version: 24, cache: npm }
      - run: npm ci
      - run: npm run typecheck
      - run: npm test
```

Internal tools can use the same structure if CI is desired, but in most cases the Agent's local verification (syntax check, dry run) is sufficient and CI can be omitted.

---

## 3. Deployment (Public Apps)

Triggered on push to main, after CI passes. Transfers to self-hosted server via Tailscale and restarts.
Two variants depending on Docker usage.

### 3-1. Compose Type

GitHub Actions → Tailscale → scp → `docker compose up -d --build`.
Most web apps use this variant.

```yaml
deploy:
  needs: test
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Connect to Tailscale
      uses: tailscale/github-action@v3
      with:
        oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
        oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
        tags: tag:ci
    - name: Sync source
      uses: appleboy/scp-action@v0.1.7
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        source: "."
        target: "~/apps/{project}/"
    - name: Up
      uses: appleboy/ssh-action@v1
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        script: |
          cd ~/apps/{project}
          docker compose up -d --build
```

### 3-2. Binary Type

Build → scp → systemd restart. Used when cross-compilation (Linux amd64) is needed.

```yaml
    - name: Build
      run: {cross-compile command}   # e.g., GOOS=linux GOARCH=amd64 go build
    - name: Copy binary
      uses: appleboy/scp-action@v0.1.7
      with: { host: ${{ secrets.DEPLOY_HOST }}, ..., source: "{binary}", target: "/tmp/" }
    - name: Restart service
      uses: appleboy/ssh-action@v1
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        script: |
          sudo mv /tmp/{binary} /opt/{name}/{binary}
          sudo chmod +x /opt/{name}/{binary}
          sudo systemctl restart {name}
```

---

## 4. Demo Publishing (Cloudflare Tunnel)

Public apps run on the self-hosted server and are exposed as `{subdomain}.{domain}` via Cloudflare Tunnel.
Since ports are not directly exposed, multiple projects can coexist while appearing as individual domains externally.

DNS route additions and tunnel ingress configuration are handled in the server-side operations procedures. Host-specific values such as hostnames, tunnel IDs, and port assignments are not written in the repo — they are managed via Secrets and operations documentation.

---

## 5. Secrets

Secrets used in GitHub Actions. Values are never stored in the repo.

| Secret | Purpose |
|---|---|
| `DEPLOY_HOST` | Deployment target host (via Tailscale) |
| `DEPLOY_USER` | Deployment target user |
| `SSH_PRIVATE_KEY` | SSH private key for deployment target |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth Client ID |
| `TS_OAUTH_SECRET` | Tailscale OAuth Secret |
| `{APP}_API_KEY` | App-specific external API key |

---

## 6. Dependency Updates (Dependabot)

Decide by rule, not per PR — don't deliberate over each individual PR.

| Situation | Handling |
|---|---|
| minor/patch + CI green | Auto-merge (unconditional) |
| major | Hold. Once several accumulate, review the changelogs and decide in a batch (merge / close / follow-up Issue) |
| CI red | Don't merge. Treat as a candidate for closing (`@dependabot ignore this major version` for a permanent ignore) |
| Repo without CI | Auto-merge prohibited. Use grouping for notification only |

The setup is three pieces. Templates live in `repo-standardize`'s `reference/`.

1. `.github/dependabot.yml` — weekly for every ecosystem, with minor/patch grouped. For registry-based ecosystems (npm/pip/composer/gomod), add `cooldown: default-days: 7` (supply-chain hardening: many malicious releases are pulled within a few days of publishing)
2. `.github/workflows/dependabot-auto-merge.yml` — runs `gh pr merge --auto` for everything except major
3. Repo settings — `allow_auto_merge: true` plus a ruleset on main (required status checks list the CI job name; bypass allows Repository admin / always, so the user's direct pushes are not blocked)

Compatibility score is CI statistics from other people's repos — not a decision factor. Your own repo's CI > semver type >> score.

Note: because auto-merge commits originate from `GITHUB_TOKEN`, **push-triggered workflows after the merge (e.g. deploy) do not fire**. This delays dependency updates reaching a demo until the next human push — acceptable. Only switch to a PAT for repos that need immediate reflection.

---

## 7. Connection to Role Separation

For repos with CI auto-deployment, the role table from `issue-driven-workflow.md` changes.

| Role | Deployment Task |
|---|---|
| CI | After merge to main, test passes → auto-deploy |
| user | PR review and merge only |

For internal tools and other manually-run repos, the role remains "user: execute startup command".
