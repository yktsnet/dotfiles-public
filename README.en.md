[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

In development with AI agents, the bottleneck shifts from generation to verification and intent transfer.
This repository publishes a personal development environment built on that premise, as code: the Nix configuration, the machinery for role separation, and the skill set.
The development method itself is packaged for team repositories in [sdlc-kit](https://github.com/yktsnet/sdlc-kit). This repository is the environment where that method actually runs.

---

## Principles (Order of Adoption)

The premise underneath everything is **not relying on a human who stays attentive**. Rules depend on the reader's concentration, and concentration drops with fatigue. Prohibitions live in mechanisms rather than documents, CI reruns the same checks as local verification, and the person who broke something (the Builder) gets a path to notice before submitting.

Adoption is stacked in this order:

1. **Decide the type before building** — classify the repo, the README, and the module, and derive every later rule from that
2. **Put prohibitions in mechanisms, not documents** — `settings.json` deny rules and PreToolUse hooks
3. **Place knowledge where it gets read** — rules that always apply in CLAUDE.md; procedures and criteria with a statable trigger in skills
4. **Approve the guarantees first** — the guarantee ledger and its tests (GDD)
5. **Separate the one who decides from the one who builds** — the three roles: Consultant, Builder, and user

The order has dependencies. Without a type, you cannot decide what to block; adding knowledge before blocking only speeds up accidents. Splitting roles before the guarantees are fixed sends the Builder off without knowing what it must not break. **The minimal setup is steps 1–3**, needed regardless of publication or team size. Steps 4–5 are added once there are published artifacts or several sessions running in parallel.

---

## Development Lifecycle (Two Driving Documents)

Development is split into two phases, and the driving document changes with the phase: PLAN.md / JUDGE.md (SDD) during bootstrap, and the guarantee ledger `docs/guarantees.md` with its tests (GDD) after release. Each repository declares its phase in its CLAUDE.md.

The rationale is in sdlc-kit's [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md). For the operating rules in this repository, see [guarantee-audit](.claude/skills/guarantee-audit/SKILL.md).

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

See [new-issue](.claude/skills/new-issue/SKILL.md) for details.

---

## Foundation (Prerequisites for Autonomous Execution)

Autonomous agent execution only works once three things are structurally in place: environment, secrets, and knowledge.

* **Environment consistency via Nix**: Environment differences cause "command not found" and runtime errors for agents. Nix Flakes and Home Manager unify the macOS / Linux toolchain as code, continuously verified by CI (`nix flake check`). Installs that bypass this route (`brew`, `npm -g`, and the like) are blocked by `.claude/hooks/block-non-nix-install.sh`.
* **Secrets isolation**: Production IPs, ports, and real hostnames never appear in code or Issue files on the public repository. Actual values are isolated in the local `secrets-agents/` directory, and prose uses `<PLACEHOLDER>` instead. The dictionary itself isn't kept as local plaintext — it's encrypted and distributed via git, and each device decrypts it with its own key. Without that, a device other than the one holding the plaintext copy would have no way to know what to mask.
* **Making tacit knowledge explicit as skills**: When "which file to hand the AI and when" depends on human tacit knowledge, the AI cannot reproduce operations alone. Any procedure statable as "when doing X" becomes a skill with its trigger condition declared in the description. The workflows in the previous section (`new-issue`, `guarantee-audit`, etc.) are committed in this form. The placement criteria live in [skill-dev](.claude/skills/skill-dev/SKILL.md).
* **Auditing the rules**: CLAUDE.md, skills, and memory all share one structure — rules a human wrote, read by an AI — and none of them detects contradictions between rules. Left alone, an ever-growing rule set destabilizes behavior, so [`consolidate-rules`](.claude/skills/consolidate-rules/SKILL.md) audits on a schedule only the diff since the last audit point (a single anchor line in `.claude/RULES.md`). Persistent memory carries no index at all: one fact per file, directly under `~/memory/`, kept at a granularity where `ls` is the index.

---

## Devices

A single Flake binds the macOS and Linux development machines. Device names are replaced with role-based generics for publication.

| Configuration | OS | Role |
|---|---|---|
| `linux-desktop` | NixOS (disko / SSD) | Primary dev machine. Where consultant chat and `issue()` are launched |
| `macbook` | macOS (nix-darwin) | Shares the home-manager layer with the Linux machine |

OS differences are confined to `pkgs.stdenv.isDarwin` on the Nix side and to the shims in `home-manager/modules/zsh/functions/os.sh` (`_is_darwin`, `_sed_i`, `_open`, `_linux_only`) on the shell side. Home Manager modules and function files are read as-is by both operating systems.

What is published is limited to the layers involved in developing with agents (Claude Code, memory, secrets, review, tmux session management). Editor and desktop settings and server configurations are not included.

---

## Skills

Criteria and procedures are held by the skill that uses them. There are no standalone guide documents; only what cannot be folded into a skill stays as a separate file (`repo-standardize/reference/cicd.md`, read by several skills, and `.claude/hooks/README.md` on how to write hooks). The criteria for what gets published are in [.claude/skills/README.md](.claude/skills/README.md). Skills are written in Japanese.

| Area | Skill | What it holds |
|---|---|---|
| Deciding the type | [repo-standardize](.claude/skills/repo-standardize/SKILL.md) | Repo categories and verification, settings.json, CLAUDE.md and context/, file hygiene. CI/CD in [reference/cicd.en.md](.claude/skills/repo-standardize/reference/cicd.en.md) |
| | [repo-readme](.claude/skills/repo-readme/SKILL.md) | README type (A / B / C), floor, core message, outline |
| | [module-dev](.claude/skills/module-dev/SKILL.md) | Module-repo types, boundaries, demos |
| | [mermaid-diagram](.claude/skills/mermaid-diagram/SKILL.md) | Whether to draw, width limits, shapes and line types |
| Placing knowledge | [skill-dev](.claude/skills/skill-dev/SKILL.md) | Placement criteria, narrowing auto-invocation, splitting out exploration |
| | [consolidate-rules](.claude/skills/consolidate-rules/SKILL.md) | Auditing rules for contradictions and staleness |
| Guarantees | [guarantee-audit](.claude/skills/guarantee-audit/SKILL.md) | Test policy (GDD), laying and auditing the guarantee ledger |
| | [mvp-docs](.claude/skills/mvp-docs/SKILL.md) | PLAN.md / JUDGE.md during bootstrap |
| Role separation | [new-issue](.claude/skills/new-issue/SKILL.md) | Phases, role separation, the three exception routes, Issue design |
| | [pr-workflow](.claude/skills/pr-workflow/SKILL.md) | The Builder's flow from implementation to local commit |
| | [session-nudge](.claude/skills/session-nudge/SKILL.md) | Consulting on another session from the outside |
| Publishing | [readme-i18n](.claude/skills/readme-i18n/SKILL.md), [repo-publish](.claude/skills/repo-publish/SKILL.md), [repo-about](.claude/skills/repo-about/SKILL.md) | English README, going public, About and topics |
| Prerequisites | [nix-tool-install](.claude/skills/nix-tool-install/SKILL.md), [sops-secrets](.claude/skills/sops-secrets/SKILL.md), [jp-writing](.claude/skills/jp-writing/SKILL.md) | Installing via Nix, encrypting secrets, Japanese writing rules |
