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
| Layer 1: Accident Prevention | `settings.json` deny + attribution | All repos |
| Layer 2: Operations Foundation | Instruction files (CLAUDE.md / context/ / Skills) + verification methods | All repos running an Agent |
| Layer 3: Public Verification | CI (`cicd-guide.md`) | Public or auto-deployed repos |

---

## 3. Layer 1 — settings.json

Check in `.claude/settings.json`. `.local.json` is for personal overrides (gitignored).

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

> [!NOTE]
> To allow reading external private information, set `permissions` in `.claude/settings.json` to `read_file: ["~/dotfiles/secrets-agents/"]`.

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

Workflow skills are not copied per repository; they live in the global `~/.claude/skills/` (home-manager copies them from dotfiles' `.claude/skills/`).

| Skill | Role |
|---|---|
| `pr-workflow` | For the Builder. Implementation → run verification → PR creation (the branch and worktree are created by `issue()`) |
| `new-issue` | For the Consultant. Organize requirements → mask secrets → write the Issue into `issues/` |

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
