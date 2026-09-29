[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

A personal development environment for handing development to AI agents, published as a Nix configuration together with the rules it enforces.
The parts that carry over to team repositories are packaged separately in [sdlc-kit](https://github.com/yktsnet/sdlc-kit); this is the environment where those practices actually run.

---

## From Writing to Checking

As agents wrote more of the code, my own work moved from writing to checking. The more there was to check, the more the way I checked drifted from day to day. On tired days I missed things; on rushed days I skipped steps. The agents were no different: a rule followed in one session got overlooked in the next.

So, bit by bit, I moved what I wanted followed out of documents that ask for compliance and into an environment that leaves no way around it. Neither the people nor the agents are expected to remember.

---

## Rules Live in the Environment

Rules are sorted by where they live. Rules that apply every time go in CLAUDE.md, procedures and criteria whose trigger can be stated as "when doing X" go in skills, and anything that must not be crossed goes in the `settings.json` deny list and hooks. All of it is then distributed through Nix, so the same rules apply in any repository on any machine.

### One Toolchain on Every Machine

One flake manages the macOS and Linux development machines. When tools or versions differ between machines, agents stall on "command not found" or "behaves differently", and a person ends up spending time finding out why.

| Configuration | OS | Role |
|---|---|---|
| `linux-desktop` | NixOS (disko / SSD) | Primary dev machine. Where consultant chat and `issue` are launched |
| `macbook` | macOS (nix-darwin) | Shares the home-manager layer with the Linux machine |

OS differences are confined to `pkgs.stdenv.isDarwin` on the Nix side and to the shims in `os.sh` (`_is_darwin`, `_sed_i`, `_open`, `_linux_only`) on the shell side; everything else is the same file on both. When an agent reaches for `brew` or `npm -g`, `block-non-nix-install.sh` stops it and points to the Nix procedure ([nix-tool-install](.claude/skills/nix-tool-install/SKILL.md)).

### Blocks Are Mechanisms, Not Requests

`rebuild` commands, edits to `flake.lock`, `ssh`, and reading or writing the secrets mapping are closed off by deny rules. Deny rules only match string prefixes, so anything that has to be judged as an action, such as a path-qualified `/tmp/venv/bin/pip install` or rewriting `~/.claude` through `sed -i`, is handled by [PreToolUse hooks](.claude/hooks/).

Each hook's rejection message states both why it stopped and the correct route. A rejected agent tries something else, and what it tries comes from the message, so it takes the route written there. `static-check.sh`, which syntax-checks the single file right after each edit, follows the same idea: it takes a check that nobody would notice being skipped out of the model's discretion.

### One Source for Every Session

The settings, hooks, and skills in `.claude/`, together with `home-manager/config/claude/common.md`, are the source of truth. `home-manager/modules/claude.nix` copies them into `~/.claude` on every rebuild. Since `~/.claude` is a generated artifact, `block-live-claude-config-edit.sh` rejects direct edits there and returns the source path instead.

As rules accumulate, they start to contradict each other. [consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) audits only what changed since the last inventory point (a one-line anchor in `.claude/RULES.md`). Persistent memory lives directly under `~/memory/`, one fact per file, and `memory.nix` puts it on the git path so every machine sees the same set.

### Deciding and Building Are Separate

When the same model both decides and builds, it cannot notice on its own that it has gone off course. The work is split into three roles.

- **Consultant**: designs the spec and the Issue in dialogue with the user. Does not implement ([new-issue](.claude/skills/new-issue/SKILL.md))
- **Executor**: takes an Issue and carries it through implementation, tests, and a local commit. Never touches the remote ([pr-workflow](.claude/skills/pr-workflow/SKILL.md))
- **User**: approves the Issue's guarantee section, reviews the commits, and publishes them

Hand-offs go through zsh functions. `issue` creates a worktree and launches the executor, `issue-finish` takes a reviewed branch from push through PR, merge, and cleanup, and `issue-abort` discards the worktree along with its branch. Each worktree is isolated, so several Issues can run in parallel. The executor's changes are reviewed line by line in [crit](https://github.com/tomasz-tomczyk/crit).

[session-nudge](.claude/skills/session-nudge/SKILL.md) provides a reader standing outside the parallel sessions; it sends advice to another session only after the user approves the draft. Real-time work such as incident response, one-off exceptions the user declares, and small changes that do not touch logic go through without an Issue.

### Secrets Stay Out of the Prose

Issues, PRs, and commit messages use `<PLACEHOLDER>` instead of IPs, ports, and real hostnames. The mapping between real values and placeholders lives in `secrets-agents/`, which agents are not allowed to read or write.

If the mapping existed on only one machine, writing on any other machine would mean not knowing what to mask. The mapping is encrypted with sops (age) and distributed through git, and each machine decrypts it with its own key ([sops-secrets](.claude/skills/sops-secrets/SKILL.md)).

---

## What Ships to sdlc-kit

Of the practices running here, the ones that carry over to team repositories are packaged in [sdlc-kit](https://github.com/yktsnet/sdlc-kit). Only practices that meet at least one of three conditions go in: they keep a human decision from being skipped, they have to survive across sessions, or they have to come out the same when the person changes. That covers the task flows, PLAN.md / JUDGE.md for the launch phase, the guarantee ledger after release, and the guards that protect main. The idea of running development on two driving documents is in sdlc-kit's [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md).

Unifying tools through Nix, distributing `~/.claude`, decrypting the mapping, and persistent memory are tied to the machine, so a team repository cannot enforce them. They stay in this repository.

---

## What Is Not Here

Only the layers involved in developing with agents (Claude Code, memory, secrets, review, and tmux session management) are extracted from the working dotfiles. Editor and desktop settings and server configurations are not included. This is an extract, not a mirror, so some things in the working environment are absent here. The criteria for what gets published are in [.claude/skills/README.md](.claude/skills/README.md).

The repository is not meant to be cloned and applied to your own machines. The device configurations assume the actual hardware and keys, and the encrypted contents of `secrets/` are not included. CI's `nix flake check` confirms that the published configuration still evaluates.

---

## Repository Map

| Path | Contents | Section |
|---|---|---|
| `flake.nix`, `devices/` | NixOS / nix-darwin configurations for the dev machines. Shared parts in `devices/common/` | One Toolchain |
| `home-manager/modules/` | Claude Code distribution, memory, secrets, tmux, crit. Issue-driven functions in `zsh/` | One Source, Deciding and Building |
| `.claude/settings.json`, `.claude/hooks/` | Deny rules and hooks | Blocks Are Mechanisms |
| `.claude/skills/` | Procedures and criteria. Index in [.claude/skills/README.md](.claude/skills/README.md) | All sections |
| `secrets-agents/` | Where the mapping is decrypted (`example.md` is a sample) | Secrets |
| `issues/` | This repository's own Issues and PR records | Deciding and Building |
