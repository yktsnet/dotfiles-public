[🇯🇵 日本語](issue-driven-workflow.md) | [🇬🇧 English](issue-driven-workflow.en.md)

# Issue-Driven Development Workflow

An issue-driven development flow leveraging AI Agents (Claude Code).
Separates design, implementation, and verification to prevent Agent runaway while developing at speed.

---

## Phases

The phase concept (MVP phase / Issue-Driven phase) applies only to **repositories on the publishing pipeline**. Each such repository is in one of the two phases. The user decides the phase and states it in the repository's CLAUDE.md (the Consultant never decides or changes it). If nothing is stated, Issue-Driven is the default.

- **MVP phase**: early stage where direction and structure are still fluid. The Consultant may implement directly in an open chat.
- **Issue-Driven phase**: direction is settled. Follow the role separation below.

If the phase is unclear, do not implement; ask the user.

Moving from the MVP phase to the Issue-Driven phase requires the guarantee ledger to be in official operation (`guarantee-audit` promotion complete: `docs/guarantees.md` no longer carries `(Draft)`). The phase change (recording it in the repository's CLAUDE.md) and laying the ledger are bundled as a single event.

Repositories off the publishing pipeline (personal infrastructure, ops repositories, and repositories being prepared for publication) do not use the phase concept. There the Consultant may implement directly in an open chat by default, and the role separation below applies only when the user explicitly asks for an Issue.

## Role Separation (Issue-Driven phase)

| Role | Work |
|---|---|
| **Consultant** (WebChat / desktop Code open chat) | Issue design, spec discussion, documentation. **Never implements** |
| **Builder** (CLI Code launched via issue()) | Code edits, static checks, and commits based on the Issue |
| **user** | Deploy, service restarts, verification, merge, approve the Issue's guarantee section |

- The Consultant goes only as far as writing the Issue file (via the `/new-issue` skill). No code; stop once it is written.
- The same applies when Code plays the Consultant (`main`, open chat). When asked to implement, create an Issue with `status: draft` and stop; the user approves the guarantee section to promote it to `status: open`, then launches implementation via issue().
- The Builder (Code) implements from the Issue and stops at a local commit. Pushing, PR creation, and production commands are forbidden; publishing happens in `issue-finish` after the user's review.

- Verification steps: the Builder writes them in the commit message body under `## 検証手順`; `issue-finish` turns that body into the PR description, and the user executes the steps.

### Exceptions to Role Separation

To keep the separation from becoming rigid, the Consultant may edit directly through exactly three routes.

- **Real-time ops**: incident response that cannot be designed as an Issue in advance may be handled directly by the Consultant. Any implementation derived from it goes through an Issue.
- **One-off exception**: when the user explicitly declares in the open chat "make an exception and edit directly this time", the Consultant may edit directly, stating the target files and the reason in one line. Never normalize this (if it becomes frequent, prompt the user to move the repository back to the MVP phase).
- **Lightweight route**: when a diff satisfies all three conditions — touches no logic (config, README, comments, etc.), touches no guarantee ledger (`docs/guarantees.md`), and stays within a few dozen lines in a single file — the Consultant may edit directly without an Issue and without a one-off declaration.

---

## Project Layout

Each repository holds a persistent instruction file for the selected Agent and the shared management directories.

```
{app_root}/
├── CLAUDE.md        # Instructions for Claude Code (incl. static checks and verification templates)
├── .claude/
│   └── settings.json        # Permissions / accident prevention (harness-guide.md)
├── context/         # Shared context
│   ├── conventions.md
│   └── structure.md
└── issues/          # Local issue management
    └── {NN}_{slug}.md
```

The `pr-workflow` (Builder) and `new-issue` (Consultant) skills are not copied per repository; they live in the global `~/.claude/skills/` (managed by dotfiles). The master Issue template lives at `~/.claude/skills/repo-standardize/reference/issue-template.md` and is never distributed as copies (the `new-issue` skill reads it directly). Repository-specific checks and verification steps go in each repository's CLAUDE.md, which the skills reference.

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

### 保証
- 新たに宣言する保証: {behaviors that should hold after this change, as natural-language bullets}
- 維持する保証: {existing behaviors this change must not break, as natural-language bullets}

{free-form details that do not fit above}
```

The guarantee section is written in natural language describing behavior (test code or test names are supplementary). For changes with no accompanying tests, state `保証: なし（理由）` explicitly.

### Lifecycle

```
draft  → (design complete, user approves the guarantee section) →  open  → (issue-finish) →  close
```

- `draft`: under design. Excluded from issue() selection.
- `open`: ready to implement. Selectable by issue(). The Builder never changes `status:`. **`open` implies the user has read the guarantee section and approved it after trimming, adding, and correcting as needed.**
- `close`: done. Updated by issue-finish.

### Derived Issues

When verification finds a problem, close the original Issue and create a derived one such as `{id}a`.

Never reopen the original Issue or send follow-up prompts into the same Agent session. Always start from an Issue file to keep the record.

### Information Security

- Never write concrete connection details in human-readable text (Issues, PRs, commit messages, comments). Use the `<PLACEHOLDER>` entries defined in the local secrets dictionaries (`secrets-agents/`, never published) instead.
- Masked: real domains, public ports, Tunnel UUIDs, production absolute paths, VPN IPs / SSH usernames, app-specific values. Not masked: localhost, development ports, repository-relative paths.

---

## Shell Functions

### `issue`

Selects the target Issue and launches the Agent. Local files under `issues/` are the single source of truth; the GitHub Issue is a record-only mirror that `issue-finish` leaves behind as "create → close immediately" on completion.

1. Select an Issue with `status: open` via `fzf` (with preview).
2. Create worktree `{repo}.wt/{id}-{slug}` on branch `claude/{id}-{slug}`, commit the selected Issue file on that branch, then launch the `claude` command inside it. The Issue file stays untracked on the main side, so parallel Issues never leak into each other's branches. The main checkout stays clean and multiple Issues can run in parallel. No stash is needed (the worktree is cut from HEAD, so uncommitted changes are never carried in).

Code never touches GitHub (pushing, PR creation, and the record Issue are all handled by `issue-finish`).

### `issue-abort`

Aborts the task in progress and discards changes.

1. Pick a `claude/*` worktree via `fzf` and force-delete both the worktree and the branch (`git worktree remove --force` + `git branch -D`).

### `issue-finish`

Publishes the reviewed branch (push → PR creation → merge), cleans up branches, and closes the Issue in one pass. Only what the user has reviewed locally ever reaches the remote.

1. Pick a `claude/*` branch not yet merged into `main` via `fzf` (previewing the commit log and diff).
2. Push the selected branch, create the PR with the commit message body as its description (`gh pr create`), then run `gh pr merge --squash`. The Issue's open commit is merged as part of this PR. On repos with required status checks the immediate merge is rejected, so the flow switches to auto-merge and waits for CI and the merge to complete.
3. Run `git pull --prune` (the main checkout always stays on main; after a squash merge, untracked Issue files are moved aside before the pull).
4. Remove the merged branch's worktree and delete its local and remote branches.
5. Create the record GitHub Issue and close it immediately (if `github_issue:` already has a number, close only). A failed creation never blocks the flow.
6. Set the Issue file's `status:` to `close` (the file itself never moves). When a PR was merged, write that PR's title, URL, merge commit SHA, and body to a **separate file** at `issues/done/{same filename}` — one Issue file plus one PR record file.
7. Commit the changed files (the Issue file and, if present, the PR record file) to `main` and push.
