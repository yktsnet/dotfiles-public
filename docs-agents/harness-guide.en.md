[🇯🇵 日本語](harness-guide.md) | [🇬🇧 English](harness-guide.en.md)

# Harness Guide

Design guide for per-repo `.claude/` structure, instruction files, and verification methods.
For new repos, apply `issue-driven-workflow.md` (process layer) and this guide (harness layer) first. CI/CD is delegated to `cicd-guide.md`.

Two design principles: **Prohibitions go in settings, keeping instruction files short.** **Give the Agent verification methods so it can self-check before PR.**

---

## 1. Repo Categories and Verification Methods

Categorize repos and determine the verification methods the Agent runs before PR.
Verification doesn't have to mean tests. Having at least one path to confirm "my changes aren't broken" is sufficient.

| Category | Verification Method |
|---|---|
| Config (IaC, dotfiles) | Syntax check (`flake check`, `zsh -n`, `py_compile`, etc.) |
| Logic (batch, daemon, analysis) | Syntax check + import/caller verification. Dry run if possible. Run tests if available |
| Web (API, site) | Type check + test |
| Tool (automation, Agent-driven) | Syntax check. Strongly restrict side-effect commands |

Public/private status is an orthogonal axis. **Public** repos have CI (Layer 3). **Private** repos have optional CI; local verification may substitute.

Verification methods should be **runnable without additional installation in the environment**. Imperative global installations that break reproducibility (`pip install`, `npm install -g`, etc.) are prohibited. Non-standard tools are loaded via disposable environments (this fleet uses Nix, so `nix-shell -p {pkg} --run "..."`). The Issue `verification` field should also specify methods available in the env by default (`php -l`, etc.) or disposable environment / visual inspection.

The PR's `## Verification Steps` section documents checks the Agent cannot complete (deployment, browser, production behavior), delegated to the user. Safe-to-run checks stay on the Agent side; dangerous ones (production, deployment, merge) stay on the user side.

---

## 2. Layer Structure

| Layer | Content | Applies To |
|---|---|---|
| Layer 1: Accident Prevention | `settings.json` deny + attribution + `hooks/` PreToolUse | All repos |
| Layer 2: Operations Foundation | Instruction files (CLAUDE.md / context/ / Skills) + verification methods | All repos running an Agent |
| Layer 3: Public Verification | CI (`cicd-guide.md`) | Public or auto-deployed repos |

---

## 3. Layer 1 — settings.json and Hooks

Check in `.claude/settings.json`. `.local.json` is for personal overrides (gitignored).

There are two mechanisms for blocking. `deny` is declarative and easy to read, but it only ever sees a **string prefix**. Anything that requires judging the structure of a command or the meaning of an edit target belongs in a PreToolUse hook (Section 3.5).

### deny (common)

```json
"deny": [
  "Bash(git push origin main*)",
  "Bash(git push --force *)",
  "Bash(git push -f *)"
]
```

### deny (per category — add to common)

| Category | Additional deny |
|---|---|
| Config | Apply commands (`*-rebuild *`, etc.), secret read/write, lock file editing |
| Logic | Production startup, commands with external side effects (real orders, real sends, real billing) |
| Web | Deploy CLI (`wrangler`, etc.) |
| Tool | Retain side-effect commands in deny as appropriate for the role |

For self-hosted environments, also add `ssh` and `rsync` to deny (blocking the deployment path).

### allow (common)

```json
"allow": ["Bash(git *)", "Bash(gh pr *)"]
```

Push commands are blocked by deny taking precedence, so `Bash(git *)` allow is compatible.

To let the agent read directories outside the repository (e.g. a secrets dictionary), add the paths to `additionalDirectories` under `permissions`.

### allow (per category)

| Category | Additional allow |
|---|---|
| Config | Parser/syntax check tools |
| Logic | Language runtime (block production commands individually via deny) |
| Web | Package execution (`npm run *` / test runner / build CLI) |

### attribution

```json
"attribution": { "commit": "", "pr": "" }
```

Remove Co-Authored-By. The stance is that the Agent is a tool, not a co-author. Mixing non-human names in commit history also degrades blame readability.

### 3.5 Hooks (`.claude/hooks/`)

`deny` matches a string prefix; it does not interpret the command. Putting `Bash(pip install *)` in deny matches neither a path-qualified `/tmp/venv/bin/pip install x` nor one chained after `make setup &&`. **When what you want to forbid is an action rather than a string**, decide it in a PreToolUse hook.

The implementations live in `.claude/hooks/`. In the operating fleet, `home-manager/modules/claude.nix` deploys `.claude/` to `~/.claude/`, so the same files take effect across every repo.

