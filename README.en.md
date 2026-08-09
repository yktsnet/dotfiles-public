[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Two-Phase Development Lifecycle for AI-Agent Collaboration

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

In development with AI agents, the bottleneck shifts from generation to verification and intent transfer.
This repository splits development into two phases, each driven by a different document: specifications (PLAN.md / JUDGE.md) during bootstrap, the guarantee ledger (guarantees.md) and its tests during maintenance.
The execution environment that supports this lifecycle (Nix, role separation, and the skill set) is published as code along with it.

---

## Development Lifecycle (Two Driving Documents)

Development documents have lifespans. Rather than trying to keep a single specification alive forever, the driving document changes with the phase. Each repository declares its phase in its CLAUDE.md.

### MVP Phase: Spec-Driven Development (SDD)

While direction and structure are still unsettled, PLAN.md (spec, plan, and work log) and JUDGE.md (decisions made during implementation) drive development. The agent keeps both files updated as implementation proceeds, and at release they are absorbed into the README and retired. The specification is scaffolding for this phase only; it is not expected to persist.

### Issue-Driven Phase: Guarantee-Driven Development (GDD)

After release, changes too small to deserve a spec accumulate, and the original specification inevitably drifts from the implementation. So the driving document hands over to the guarantee ledger (`docs/guarantees.md`). The ledger records only what is promised and what is not, and every promise is continuously verified by a corresponding test. Unlike a README, it cannot rot silently, because breaking a promise makes a test fail.

The human approves the declaration of guarantees (what should hold) in each Issue's guarantee section, and the agent writes the test code. The human's job shifts from writing tests to approving promises. See [test-policy.md](docs-agents/test-policy.en.md) for details.

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

This role separation describes the flow of a single Issue; in practice, multiple worktrees and consultant sessions run in parallel. A session running on the same model and the same rules cannot detect on its own that it has drifted off course. `M-m` ([session-nudge](.claude/skills/session-nudge/SKILL.md), [keybindings](docs/tui_environment.md)) provides that external reader: it sends via cross-session messaging, but only after the user approves the draft message. It never intervenes in another session automatically.

See [issue-driven-workflow.md](docs-agents/issue-driven-workflow.en.md) for details.

This repository also serves as a Claude Code plugin marketplace. `/plugin marketplace add yktsnet/dotfiles-public` → `/plugin install public-skills` installs the seven general-purpose skills (readme-i18n, repo-about, jp-writing, jp-writing-code, vhs-demo, app-demo-gif, comment-cleanup).

---

## Foundation (Prerequisites for Autonomous Execution)

Autonomous agent execution only works once three things are structurally in place: environment, secrets, and knowledge.

* **Environment consistency via Nix**: Environment differences cause "command not found" and runtime errors for agents. Nix Flakes and Home Manager unify the macOS / Linux toolchain as code, continuously verified by CI (`nix flake check`). Installs that bypass this route (`brew`, `npm -g`, and the like) are blocked by `.claude/hooks/block-non-nix-install.sh`.
* **Secrets isolation**: Production IPs, ports, and real hostnames never appear in code or Issue files on the public repository. Actual values are isolated in the local `secrets-agents/` directory, and prose uses `<PLACEHOLDER>` instead.
* **Making tacit knowledge explicit as skills**: When "which file to hand the AI and when" depends on human tacit knowledge, the AI cannot reproduce operations alone. Any procedure statable as "when doing X" becomes a skill with its trigger condition declared in the description. The workflows in the previous section (`new-issue`, `guarantee-audit`, etc.) are committed in this form. See [harness-guide.md](docs-agents/harness-guide.md#knowledge-placement-criteria) for details.
* **Auditing the rules**: CLAUDE.md, skills, and memory all share one structure — rules a human wrote, read by an AI — and none of them detects contradictions between rules. Left alone, an ever-growing rule set destabilizes behavior, so [`consolidate-rules`](.claude/skills/consolidate-rules/SKILL.md) audits only the diff on a schedule, starting from the index `.claude/RULES.md`. The persistent-memory index is treated the same way: generated output, rebuilt from frontmatter by a SessionStart hook.

---

## Device Fleet

A single Flake binds six configurations that differ in OS and in how they boot. Device names are replaced with role-based generics for publication.

| Configuration | OS / Boot | Role |
|---|---|---|
| `gui/macbook` | macOS (nix-darwin) | Primary dev machine. Where consultant chat and `issue()` are launched |
| `gui/linux-desktop` | NixOS (disko / SSD) | Desktop. Build host |
| `gui/linux-laptop` | NixOS (disko / SSD) | Portable GUI machine. Serves netboot images |
| `headless/ssd/linux-server-a` | NixOS headless (VPS) | Public services and ops |
| `headless/ssd/linux-server-b` | NixOS headless | Resident jobs |
| `headless/diskless/linux-netboot` | NixOS netboot (tmpfs root) | Stateless machine. No storage; receives over PXE |

Common modules are split between GUI and headless, and only per-machine differences (`hardware.nix`, `disko.nix`, `monitor.nix`, and so on) live in each directory. Diskless machines drop NixOS generation retention and serve only the latest one (`.claude/skills/netboot-stateless/`).

Fleet-wide status checks run through `apps/zsh/fleet_monitor.py`, which keeps no agent resident on the remotes: it pipes the local script into SSH's stdin instead.

---

## TUI Toolchain & Development Environment

A Nix-unified TUI environment for both agents and humans to work in the same environment.

* **Neovim**: An integrated development environment based on `lazy.nvim`. LSP completion, static type checking, auto-formatting (conform.nvim), and automatic session restoration. File operations go through oil.nvim, which edits directories as ordinary text buffers.
* **Tmux**: Prefix-key-free pane operations, OSC 52 clipboard sync, True Color support. Operable with the same shortcuts as Neovim's split windows.

For detailed keybindings and configuration, see [TUI Environment (docs/tui_environment.md)](docs/tui_environment.md).

---

## Agent Development Guides

A set of guides for starting AI Agent collaborative development in a new repository. Hand all 7 files to the AI together to build a standard development environment.

| Guide | Role |
|---|---|
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | Process layer. Issue-driven development flow, role separation, shell functions |
| [harness-guide.md](docs-agents/harness-guide.md) | Harness layer. `.claude/` structure, settings.json, instruction files, verification methods |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD layer. GitHub Actions, auto-deployment, Cloudflare Tunnel |
| [readme-guide.md](docs-agents/readme-guide.md) | README writing guide. Structure, language rules, JUDGE.md integration |
| [repo-guide.md](docs-agents/repo-guide.md) | Repository structure, secrets management, pre-publish checklist |
| [module-guide.md](docs-agents/module-guide.md) | Design guide for OSS module-style repos. Type decisions, structure, demo methods |
| [test-policy.md](docs-agents/test-policy.en.md) | Test layer. Guarantee approval, guarantee ledger, risk-based test depth |
