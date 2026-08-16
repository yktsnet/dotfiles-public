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
| **Public App** | Web app, portfolio project | GitHub Actions (syntax/type check → test → build) | Auto-deploy to Cloudflare (Pages / Workers) |
| **Internal Tool** | Data processing scripts, automation, shell commands | Optional (local verification may suffice) | None (local execution or distributed via dotfiles) |

Public apps are externally visible, so they require CI and deployment. Internal tools are personal-use only, so Layer 2 (local verification) from `harness-guide.md` is sufficient.

**Deployment targets converge on Cloudflare.** Do not build new paths that ship to a self-hosted server (VPS, etc.). Keeping a server alive, patching its OS, and managing its keys are permanent operational costs, so anything that fits on serverless goes on serverless.

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
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6   # swap for appropriate language
        with: { node-version: 24 }
      - run: npm test                 # repos without dependencies call node --test etc. directly
```

Repos with no package dependencies do not get an `npm ci` step. The point is to **keep CI identical to the commands actually being run**, not to follow the template.

Internal tools can use the same structure if CI is desired, but in most cases the Agent's local verification (syntax check, dry run) is sufficient and CI can be omitted.

---

## 3. Deployment (Cloudflare)

### 3-1. Pages (static sites, Pages Functions)

This is the default. **Use the GitHub integration and do not write a deploy job in Actions.** Cloudflare detects the push, builds, and serves. CI (Actions) and deployment (Cloudflare) stay independent, and no deployment API token has to live in GitHub.

The initial connection is done in the Cloudflare dashboard (the user's job). Three settings:

| Item | Content |
|---|---|
| Build command | Empty if there is none; otherwise the same command used locally |
| Build output directory | Where the static files to serve are placed (e.g. `public` / `dist`) |
| Environment variables | Production values live on the Cloudflare side; the repo only carries the keys in `.env.example` |

`functions/` placed at the repository root is automatically deployed as Pages Functions.

Only when you need to wait for CI to pass before serving, switch from the GitHub integration to running `wrangler pages deploy` from Actions. That adds token management, so don't adopt it until it is needed.

### 3-2. Workers

Run `wrangler deploy` from Actions.

```yaml
deploy:
  needs: test
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v6
    - uses: cloudflare/wrangler-action@v3
      with:
        apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

`wrangler` is denied in the Agent's settings.json (the Web category in `harness-guide.md`). Deployment is run by CI or the user, never by the Agent.

---

## 4. Publishing and Access Control

Custom domains for Pages / Workers are assigned on the Cloudflare side. No port exposure and no long-running cloudflared are needed.

Apps that are not meant to be public (personal internal tools, etc.) sit behind **Cloudflare Access**, restricted by Google login or similar. In that case the app implements no authentication of its own and is written on the assumption that only requests that passed Access arrive. State that assumption in the README or CLAUDE.md.

---

## 5. Secrets

Secrets used in GitHub Actions. Values are never stored in the repo.

| Secret | Purpose |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Workers / Pages deployment (only when run from Actions) |
| `CLOUDFLARE_ACCOUNT_ID` | Same as above |
| `{APP}_API_KEY` | App-specific external API key |

**Values the app needs at runtime belong to Cloudflare's environment variables / Secrets Store, not to GitHub.** GitHub Secrets are a container for building and deploying, not the configuration of the runtime environment.

When Pages is operated through the GitHub integration, the Cloudflare entries in this table become unnecessary.

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

For repos with CI auto-deployment, the role table in `issue-driven-workflow.md` changes.

| Role | Work at deployment time |
|---|---|
| CI / Cloudflare | Builds and serves automatically after the merge into main |
| user | PR review and merge, plus the initial connection on the Cloudflare side (dashboard operation) |

Creating the Cloudflare project, connecting GitHub, assigning the custom domain, and setting Access policies are GUI operations the user performs. The Agent is responsible up to the files inside the repo (`ci.yml`, `functions/`, `.env.example`).

Internal tools and other manually-run repos keep "user: runs the launch command".
