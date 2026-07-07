[🇯🇵 日本語](issue-driven-workflow.md) | [🇬🇧 English](issue-driven-workflow.en.md)

# Issue-Driven Development Workflow

An issue-driven development flow leveraging AI Agents (Claude Code / Jules).
Separates design, implementation, and verification to prevent Agent runaway while developing at speed.

---

## Phases

Each repository is in one of two phases. The user decides the phase and states it in the repository's CLAUDE.md (the Consultant never decides or changes it). If nothing is stated, Issue-Driven is the default.

- **MVP phase**: early stage where direction and structure are still fluid. The Consultant may implement directly in an open chat.
- **Issue-Driven phase**: direction is settled. Follow the role separation below.

If the phase is unclear, do not implement; ask the user.

## Role Separation (Issue-Driven phase)

| Role | Work |
|---|---|
| **Consultant** (WebChat / desktop Code open chat) | Issue design, spec discussion, documentation. **Never implements** |
| **Builder** (CLI Code / Jules launched via issue()) | Code edits, static checks, and commits based on the Issue |
| **user** | Deploy, service restarts, verification, merge |

- The Consultant goes only as far as writing the Issue file (via the `/new-issue` skill). No code; stop once it is written.
- The same applies when Code plays the Consultant (`main`, open chat). When asked to implement, create an Issue with `status: open` and stop; the user launches implementation via issue().
- The Builder (Code) implements from the Issue and stops at a local commit. Pushing, PR creation, and production commands are forbidden; publishing happens in `issue-finish` after the user's review.
- The Builder (Jules) implements in a cloud sandbox and creates its PR on the cloud side.
- Verification steps: the Builder writes them in the commit message body under `## 検証手順`; `issue-finish` turns that body into the PR description, and the user executes the steps.

---

## Supported Agents

Select the Agent (Code / Jules) on the ZSH side; no guard is configured there.
Branch management differs by the Agent's execution environment.

| Agent | Environment | Branch management | Persistent instruction file |
|---|---|---|---|
| **Claude Code (Code)** | Local | Creates a worktree + branch and runs in isolation | `CLAUDE.md` |
| **Jules** | Cloud sandbox | No local branch (remote-only) | `AGENTS.md` |

---

## Project Layout

Each repository holds a persistent instruction file for the selected Agent and the shared management directories.

```
{app_root}/
├── CLAUDE.md        # Instructions for Claude Code (incl. static checks and verification templates)
├── AGENTS.md        # Instructions for Jules
├── .claude/
│   └── settings.json        # Permissions / accident prevention (harness-guide.md)
├── context/         # Shared context
│   ├── conventions.md
│   └── structure.md
└── issues/          # Local issue management
    ├── 00_template.md
    └── {NN}_{slug}.md
```

The `pr-workflow` (Builder) and `new-issue` (Consultant) skills are not copied per repository; they live in the global `~/.claude/skills/` (managed by dotfiles). Repository-specific checks and verification steps go in each repository's CLAUDE.md, which the skills reference.

---

## Issue Format

```markdown
## {Title}
id: {00}
branch-slug: {slug}
github_issue:
status: draft | open | close
type: cleanup | fix | feat
対象: {every file to change or create; mark new files with (新規)}
内容: {purpose and outline only}
確認: {static checks the Agent runs before submitting}

---

{free-form details that do not fit above}
```

### Lifecycle

```
draft  → (design complete) →  open  → (issue-finish) →  close
```

- `draft`: under design. Excluded from issue() selection.
- `open`: ready to implement. Selectable by issue(). The Builder never changes `status:`.
- `close`: done. Updated by issue-finish.

### Derived Issues

When verification finds a problem, close the original Issue and create a derived one such as `{id}a`.

Never reopen the original Issue or send follow-up prompts into the same Agent session. Always start from an Issue file to keep the record.

### Information Security

- Never write concrete connection details in human-readable text (Issues, PRs, commit messages, comments). Use the `<PLACEHOLDER>` entries defined in the `secrets-agents/` dictionaries instead.
- Masked: real domains, public ports, Tunnel UUIDs, cloudflared paths, production absolute paths, Tailscale IPs / SSH usernames, WiFi SSIDs, app-specific values (accounts / strategy names). Not masked: device names, localhost, development ports, repository-relative paths, LocalStack resource names.
- Dictionary files: `network.md` / `paths.md` / `cloud.md` / `apps.md` (conventions in `secrets-agents/README.md`). The `secrets-agents/` directory itself is never published.
- When a value that does not exist locally (accounts, etc.) is entered into an app, append it to the matching dictionary as you go.

---

## Shell Functions

### `issue` or `jules`

Selects the target Issue and launches the Agent. Local files under `issues/` are the single source of truth; the GitHub Issue is a record-only mirror that `issue-finish` leaves behind as "create → close immediately" on completion.

1. Select an Issue with `status: open` via `fzf` (with preview).
2. Commit `issues/` changes to `main` (so the worktree branch contains the Issue and the PR diff stays free of `issues/` noise). The push is done by `issue-finish` before it creates the PR.
3. Per Agent:
   - **Code**: create worktree `{repo}.wt/{id}-{slug}` on branch `claude/{id}-{slug}` and launch the `claude` command inside it. The main checkout stays clean and multiple Issues can run in parallel. No stashing needed (the worktree is cut from HEAD, so uncommitted changes are not carried over).
   - **Jules**: no local branch; feed the Issue content directly into a cloud session via `jules new`.

Code never touches GitHub (pushing, PR creation, and the record Issue are all handled by `issue-finish`).

### `issue-abort` or `jules-abort`

Aborts the task in progress and discards changes.

1. Per Agent:
   - **Code**: pick a `claude/*` worktree via `fzf` and force-delete both the worktree and the branch (`git worktree remove --force` + `git branch -D`).
   - **Jules**: skip local branch operations; handle the cloud session manually (`jules remote`, etc.).

### `issue-finish` or `jules-finish`

Publishes the reviewed branch (push → PR creation → merge), cleans up branches, and closes the Issue in one pass. Only what the user has reviewed locally ever reaches the remote.

1. Pick a `claude/*` branch not yet merged into `main` via `fzf` (previewing the commit log and diff).
2. Push `main` and the selected branch, create the PR with the commit message body as its description (`gh pr create`), then run `gh pr merge --merge`.
3. Run `git pull --prune` (the main checkout always stays on main).
4. Remove merged `claude/*` worktrees and delete local and remote branches in bulk.
5. Create the record GitHub Issue and close it immediately (if `github_issue:` already has a number, close only). A failed creation never blocks the flow.
6. Update the local Issue file to `status: close`, commit to `main`, and push.

Jules creates its PR on the cloud side, so `jules-finish` only pulls `main` after the merge.
