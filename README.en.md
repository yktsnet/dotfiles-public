[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Nix-Powered Workspace for AI-Agent Collaborative Development

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

Environment differences get in the way of an agent's autonomous execution. And because agents act without a human checking each step, they can let destructive operations or secret leaks slip straight through.  
The former is resolved by declaratively unifying the macOS / Linux toolchain with Nix Flakes. The latter is contained through Issue-driven role separation and the isolation of secrets and restriction of operations.

---

## Philosophy & Core Architecture

To leverage the autonomous editing capabilities of AI agents while keeping their execution from reaching the main branch or production without human review, this project adopts an Issue-driven development flow that separates "design, implementation, and verification."

### 1. Role Separation

Clearly defines responsibilities according to the strengths of humans, conversational AI, and autonomous AI agents.

* **WebChat (Design / Conversational AI)**:
  Engages in dialogue with the user to formulate specifications and create design files. Does not write verification procedures.
* **AI Agent (Implementation / Autonomous AI)**:
  Autonomously executes code editing, static error checking, and PR creation using Issue files as input. Destructive commands such as `rebuild` and access to secrets are structurally blocked by the deny list in `.claude/settings.json`.
* **User (Verification / Human)**:
  Follows the verification procedures in PRs created by agents to perform operational checks and merge into the main branch.

### 2. Nix's Role in Eliminating Environment Differences to Support Agents

For autonomous agents to write code and run tests, it is essential to eliminate local machine state dependencies (environment differences).  
This repository adopts Nix Flakes and Home Manager as base infrastructure. Across MacBook (macOS) and Linux desktop, the toolchain used by agents (Neovim, Yazi, Git, LSP, etc.), executables, and environment variables are unified as code. This prevents agents from encountering "command not found" and "runtime errors" due to environment differences. This consistency is continuously verified by CI (`nix flake check`).

### 3. Secrets & Config Isolation

To prevent specific confidential information (secrets) such as production IPs, port numbers, and actual hostnames from being directly written in code or Issue files in the public repository, design values are isolated in a local `secrets-agents/` directory for agent reference.

---

## Agent Profiles & Branch Management

Branch management and instruction files are optimized according to the characteristics of the AI agent's execution environment. See [docs-agents/issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) for detailed workflow behavior.

| Agent | Execution Environment | Branch Management | Persistent Instruction File |
|---|---|---|---|
| **Claude Code** | Local machine environment | Auto-creates a worktree + branch and runs in isolation | `CLAUDE.md` |
| **Jules** | Cloud sandbox | No local branch creation; operates entirely on remote | `AGENTS.md` |

---

## Core Workflows (Zsh Functions)

The following shell macros integrated into Zsh enable seamless keyboard-driven processing from ticket management to agent launch and post-merge cleanup.

* **`issue` / `jules`** (Ticket launch):
  Selects `status: open` Issue files with fzf preview.
  * **For Code**: Auto-creates worktree `{repo}.wt/{id}-{slug}` on branch `claude/{id}-{slug}` and launches the Claude CLI inside it. The main checkout stays clean, and multiple Issues can run in parallel.
  * **For Jules**: Submits tasks directly to a cloud session without creating a local branch.
* **`issue-abort` / `jules-abort`** (Development interruption):
  Picks an in-progress `claude/*` worktree via `fzf` and discards it together with its work branch. The main checkout is untouched.
* **`issue-finish` / `jules-finish`** (PR merge and close):
  Searches and selects the created PR via `gh`, automatically merges it into the main branch. Cleans up merged worktrees and local/remote branches, leaves a record-only GitHub Issue (create → close immediately), rewrites the target local Issue file to `status: close`, and automatically pushes to the main branch.
* **`skill`** (Claude Code Skill launcher):
  Lists manual-execution skills (those with `manual: true` in SKILL.md frontmatter) under the dotfiles `.claude/skills/` via `fzf` with preview, and launches the selected skill with `claude /{skill-name}`.

---

## TUI Toolchain & Development Environment

A Nix-unified TUI (Text User Interface) environment for both agents and humans to work in the same environment.

* **Neovim (IDE & Editor)**: A highly modularized integrated development environment based on `lazy.nvim`. Features LSP-based auto-completion and static type checking, automatic code formatting (conform.nvim), seamless Yazi integration, buffer-type file operations (Oil.nvim), floating terminal (ToggleTerm), and automatic session restoration to maximize development efficiency.
* **Yazi (Terminal File Manager)**: A blazing-fast file manager written in Rust. Equipped with high-speed search via fzf/ripgrep integration and a wrapper function that syncs the shell's current directory on exit.
* **Tmux (Terminal Multiplexer)**: Settings that bridge remote/local differences: prefix-key-free pane switching/splitting, transparent clipboard sync via OSC 52, True Color support. Seamlessly operable with the same shortcuts as Neovim's split windows (Alt + arrows, Alt + /, Alt + -, Alt + x).

For detailed keybindings and configuration, see [TUI Environment (docs/tui_environment.md)](docs/tui_environment.md).

---

## Agent Development Guides

A set of guides for starting AI Agent collaborative development in a new repository. Hand all 5 files to the AI together to build a standard development environment.

| Guide | Role |
|---|---|
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | Process layer. Issue-driven development flow, role separation, shell functions |
| [harness-guide.md](docs-agents/harness-guide.md) | Harness layer. `.claude/` structure, settings.json, instruction files, verification methods |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD layer. GitHub Actions, auto-deployment, Cloudflare Tunnel |
| [readme-guide.md](docs-agents/readme-guide.md) | README writing guide. Structure, language rules, JUDGE.md integration |
| [repo-guide.md](docs-agents/repo-guide.md) | Repository structure, secrets management, pre-publish checklist |
