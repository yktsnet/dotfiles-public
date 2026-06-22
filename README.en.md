[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Nix-Powered Workspace for AI-Agent Collaborative Development

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

An Issue-Driven declarative development workspace for collaborative development with AI coding agents (Claude Code / Jules) and humans through clearly separated roles.  
Built on Nix Flakes and Home Manager, it eliminates environment differences between macOS and Linux, providing a foundation where agents always operate on an identical toolchain.

---

## Philosophy & Core Architecture

To maximize the autonomous editing capabilities of AI agents while preventing code generation that deviates from human design intent (agent runaway), this project adopts an Issue-driven development flow that separates "design, implementation, and verification."

### 1. Role Separation

Clearly defines responsibilities according to the strengths of humans, conversational AI, and autonomous AI agents.

* **WebChat (Design / Conversational AI)**:
  Engages in dialogue with the user to formulate specifications and create design files. Does not write verification procedures.
* **AI Agent (Implementation / Autonomous AI)**:
  Autonomously executes code editing, static error checking, and PR creation using Issue files as input. Destructive commands in production environments are prohibited.
* **User (Verification / Human)**:
  Follows the verification procedures in PRs created by agents to perform operational checks and merge into the main branch.

### 2. Nix's Role in Eliminating Environment Differences to Support Agents

For autonomous agents to write code and run tests, it is essential to eliminate local machine state dependencies (environment differences).  
This repository adopts Nix Flakes and Home Manager as base infrastructure. Across MacBook (macOS) and Linux desktop, the toolchain used by agents (Neovim, Yazi, Git, LSP, etc.), executables, and environment variables are fully unified as code. This prevents agents from encountering "command not found" and "runtime errors" due to environment differences, ensuring a seamless AI collaborative development foundation across different operating systems.

### 3. Secrets & Config Isolation

To prevent specific confidential information (secrets) such as production IPs, port numbers, and actual hostnames from being directly written in code or Issue files in the public repository, design values are isolated in a local `secrets-agents/` directory for agent reference.

---

## Agent Profiles & Branch Management

Branch management and instruction files are optimized according to the characteristics of the AI agent's execution environment. See [docs-agents/issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) for detailed workflow behavior.

| Agent | Execution Environment | Branch Management | Persistent Instruction File |
|---|---|---|---|
| **Claude Code** | Local machine environment | Auto-generates and operates local branches | `CLAUDE.md` |
| **Jules** | Cloud sandbox | No local branch creation; operates entirely on remote | `AGENTS.md` |

---

## Project Structure

Running `issue-init` (or `jules-init`) generates the following common directory structure and the instruction file for the selected agent in the **target development repository** (not this repository's own structure).

```text
{target-repository}/
├── CLAUDE.md        # System instruction file for Claude Code
├── AGENTS.md        # System instruction file for Jules
├── context/         # Common coding rules and configuration documents
│   ├── conventions.md
│   └── structure.md
└── issues/          # Development task (Issue) files
    ├── 00_template.md  # Template defining 2-digit sequential ID, branch-slug, target files, etc.
    └── {NN}_{slug}.md  # Designed task files
```

---

## Core Workflows (Zsh Functions)

The following shell macros integrated into Zsh enable seamless keyboard-driven processing from ticket management to agent launch and post-merge cleanup.

* **`issue-init` / `jules-init`** (Environment initialization):
  Initializes a development repository for AI collaborative development. Auto-deploys the common context directory and instruction files (`CLAUDE.md` / `AGENTS.md`) for the target agent.
* **`issue` / `jules`** (Ticket launch):
  Selects `status: open` Issue files with fzf preview.
  * **For Code**: Automatically creates and checks out a dedicated local branch `claude/{id}-{slug}`, then launches the Claude CLI.
  * **For Jules**: Submits tasks directly to a cloud session without creating a local branch.
* **`issue-abort` / `jules-abort`** (Development interruption):
  Interrupts the current agent task, clears in-progress edits, and safely returns to the main branch.
* **`issue-finish` / `jules-finish`** (PR merge and close):
  Searches and selects the created PR via `gh`, automatically merges it into the main branch. Cleans up local and remote work branches, rewrites the target local Issue file to `status: close`, and automatically pushes to the main branch.

---

## TUI Toolchain & Development Environment

A Nix-unified TUI (Text User Interface) environment for both agents and humans to work in the same environment.

* **Neovim (IDE & Editor)**: A highly modularized integrated development environment based on `lazy.nvim`. Features LSP-based auto-completion and static type checking, automatic code formatting (conform.nvim), seamless Yazi integration, buffer-type file operations (Oil.nvim), floating terminal (ToggleTerm), and automatic session restoration to maximize development efficiency.
* **Yazi (Terminal File Manager)**: A blazing-fast file manager written in Rust. Equipped with high-speed search via fzf/ripgrep integration and a wrapper function that syncs the shell's current directory on exit.
* **Tmux (Terminal Multiplexer)**: Settings that bridge remote/local differences: prefix-key-free pane switching/splitting, transparent clipboard sync via OSC 52, True Color support. Seamlessly operable with the same shortcuts as Neovim's split windows (Alt + arrows, Alt + /, Alt + -, Alt + x).

For detailed keybindings and configuration, see [TUI Environment (docs/tui_environment.md)](docs/tui_environment.md).

---

## Agent Development Guides

A set of guides for starting AI Agent collaborative development in a new repository. Hand all 4 files to the AI together to build a standard development environment.

| Guide | Role |
|---|---|
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | Process layer. Issue-driven development flow, role separation, shell functions |
| [harness-guide.md](docs-agents/harness-guide.md) | Harness layer. `.claude/` structure, settings.json, instruction files, verification methods |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD layer. GitHub Actions, auto-deployment, Cloudflare Tunnel |
| [readme-guide.md](docs-agents/readme-guide.md) | README writing guide. Structure, language rules, JUDGE.md integration |
