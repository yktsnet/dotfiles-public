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

- **Do not leave 0-byte / placeholder-only files.** Don't commit empty content. Don't create scaffolding and abandon it.
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

---

## 4. Pre-Publication Checklist

Run before push / publication.

```
[ ] No 0-byte / placeholder-only files
[ ] No tracked artifacts (binaries/dist/db/node_modules)  (verify with git ls-files)
[ ] No unrelated stack remnants or duplicate lines in .gitignore
[ ] .env is not tracked and .env.example exists
[ ] LICENSE exists with correct year/owner
[ ] No secrets written directly in prose
```