| Hook | Trigger | What it blocks |
|---|---|---|
| `block-non-nix-install.sh` | PreToolUse `Bash` | Package installs outside Nix (pip / brew / npm -g / cargo / gem). Catches path-qualified executions and installs nested in compound commands |
| `block-live-claude-config-edit.sh` | PreToolUse `Edit\|Write\|Bash` | Direct edits to `~/.claude/`, which is generated output. Rewrites the path to the source and returns it. Also catches shell-side writes such as `sed -i` (reads are let through) |
| `block-new-skill-md.sh` | PreToolUse `Write\|Bash` | New `SKILL.md` files that break convention. Checks frontmatter (`name` / `description` / explicit-invocation flag) and placement: writing into `~/.claude/skills/` is denied, repo-local placement prompts for confirmation |
| `block-project-scoped-memory.sh` | PreToolUse `Edit\|Write` | Memory written to the wrong store (Section 4.5) |
| `sync-memory-index.sh` | SessionStart | (Generates rather than blocks) regenerates `MEMORY.md` |
| `opus-scope-and-concision.sh` | SessionStart | (Injects rather than blocks) adds concision and scope discipline for Opus models only |
| `backup-secret-json.sh` | PreToolUse `Edit\|Write` | Backs up `secrets/**/*.json.age` before it gets overwritten (a safety net, not a block; keeps only the last 5 generations) |

#### Match on command position

`block-non-nix-install.sh` performs its match like this.

```bash
stripped=$(printf '%s' "$cmd" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')
pre='(^|[;&|`]|\$\()[[:space:]]*(sudo[[:space:]]+)?(env[[:space:]]+)?([[:alnum:]@/_.~+-]*/)?'
```

Quoted spans are dropped first, so merely naming an installer inside a commit message doesn't trip it. `pre` then restricts the match to command position (start of line, or right after `;` `|` `&` `` ` `` `$(`) and absorbs path-qualified executions and a leading `sudo` / `env`.

The trade-off is that this reads shell syntax, not intent: prose that quotes an example command in command position still matches. Documentation about the hook is the common false positive.

#### Write the denial message as a router

A denied Agent will try something else, and the denial text is where you get to say what. So a hook's `permissionDecisionReason` should carry **both the reason and the alternative**. `block-non-nix-install.sh` returns the distinction between `nix run` / `nix shell` / `home.nix` / `shell.nix` plus the `nix-tool-install` skill; `block-live-claude-config-edit.sh` mechanically rewrites the edit target and hands it back.

```bash
dotfiles_path="${file_path/#$home\/.claude\//$home/dotfiles/.claude/}"
```

If all you need is a wall, `deny` suffices. The payoff of a hook is that it can push the Agent onto the right path at the moment it refuses.

---

## 4. Layer 2 — Instruction Files

Separate Agent instructions by role.

### CLAUDE.md (entry point, under 200 lines)

Load context via `@import`.

```markdown
# CLAUDE.md
@context/conventions.md
@context/structure.md

## Commands
{setup / dev / build / verification commands}

## Architecture Highlights
{single source of truth, layer structure, etc. — minimal}

## Verification Methods
{paths the Agent checks before PR}
```

**Include**: Commands, structural highlights, verification methods.
**Exclude**: Prohibitions/enforcement (→ settings.json deny), attribution (→ settings.json), lengthy specifications, infrastructure settings/secrets that shouldn't be public (→ write only the instruction to reference `~/dotfiles/secrets-agents/` files).

### context/

| File | Role |
|---|---|
| `conventions.md` | Naming rules, code conventions, style (how to write) |
| `structure.md` | Directory structure, routing, data flow (where things are) |

Add files as the repo's nature requires. If everything fits in 2 files, no need to split further.

### Skills

Workflow skills are not copied per repository; they live in the global `~/.claude/skills/`. The source of truth is this repository's `.claude/skills/`, which `home-manager/modules/claude.nix` copies there.

| Skill | Role |
|---|---|
| `pr-workflow` | For the Builder. Implementation → run verification → local commit (the branch and worktree are created by `issue()`; push and PR creation happen in `issue-finish`) |
| `new-issue` | For the Consultant. Organize requirements → mask secrets → write the Issue into `issues/` |
| `consolidate-rules` | Audits rule files for contradiction and staleness (Section 4.6) |

Both define only the generic flow; repository-specific checks and verification steps (Section 1 above) go in each repository's CLAUDE.md, which the skills reference.
`pr-workflow` is launched via the `claude` command from the `issue()` shell function in `issue-driven-workflow.md`.

### Knowledge Placement Criteria

Where to place knowledge is decided by the trigger that reads it.

