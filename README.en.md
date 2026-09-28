[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

In development with AI agents, the bottleneck shifts from generation to verification and intent transfer.
This repository publishes a personal development environment built on that premise, as code: the Nix configuration, the machinery for role separation, and the skill set.
The development method itself is packaged for team repositories in [sdlc-kit](https://github.com/yktsnet/sdlc-kit). This repository is the environment where that method actually runs.

---

## Development Lifecycle (Two Driving Documents)

Development is split into two phases, and the driving document changes with the phase: PLAN.md / JUDGE.md (SDD) during bootstrap, and the guarantee ledger `docs/guarantees.md` with its tests (GDD) after release. Each repository declares its phase in its CLAUDE.md.

The rationale is in sdlc-kit's [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md). For the operating rules in this repository, see [test-policy.md](docs-agents/test-policy.en.md).

---

## Role Separation

The execution machinery for the two workflows above. Responsibilities are strictly defined across humans, conversational AI, and autonomous AI agents, so that no agent edit reaches the main branch or production without review.

* **WebChat (Design / Conversational AI)**:
  In dialogue with the user, formulates specifications and design files during the MVP phase, and performs investigation and Issue design during the Issue-driven phase. Never implements.
* **AI Agent (Implementation / Autonomous AI)**:
  Autonomously executes code editing, test implementation, static error checking, and local commits using Issue files as input; it never touches the remote. The procedure is fixed in [pr-workflow](.claude/skills/pr-workflow/SKILL.md). Destructive commands such as `rebuild` and access to secrets are blocked by the deny list in `.claude/settings.json`, and whatever a string prefix cannot decide (path-qualified package installs, edits to generated output) is handled by the PreToolUse hooks in [`.claude/hooks/`](.claude/hooks/).
* **User (Approval, Verification / Human)**:
  Approves the guarantee sections of Issues, reviews and verifies the agent's commits locally, then publishes them (push, PR creation, merge) via `issue-finish`. Only reviewed changes ever reach the remote.

Hand-offs between roles are performed by Zsh macros:

* **`issue`**: Selects the target Issue, creates an isolated worktree, and launches the agent inside it. The main checkout stays clean, and multiple Issues can run in parallel.
* **`issue-abort`**: Discards an in-progress worktree together with its work branch.
* **`issue-finish`**: Runs push → PR creation → merge → cleanup for a reviewed branch in one pass.

Exceptions keep the separation from becoming rigid: real-time ops such as incident response, one-off exceptions the user declares explicitly, and a lightweight route that lets small, logic-free changes through without an Issue.

This role separation describes the flow of a single Issue; in practice, multiple worktrees and consultant sessions run in parallel. A session running on the same model and the same rules cannot detect on its own that it has drifted off course. `M-m` ([session-nudge](.claude/skills/session-nudge/SKILL.md)) provides that external reader: it sends via cross-session messaging, but only after the user approves the draft message. It never intervenes in another session automatically.

See [issue-driven-workflow.md](docs-agents/issue-driven-workflow.en.md) for details.

---

## Foundation (Prerequisites for Autonomous Execution)

Autonomous agent execution only works once three things are structurally in place: environment, secrets, and knowledge.

* **Environment consistency via Nix**: Environment differences cause "command not found" and runtime errors for agents. Nix Flakes and Home Manager unify the macOS / Linux toolchain as code, continuously verified by CI (`nix flake check`). Installs that bypass this route (`brew`, `npm -g`, and the like) are blocked by `.claude/hooks/block-non-nix-install.sh`.
* **Secrets isolation**: Production IPs, ports, and real hostnames never appear in code or Issue files on the public repository. Actual values are isolated in the local `secrets-agents/` directory, and prose uses `<PLACEHOLDER>` instead. The dictionary itself isn't kept as local plaintext — it's encrypted and distributed via git, and each device decrypts it with its own key. Without that, a device other than the one holding the plaintext copy would have no way to know what to mask.
* **Making tacit knowledge explicit as skills**: When "which file to hand the AI and when" depends on human tacit knowledge, the AI cannot reproduce operations alone. Any procedure statable as "when doing X" becomes a skill with its trigger condition declared in the description. The workflows in the previous section (`new-issue`, `guarantee-audit`, etc.) are committed in this form. See [harness-guide.md](docs-agents/harness-guide.md#knowledge-placement-criteria) for details.
* **Auditing the rules**: CLAUDE.md, skills, and memory all share one structure — rules a human wrote, read by an AI — and none of them detects contradictions between rules. Left alone, an ever-growing rule set destabilizes behavior, so [`consolidate-rules`](.claude/skills/consolidate-rules/SKILL.md) audits only the diff on a schedule, starting from the index `.claude/RULES.md`. Persistent memory carries no index at all: one fact per file, directly under `~/memory/`, kept at a granularity where `ls` is the index.

---

## Devices

A single Flake binds the macOS and Linux development machines. Device names are replaced with role-based generics for publication.

| Configuration | OS | Role |
|---|---|---|
| `gui/linux-desktop` | NixOS (disko / SSD) | Primary dev machine. Where consultant chat and `issue()` are launched |
| `gui/macbook` | macOS (nix-darwin) | Shares the home-manager layer with the Linux machine |

OS differences are confined to `pkgs.stdenv.isDarwin` on the Nix side and to the shims in `zsh/functions/os.sh` (`_is_darwin`, `_sed_i`, `_open`, `_linux_only`) on the shell side. Home Manager modules and function files are read as-is by both operating systems.

What is published is limited to the layers involved in developing with agents (Claude Code, memory, secrets, review, tmux session management). Editor and desktop settings and server configurations are not included.

---

## Agent Development Guides

A set of guides for starting AI Agent collaborative development in a new repository. The 9 files in `docs-agents/` split into a **judgment layer**, where the answer differs from repo to repo, and a **standard layer**, where the same answer applies once decided, with a single **principles layer** above both. In an operation that launches many repos in parallel, the cost paid on the judgment layer is what governs throughput. The judgment layer is read by the `repo-readme` / `module-dev` Skills; the standard layer by the `repo-standardize` / `guarantee-audit` Skills.

### Principles Layer

| Guide | Role |
|---|---|
| [principles.en.md](docs-agents/principles.en.md) | Order of adoption, and the essence, mechanism, and completion condition of each stage. The premises the other guides are written on |

### Judgment Layer

| Guide | Role |
|---|---|
| [module-guide.md](docs-agents/module-guide.md) | Design guide for OSS module-style repos. Type decisions, structure, demo methods |
| [readme-guide.md](docs-agents/readme-guide.md) | README writing guide. Structure, language rules, JUDGE.md integration |
| [diagram-guide.md](docs-agents/diagram-guide.md) | Whether to draw a diagram, width constraints, shapes and line types, abstraction level |

### Standard Layer

| Guide | Role |
|---|---|
| [repo-guide.md](docs-agents/repo-guide.md) | Repository structure, secrets management, pre-publish checklist |
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | Process layer. Issue-driven development flow, role separation, shell functions |
| [harness-guide.md](docs-agents/harness-guide.md) | Harness layer. `.claude/` structure, settings.json, instruction files, verification methods |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD layer. GitHub Actions, auto-deployment to Cloudflare (Pages / Workers), Dependabot |
| [test-policy.md](docs-agents/test-policy.md) | Test layer. Guarantee approval, guarantee ledger, risk-based test depth |
