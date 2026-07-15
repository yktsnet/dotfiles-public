[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Two-Phase Development Lifecycle for AI-Agent Collaboration

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

In development with AI agents, the bottleneck shifts from generation to verification and intent transfer.
This repository splits development into two phases, each driven by a different document: during bootstrap, specifications (PLAN.md / JUDGE.md) make agents enforce human intent; during maintenance, the guarantee ledger (guarantees.md) and its tests do.
The execution environment that supports this lifecycle — Nix, role separation, and the skill set — is published as code along with it.

---

## Development Lifecycle (Two Driving Documents)

Development documents have lifespans. Rather than trying to keep a single specification alive forever, the driving document changes with the phase. Each repository declares its phase in its CLAUDE.md.

| Phase | Driving document | Method | Fate of the document |
|---|---|---|---|
| MVP phase (bootstrap) | PLAN.md / JUDGE.md | Spec-Driven Development (SDD) | Absorbed into the README at release, then discarded |
| Issue-driven phase (maintenance) | Issue guarantee sections + `docs/guarantees.md` | Guarantee-Driven Development (GDD) | A durable contract continuously verified by tests |

### MVP Phase: Spec-Driven Development

While direction and structure are still unsettled, PLAN.md (spec, plan, and work log) and JUDGE.md (decisions made during implementation) drive development. The agent keeps both files updated as implementation proceeds, and at release they are absorbed into the README and retired. The specification is scaffolding for this phase only; it is not expected to persist.

### Issue-Driven Phase: Guarantee-Driven Development

After release, changes too small to deserve a spec accumulate, and the original specification inevitably drifts from the implementation. So the driving document hands over to the guarantee ledger (`docs/guarantees.md`). The ledger records only what is promised and what is not, and every promise is continuously verified by a corresponding test. Unlike a README, it cannot rot silently, because breaking a promise makes a test fail. When behavior feels off, the ledger is the first thing to open.

When agents write the code, the human's job shifts from writing tests to approving promises. The human approves the declaration of guarantees (what should hold) in each Issue's guarantee section, and the agent writes the test code. Tests are not the definition of truth; they are executable projections of the approved guarantees. If TDD is the discipline of writing tests first, GDD is the discipline of approving promises first. Drift between the ledger and the tests is detected by periodic audits with the `guarantee-audit` skill. See [test-policy.md](docs-agents/test-policy.en.md) for details.

---

## Role Separation

The execution machinery for the two workflows above. Responsibilities are strictly defined across humans, conversational AI, and autonomous AI agents, so that no agent edit reaches the main branch or production without review.

* **WebChat (Design / Conversational AI)**:
  In dialogue with the user, formulates specifications and design files during the MVP phase, and performs investigation and Issue design during the Issue-driven phase. Never implements.
* **AI Agent (Implementation / Autonomous AI)**:
  Autonomously executes code editing, test implementation, static error checking, and local commits using Issue files as input; it never touches the remote. Destructive commands such as `rebuild` and access to secrets are structurally blocked by the deny list in `.claude/settings.json`.
* **User (Approval, Verification / Human)**:
  Approves the guarantee sections of Issues, reviews and verifies the agent's commits locally, then publishes them (push, PR creation, merge) via `issue-finish`. Only reviewed changes ever reach the remote.

Hand-offs between roles are performed by Zsh macros:

* **`issue`**: Selects a `status: open` Issue via `fzf`, auto-creates worktree `{repo}.wt/{id}-{slug}` on branch `claude/{id}-{slug}`, and launches the Claude CLI inside it. The main checkout stays clean, and multiple Issues can run in parallel.
* **`issue-abort`**: Picks an in-progress `claude/*` worktree and discards it together with its work branch.
* **`issue-finish`**: Picks a reviewed branch and runs push → PR creation → merge → worktree/branch cleanup → rewriting the Issue file to `status: close`, all in one pass.
* **`skill`**: Lists manual-execution skills (those with `manual: true` in the frontmatter) via `fzf` with preview and launches the selection with `claude /{skill-name}`.

This repository also serves as a Claude Code plugin marketplace. `/plugin marketplace add yktsnet/dotfiles-public` → `/plugin install public-skills` installs the four general-purpose skills (readme-i18n, repo-about, jp-writing, jp-writing-code).

---

## Foundation (Prerequisites for Autonomous Execution)

Autonomous agent execution only works once three things are structurally in place: environment, secrets, and knowledge.

* **Environment consistency via Nix**: Environment differences cause "command not found" and runtime errors for agents. Nix Flakes and Home Manager unify the macOS / Linux toolchain as code, continuously verified by CI (`nix flake check`).
* **Secrets isolation**: Production IPs, ports, and real hostnames never appear in code or Issue files on the public repository. Actual values are isolated in the local `secrets-agents/` directory, and prose uses `<PLACEHOLDER>` instead.
* **Making tacit knowledge explicit as skills**: When "which file to hand the AI and when" depends on human tacit knowledge, the AI cannot reproduce operations alone. Any procedure statable as "when doing X" becomes a skill with its trigger condition declared in the description. The workflows in the previous section (`new-issue`, `guarantee-audit`, etc.) are committed in this form. See [harness-guide.md](docs-agents/harness-guide.md#knowledge-placement-criteria) for details.

---

## TUI Toolchain & Development Environment

A Nix-unified TUI environment for both agents and humans to work in the same environment.

* **Neovim**: An integrated development environment based on `lazy.nvim`. LSP completion, static type checking, auto-formatting (conform.nvim), Yazi integration, and automatic session restoration.
* **Yazi**: A file manager written in Rust. fzf/ripgrep integration and a wrapper function that syncs the shell's current directory on exit.
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