| Trigger | Placement |
|---|---|
| Short rule that applies every time | One line in CLAUDE.md |
| Procedure/norm statable as "when doing X" | A skill (the description becomes the declaration of its trigger condition) |
| Shared dictionary/guide referenced by a rule | An independent directory, referenced by absolute path from CLAUDE.md / a skill (e.g., `secrets-agents/`, `docs-agents/`) |
| Human drafts / unorganized thoughts | Outside the harness. Not auto-read by the AI |

The trigger for migrating a document is the moment you notice "I've handed this document over by hand again." Don't migrate everything at once.

Skill skeleton:

```markdown
---
name: sops-secrets
description: Operational procedure for encrypting, decrypting, and re-encrypting secrets with sops / age. Use when encrypting a secret, when changing `.sops.yaml`, or when registering a new device's key.
---
```

The description enumerates trigger conditions as "use when ~," turning tacit knowledge into a declaration.

Skill updates are not auto-extracted. If a drift is noticed during work, stop at a suggestion — don't mass-produce norms that go unreviewed.

### 4.5 Persistent Memory

Knowledge that must survive across sessions goes in `~/memory/`, one fact per file, split into subdirectories by type.

`~/memory` is not the entity itself but a symlink into dotfiles (`memory/`). Keeping the entity inside the repo lets multi-device sync and conflict resolution ride on git. The link is created by the activation script in `home-manager/modules/memory.nix`; if `~/memory` already exists as a real directory, it leaves it untouched and stops with a message asking you to migrate the contents first. Hooks can keep referring to `$HOME/memory` unchanged, since it's a symlink.

| Type | Content |
|---|---|
| `user` | Who the user is (role, expertise, preferences) |
| `feedback` | Guidance on how to work. Record the reason (**Why**) and how to apply it (**How to apply**) |
| `project` | Ongoing constraints not derivable from the code or git history. Convert relative dates to absolute ones |
| `reference` | Pointers to external resources (URLs, dashboards, tickets) |

The index `~/memory/MEMORY.md` is **generated, never hand-written**. The SessionStart hook `sync-memory-index.sh` rebuilds it from each file's frontmatter (`name` / `description`), and rewrites only when the content differs, so a session that changes nothing touches nothing.

The harness system prompt may instruct the agent to store memory in `~/.claude/projects/<project>/memory/`. The source of truth here is `~/memory/`, so anything written there accumulates as duplicates that never appear in the index. `block-project-scoped-memory.sh` denies writes to the project scope and returns the correct destination, assembled from the filename.

Auto-generating the index does nothing if the writes land elsewhere. **Generation (`sync-memory-index.sh`) and blocking (`block-project-scoped-memory.sh`) are separate countermeasures, and both are required.**

### 4.6 Auditing the Rules

CLAUDE.md, skills, and memory all share one structure: rules a human wrote, read by an AI. None of them detects contradictions between rules. Since rule files only accumulate, contradiction and staleness eventually destabilize Agent behavior. The `consolidate-rules` skill handles this audit.

It looks for three kinds of drift.

1. Internal contradictions within `docs-agents` (e.g., `test-policy.md` and `issue-driven-workflow.md` disagreeing on a criterion)
2. Divergence between CLAUDE.md and `docs-agents` (a rule that exists only in CLAUDE.md, left behind when a guide is updated)
3. Divergence between a skill's `description` and its body (the rule changed, the trigger condition didn't)

Two points of design matter.

**Read only the diff, via an index.** `.claude/RULES.md` holds no rule content — only a pointer per file, a one-line summary, cross-references, and the commit and date of the last audit. From the second run onward, that index is the starting point, and only files changed since the record get read in depth. Without an index, every run reads every target, and the cost of scheduled execution grows in proportion to the number of targets.

**Don't maintain an exclusion list.** What gets audited is the rules you wrote, not vendored technical references or bundled skills. Keeping that as a fixed list means maintenance every time a skill is added, so the split is made mechanically: whether the frontmatter `description` is written in Japanese.

Findings are applied one at a time, each with explicit approval from the user. Never batch them into a single sign-off.

---

## 5. New Repo Checklist

```
[ ] Determine category (Config / Logic / Web / Tool, Public / Private)
[ ] Layer 1: .claude/settings.json (common deny + category deny + attribution)
[ ] Layer 2: CLAUDE.md (@import + commands + structure + verification methods and templates, under 200 lines)
[ ] Layer 2: context/ (conventions.md + structure.md)
[ ] Layer 3: If Public / auto-deployed, add CI (cicd-guide.md)
[ ] Prohibitions go in settings.json deny, not CLAUDE.md
```
