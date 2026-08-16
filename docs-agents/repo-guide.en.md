[🇯🇵 日本語](repo-guide.md) | [🇬🇧 English](repo-guide.en.md)

# Repo Guide

Repository composition and hygiene guide. Applied when creating new repos and when inspecting before push / publication.
Covers only "what files should exist in the repo, and what should not."

Responsibilities are separated from other guides (no overlap).

| Scope | Guide |
|---|---|
| `.claude/` contents (settings.json, CLAUDE.md, context/, skills) | `harness-guide.md` |
| README contents | `readme-guide.md` |
| Deployment method, host-side `.env` (production values) | `cicd-guide.md` |
| Branch, Issue, and commit process | `issue-driven-workflow.md` |
| **Repo root composition & file hygiene** (this guide) | `repo-guide.md` |

One design principle: **Maintain a single hygiene baseline across all repos.** Even lightweight repos must meet the minimum. No branching by maturity level.

---

## 1. File Hygiene (Rules of Existence)

- **Do not leave 0-byte / placeholder-only files.** Don't commit empty content. Don't create scaffolding and abandon it. The only exception is `.gitkeep`, used to keep an empty directory in git when the directory's existence is itself part of the structure.
- **Do not track build artifacts.** Exclude build binaries, `dist/`, `*.db`, `node_modules/`, `.env` via `.gitignore`. Enforce "may exist locally but must not enter the repo."
- **Separate generated outputs from source files.** Track source files (config JSON, etc.); ignore what's generated from them (DBs, build assets).
- **Always include a LICENSE.** A public repo without a license defaults to all-rights-reserved (nobody can use it). Place one as the legal minimum regardless of social usage. Verify that `Copyright` year and owner are correct (don't leave copy-paste defaults).

---

## 2. `.gitignore` Standards

- **Include only lines needed for your stack.** Don't leave boilerplate from other stacks (unrelated WordPress / Python / Docker, etc.) carried over from templates. If you copied a template, always clean it up.
- No duplicate lines (don't write the same path multiple times).
- Minimum coverage: OS files / dependencies (`node_modules`, etc.) / build artifacts / local DB / `.env`.

---

## 3. Secrets (Repo Side)

- `.env` is ignored; **`.env.example` must always exist** (keys only, no real values).
- Do not write specific connection information in human-readable prose (masking conventions: the Information Security section of `issue-driven-workflow.md`).
- Production `.env` on the host side is outside repo scope (`cicd-guide.md`).

### sops Layer (Encrypted Distribution of Real Values)

`.env.example` covers "keys only in the repo." How the real values themselves get distributed to each device is the domain of sops-nix (age-key encryption). The policy:

- Placing `secrets/<category>/<name>.age` registers it as a secret named `<category>/<name>` without any change to configuration files. Adding a new category also requires no configuration change.
- Format is determined by the filename extension (`.env` → dotenv / `.json` → json / anything else → binary).
- Plaintext secrets are never placed in the repo or on disk. Decrypted files are only ever materialized on a RAM disk.
- When adding a new device, follow the order "register key → re-encrypt existing secrets → build." Getting the order wrong breaks home-manager with secrets that can't be decrypted.

The encrypted files (`.age`) and the real `.sops.yaml` are never committed to the repo. Operational commands are the domain of a skill; this guide stops at policy.

---

## 4. Pre-Publication Checklist

Run before push / publication.

```
[ ] No 0-byte / placeholder-only files (except `.gitkeep`)
[ ] No tracked artifacts (binaries/dist/db/node_modules)  (verify with git ls-files)
[ ] No unrelated stack remnants or duplicate lines in .gitignore
[ ] .env is not tracked and .env.example exists
[ ] LICENSE exists with correct year/owner
[ ] No secrets written directly in prose
```
