[🇯🇵 日本語](issue-driven-workflow.md) | [🇬🇧 English](issue-driven-workflow.en.md)

# Issue-Driven Development Workflow

An issue-driven development flow leveraging AI Agents (Claude Code / Jules).
Separates design, implementation, and verification to prevent Agent runaway while developing at speed.

---

## Role Separation

| Role | Tasks |
|---|---|
| **WebChat** | Issue design, spec discussions, document creation |
| **AI Agent** | Code editing, static checks, git operations, PR creation |
| **user** | Deployment, service restart, behavior verification, merge |

- WebChat responsibility: Up to writing Issue files. Does not write verification steps.
- AI Agent responsibility: Implementation based on Issues, PR creation. Running commands in production is prohibited.
- Verification steps: Written by the AI Agent in the PR's `## Verification Steps`. Executed by the user.

---

## Supported Agents and Characteristics

The Agent (Code / Jules) is selected on the ZSH side. No guards are configured.
Branch management differs based on each Agent's execution environment.

| Agent | Execution Environment | Branch Management | Persistent Instruction File |
|---|---|---|---|
| **Claude Code (Code)** | Local environment | Creates/operates local branches | `CLAUDE.md` |
| **Jules** | Cloud sandbox | No local branches (remote-only) | `AGENTS.md` |

---

## Project Structure

When `issue-init` runs, it generates the persistent instruction file for the selected Agent and common management directories in the current repository.

```
{app_root}/
├── CLAUDE.md        # Persistent instructions for Claude Code
├── AGENTS.md        # Persistent instructions for Jules
├── .claude/
│   ├── settings.json        # Permissions & accident prevention (harness-guide.md)
│   └── skills/
│       └── pr-workflow/SKILL.md
├── context/         # Shared context
│   ├── conventions.md
│   └── structure.md
└── issues/          # Local issue management
    ├── 00_template.md
    └── {NN}_{slug}.md
```

---

## Issue Format

```markdown
## {Title}
id: {00}
branch-slug: {slug}
github_issue:
status: draft | open | close
type: cleanup | fix | feat
target: {list all files to modify/create; mark new files with (new)}
description: {purpose and overview only}
verification: {static checks the AI Agent runs before submitting}

---

{expand specs that don't fit in description}
```

### Lifecycle

```
draft  →(design complete)→  open  →(issue-finish)→  close
```

- `draft`: Under design. Excluded from `issue()` selection.
- `open`: Ready for implementation. Selectable via `issue()`.
- `close`: Completed.

### Derived Issues

If verification reveals problems, close the original Issue and create a derived issue as `{id}a`, etc.

Reopening the original Issue or appending prompts to the same Agent session is prohibited. Always use Issue files as the starting point for record-keeping.

### Information Security

- In public repositories, do not write specific connection information such as production IPs, specific ports, or real hostnames (e.g., `production-server`) directly in Issue files — instead, reference files in `~/dotfiles/secrets-agents/`.

---

## Shell Functions

Implementations are consolidated in [`zsh/functions/`](../zsh/functions/). macOS loads them from `zsh/darwin.nix`, x86/NixOS from `zsh/nixos.nix` (see [`zsh/README.md`](../zsh/README.md) for structure).

### `issue-init` or `jules-init`

Initializes the development environment for the current directory (single repository).

1. Select Agent (Code / Jules) on the ZSH side.
2. Generate shared context (`context/`) and local Issue management (`issues/`).
3. Generate `CLAUDE.md` or `AGENTS.md` depending on the selected Agent.

### `issue` or `jules`

Select a target Issue, sync local and remote, then launch the Agent. Issues are managed both as local files (`issues/`) and GitHub Issues.

1. Select from `status: open` Issues via `fzf` (with preview).
2. If there are uncommitted changes, prompt for `git stash`. Issue file updates are committed to `main`.
3. Sync with remote (`git pull --rebase`, push if needed).
4. If `github_issue:` is empty, auto-create a GitHub Issue and write back the assigned number to the Issue file, then commit & push (skip if already linked).
5. Agent-specific branching:
   - **Code**: Create and checkout local branch `{agent}/{id}-{slug}`. Submit task via `claude` command.
   - **Jules**: No local branch. Submit Issue content directly to a cloud session via `jules new`.

### `issue-abort` or `jules-abort`

Abort an in-progress task and discard changes.

1. Agent-specific branching:
   - **Code**: Identify the current `{agent}/*` branch. `git stash`, switch to `main`, force-delete the local branch (`git branch -D`).
   - **Jules**: Skip local branch operations. Handle cloud-side session management manually (`jules remote`, etc.).

### `issue-finish` or `jules-finish`

Merge PR, clean up branches, and close Issue in one operation.

1. List open PRs, input PR number.
2. Execute `gh pr merge {number} --merge`.
3. Execute `git checkout main && git pull --prune`.
4. Agent-specific branching:
   - **Code**: Bulk-delete merged local and remote branches (`claude/*`).
   - **Jules**: Skip branch deletion (no local branches exist).
5. Close the GitHub Issue linked to the target Issue via `gh issue close`.
6. Update the local Issue file to `status: close`, commit & push to `main`.
