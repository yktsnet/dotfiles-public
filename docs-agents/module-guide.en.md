[🇯🇵 日本語](module-guide.md) | [🇬🇧 English](module-guide.en.md)

# Module Guide

Design guide for OSS module-style repos (portfolio-cum-practical-tool). Apply it when deciding a new repo's type, adding a module, or judging distribution format and demo method.

---

## 1. Decide the Repo's Type

Define the repo's identity in one sentence as "generic part + domain-specific part." Do not place the domain-specific part's real assets (real client templates, real data, production parameters) in the repo. There are three types.

| Type | Generic part / Domain-specific part | Distribution |
|---|---|---|
| **Embedded type** | A package pulled into the user's build/runtime environment / your own real project as a proving field | Registry publication (JS → npm, Python → PyPI). Mandatory once it's embedded |
| **Toolkit type** | A domain-vocabulary-free engine (`packages/`) / domain application examples (`examples/<domain>/`, fictional data only) | Clone reference |
| **Research type** | The verification framework and method (question and technique) / the answer (parameters, mapping tables, results) is injected externally via Env / config, outside the repo | Clone reference |

- **Clone reference is the default.** Registry publication carries ongoing costs (versioning, backward compatibility, English docs), so pay them only for the embedded type or once actual users appear.
- Follow the domain's own ecosystem for language choice. Don't decide by "npm is the standard" or "pip is the standard."

## 2. Structure

```
repo/
├── packages/ (or src/)   # Generic part. No domain vocabulary
│   └── <module>/
│       ├── cli.*         # A CLI entry point per module (doubles as demo and verification)
│       └── demo.tape     # VHS script (bundled to keep the demo reproducible)
├── tests/                # Mirrors src
└── examples/<domain>/    # Application examples (fictional/neutral data only)
```

- Do not directly import external dependencies (DB, external APIs, conversion services, time); inject them via arguments/factories. Run tests with fakes.
- The generic part must not import the assembling side (app). Keeping this one-way dependency means a later registry spin-off is just a directory move.
- Derive the MVP's definition of done (DoD) from "a real user can use it for a day" × "a third party can grasp the value in 30 seconds," and enumerate it in PLAN.md.

## 3. Demo

- **Do not stand up a permanent URL.** For a module, the demo is a VHS GIF (bundled `.tape`, regenerate with `vhs <tape>`); for an app, a one-shot launch (e.g. `docker compose up`) + a screen-recorded GIF.
- Never show secrets, edge cases, or real data. Also mind data source redistribution terms (showing a few rows is de minimis).
- Don't present demo results/measurements as production track record (a demo run with neutral parameters has no bearing on production).
- Treat each language's standard tooling (venv+pip / npm) as the primary setup path; mention Nix only as an optional shortcut (most users are outside Nix).
