[🇯🇵 日本語](module-guide.md) | [🇬🇧 English](module-guide.en.md)

# Module Guide

Design guide for OSS module-style repos (portfolio-cum-practical-tool). Apply it when deciding a new repo's type, adding a module, or judging distribution format and demo method.

---

## 1. Decide the Repo's Type

Define the repo's identity in one sentence as "generic part + domain-specific part." Do not place the domain-specific part's real assets (real client templates, real data, production parameters) in the repo.

Judge the type with the following procedure.

```
Is the generic part pulled into the user's build/runtime environment? ── yes → Embedded type
   └ no (the user reads it and transposes it into their own context)
      Does the repo present a reusable machine, or a discipline of question and verification? ── machine → Toolkit type
                                                                              └ discipline → Research type
```

The first question is settled by an objective fact (whether it's imported/required), so it rarely splits. The split usually happens at the second question, on the boundary between Toolkit type and Research type.

**Litmus test for Toolkit vs Research** (use this when in doubt): if you moved every parameter and every piece of data out to external injection/config, would the repo on its own still have value as a "working machine"? If yes, the machine is the star: Toolkit type. If no — meaning what gets injected from outside is the answer itself, and the machine is only a means to produce it — the discipline is the star: Research type.

There are three types.

| Type | Generic part / Domain-specific part | Distribution |
|---|---|---|
| **Embedded type** | A package pulled into the user's build/runtime environment / your own real project as a proving field | Registry publication (JS → npm, Python → PyPI). Mandatory once it's embedded |
| **Toolkit type** | A domain-vocabulary-free engine (`packages/`) / domain application examples (`examples/<domain>/`, fictional data only) | Clone reference |
| **Research type** | The verification framework and method (question and technique) / the answer (parameters, mapping tables, results) is injected externally via Env / config, outside the repo | Clone reference |

- **Clone reference is the default.** Registry publication carries ongoing costs (versioning, backward compatibility, English docs), so pay them only for the embedded type or once actual users appear.
- Follow the domain's own ecosystem for language choice. Don't decide by "npm is the standard" or "pip is the standard."

#### Relationship to readme-guide.md's Type A/B/C

`readme-guide.md` §1's Type A/B/C (the classification that decides how the README is written) and this section's Embedded/Toolkit/Research type (the classification that decides design and distribution format) are not judged independently; deciding one largely settles the other (not a mechanical one-to-one mapping). Embedded type is almost always Type B (usage-guarantee), since being pulled into the user's build is its definition. Research type is almost always Type C (experiment/Lab), since "the question and the measured results" is itself the claim, matching Type C's claim shape of "this is what measuring showed." Toolkit type is where the range lives: if the claim centers on actually letting people use the machine, it's Type B; if it centers on the fact of having built the machine, with no real users assumed (a portfolio piece), it's Type A. The order in which these are decided is also fixed: Embedded/Toolkit/Research type is decided at the design stage, before any code is written, by `module-dev`, and it dictates the structure and distribution format. Type A/B/C is judged only after working code exists, by `repo-standardize` using §1 and §3 (it cannot be judged before code exists). If the two disagree, this section's type wins, since it was decided first and is already reflected in the structure, and Type A/B/C is corrected to match it.

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

### Where to Draw the Boundary

Spot "domain vocabulary" by whether industry-specific terms show up directly in variable names, type names, or config keys. `patientId` or `claim_status` is domain vocabulary; `itemId` or `state` is generic vocabulary. The hard cases look generic but actually assume an industry convention (`approvalWindow` meaning a specific industry's approval-flow day count, for example); for those, read the calling context to decide.

When you can't tell whether something belongs on the generic side or the domain-specific side, put it on the domain-specific side. Stripping something back out of the generic side later is expensive (it becomes a redesign touching callers, tests, and docs), while promoting something from the domain-specific side to the generic side is cheap (extract a function while leaving one working implementation in place). This asymmetry is why anything undecided should stay on the domain-specific side.

Only split off a module once two or more implementations of the same abstraction exist. Extracting an abstraction with only one implementation means the interface you extracted won't fit the actual second use case, and you end up rebuilding it.

## 3. Demo

- **Do not stand up a permanent URL.** For a module, the demo is a VHS GIF (bundled `.tape`, regenerate with `vhs <tape>`); for an app, a one-shot launch (e.g. `docker compose up`) + a screen-recorded GIF.
- Never show secrets, edge cases, or real data. Also mind data source redistribution terms (showing a few rows is de minimis).
- Don't present demo results/measurements as production track record (a demo run with neutral parameters has no bearing on production).
- Treat each language's standard tooling (venv+pip / npm) as the primary setup path; mention Nix only as an optional shortcut (most users are outside Nix).

## 4. Judging Whether to Add to an Existing Repo

Whether to add a new module to an existing repo or start a new one is judged by the generic part's distribution unit. If publishing under the existing repo's distribution unit (the same registry package, the same clone reference) causes no problem, add it to the existing repo. If the distribution unit would change (e.g. the existing repo is an npm package and the new module is a toolkit in a different language), start a new repo.

If you find yourself wanting to add a module that doesn't fit the existing repo's type, don't add it. Adding a Toolkit-type module to a Research-type repo breaks the repo's claim (that the question and measured results are the substance). A module whose type doesn't fit gets spun off as its own new repo instead.
