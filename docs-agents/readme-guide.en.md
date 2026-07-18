[🇯🇵 日本語](readme-guide.md) | [🇬🇧 English](readme-guide.en.md)

# README Guide

A guide for writing public-repo READMEs. When writing a new repo's README, **judge the type → decide the core message and target → build an outline (H2s) that fits them**. Think in this order.

Deployment details live in `cicd-guide.md` and verification methods in `harness-guide.md`, so the README does not duplicate them.

The goal of this guide is not to force every README into one template. It is to make **each published repo's README a single coherent argument**. Coherent means the following three things line up in a straight line.

- **Core message** … what you want a reader to think this repo is, in one phrase
- **Target** … who you write for (assumed to be a developer; pick by skill level, role layer, or users of a specific technology)
- **Outline** … the H2 structure that conveys the two points above best

No fixed list of required sections is imposed. Instead, only a **per-type "floor" (the points that must be satisfied)** is defined; the outline above it is decided dynamically per repo. The floor is a set of points to satisfy, not a fixed order or naming of H2s.

---

## 0. The Order of Thinking (How to Use This Guide)

```
Type judgment (Type A / B / C)
   └─ Floor: the set of points that must be satisfied (no order)   ← static, defined by this guide
        └─ Core message + Target                                   ← decided per repo
             └─ Outline (H2 order, naming, weight)                 ← dynamic, derived from the above
```

---

## 1. Type Judgment (Type A / B / C)

```
Meant to be used? ── yes → Type B (usage-guarantee)
   └ no (meant to be read)
      Is the evidence code, or numbers? ── code → Type A (demonstration)
                                          └ numbers → Type C (experiment / Lab)
```

| | **Type A: Demonstration** | **Type C: Experiment (Lab)** | **Type B: Usage-guarantee** |
|---|---|---|---|
| Character | A "built it / carried out the migration" sample or portfolio piece | An experiment repo whose question and measured results are the substance; distribution exists only as a replication path | A tool/library a third party is guaranteed to be able to adopt and use |
| Shape of the claim | "**I built it**": this structure / this migration holds up | "**I found out**": this is what measuring showed | "**You can use it**": what it does, how to install it, what it guarantees |
| Reader (default target) | Reviewers, recruiters, technical decision-makers. **People who read the code and design decisions** | People who read the results and method. Replicators are a minority second audience | Users and adopters. **People who run it and integrate it** |
| When was the conclusion known | Known at the start (making it hold up is the goal) | Unknown until execution (finding out is the goal) | n/a (provides guarantees, not conclusions) |
| Position of reproducibility | Not needed (visible on inspection) | **Lifeline** (fixed seeds and materials underwrite the claim) | Part of the guarantee (works regardless of environment) |
| Logic of the structure | Narrative (problem → solution → grounds for decisions) | A condensed paper (question → method → **results** → discussion → replication) | Usage path (install → usage → configuration → limitations) |

**Litmus test for A vs C** (use this when in doubt):

1. **If you deleted every result number, would the repo still have value?** If yes, it's A (the code is the substance); if no, it's C (the numbers are).
2. **Was the conclusion known before you started building?** If yes (showing it can be done), it's A; if you didn't know until you measured, it's C.

---

## 2. The Floor (Points That Must Be Satisfied)

For each type, define the points the README must satisfy.

### Type A Floor

- The core message sits directly under the H1 in one sentence
- There are run steps (the entry point of the demonstration; copy-paste runnable)
- The body of the demonstration is told in problem → solution logic
- Technology choices have a Why (not just what is used, but why that)
- Scope is explicit (what it specializes in / what it does not do)

### Type B Floor

- The core message sits directly under the H1 in one sentence
- There are install steps (Installation / Quick Start)
- There is a minimal usage example (Usage)
- Reference information needed to use it (configuration, API) exists
- Scope is explicit (supported / unsupported)

### Type C Floor

- The core message (the **question**) sits directly under the H1 in one sentence
- **Results are in the README body** (tables, numbers; never deferred to a link — this is the biggest difference from A / B)
- There is a summary of the method (the full text may retreat to docs/)
- There are replication steps. The guarantee is phrased the opposite way from B: "the same steps, seed, and material version are designed to yield the same numbers; other environments and uses are not guaranteed." If a ledger (`docs/guarantees.md`) exists, link to it
- Scope is explicit (what is measured and what is not)

Not needed for Type C: a problem→solution narrative, or the Why of technology choices in the body (the rationale for the measuring apparatus belongs in docs/).

> **Coherence check**: does the core message sentence → the summary under the H1 → each H2 support one and the same claim in a straight line? If a section drifts into a different story, that H2 is misaligned with either the core message or the target.

---

## 3. How to Decide the Core Message

> What do you want a reader to think this is, in one phrase?

On top of satisfying the floor, fix the per-repo "thing you want to convey" into one sentence here. This becomes the backbone of the whole README.

- Write it in **one sentence**, with "This repo" (or an equivalent subject) as the subject
- Include "**what it solves / demonstrates / asks**" + "**by what means**"
- Boastful adjectives ("fast", "modern", "high-quality") and plain feature lists are forbidden
- **Make this sentence identical to the 1–2 line summary directly under the H1** (core message = summary)

Example (Type A): "A sample that incrementally migrates a legacy WinForms business app to `.NET 8 + React`, walking through the teardown and reconstruction up to adding an AI natural-language interface."

Example (Type C): "A benchmark that resolves which article title a Wikipedia article stripped of its opening definition corresponds to, using a fixed-coefficient formula, a retrainable GBDT, and LLM re-judgment, and measures whether it keeps succeeding when the corpus is re-drawn."

---

## 4. How to Decide the Target

Assuming a developer audience, pick one target. The target does not change the floor. It acts as a **lever, on top of the floor, that decides what to weight, what to put first, and how to name things**.

| Axis | Examples | How it affects the structure |
|---|---|---|
| Skill level | Junior / mid / senior | How hand-holding the Quick Start is; whether prerequisites can be omitted |
| Role / layer | Frontend / backend / infra / specific-domain owner | Whether to weight Architecture or Tech Stack |
| Technology users | For "users of this technology" vs "users of the artifact" | Whether to lead with usage examples and API, or design philosophy |

If the target changes, the same material gets different weight and order. The core message and the target together derive the outline that follows.

---

## 5. Building the Outline

With satisfying the floor (§2) as the minimum condition, decide the H2s dynamically from the core message (§3) and target (§4). Pull H2s as needed from the following "material pool."

| Material | Content | Suited types |
|---|---|---|
| **Overview** | Purpose, background, demo URL | A / B / C |
| **Architecture** | Diagram (Mermaid), data flow, layer structure. Diagrams over prose | A / B |
| **Before / After** (name freely) | Pre-migration problems and post-migration structure. The body of the demonstration | A |
| **Results** | Tables/graphs of measured results and how to read them. The body of the experiment | C |
| **Method** | Summary of task definition and measurement procedure (full text to docs/) | C |
| **Tech Stack** | Table format. Technology + reason (Reason column) | A / B |
| **Design Decisions** | Selection rationale consolidated from JUDGE.md. Write the Why | A / B / C |
| **Usage / API** | Usage examples, endpoints, configuration | B |
| **Reproduce** | Replication steps (fixed seeds and material versions, resource caveats) | C |
| **Scope** | Focus (what it specializes in) and Out-of-Scope (what it does not do) | A / B / C |
| **Deploy** | Deployment-method overview only (see §8) | Public apps only |
| **Comparison** | Comparison with sibling repos or existing methods | A / C |
| **Directory Structure** | Tree format. Comments on key files | A / B |

### H1 + Badges

```markdown
# Project Name

[![CI](https://github.com/{owner}/{repo}/actions/workflows/ci.yml/badge.svg)](...)
[![Deploy](https://github.com/{owner}/{repo}/actions/workflows/deploy.yml/badge.svg)](...)

(A 1–2 line summary identical to the core message)
```

Deploy badge only for repos with auto-deployment.

### Run Steps (Quick Start / Installation)

If it runs on Docker, write the Docker-only steps first. Split individual language-runtime installs into a Local Development section. Make it copy-paste runnable.

```markdown
## Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Setup
\```bash
cp .env.example .env
docker compose up -d --build
\```

- App: http://localhost:{port}
```

For Type C this section becomes the replication steps. If large materials are required (multi-GB dumps, etc.), state so with size and source, and give readers who only want the results a path that avoids the download (e.g. generated data attached to Releases).

### Tech Stack

Write technologies and their selection reasons in a table. Not just "what is used" but "why that."

```markdown
## Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| Frontend | React, TypeScript, Vite | ... |
| Backend | .NET 8 (Minimal API) | ... |
```

---

## 6. Language Rules

- Headings H1–H3 are in English
- Body text, H4 and below, and table contents are in Japanese

English headings make the structure internationally readable; Japanese body text preserves precision.

---

## 7. Integrating JUDGE.md / PLAN.md and Splitting into docs/

### Integrating JUDGE.md / PLAN.md (integration = relocation + deletion)

During development, record technology-selection criteria in `JUDGE.md` and the MVP's definition and completion criteria in `PLAN.md`. These are not instruction files for the AI; they are the user's work products. On publication, integrate them into the README and **delete the originals once integrated** (history lives in git; do not keep double bookkeeping between README and originals).

- `JUDGE.md` … key points go to the README's Design Decisions and the Tech Stack Reason column. The full text moves to `docs/design-decisions.md` (if short, integrate directly into the README and skip docs/) → delete
- `PLAN.md` … at publication the MVP is complete and its role is over. Absorb only the living content (whatever amounts to Scope) into the README's Scope. For Type C, move method descriptions (task definitions, generation scale) to `docs/method.md` → delete
- **Mandatory step before deletion**: grep the repo for references (CLAUDE.md, context/, issues/ may point at them). Rewrite the references to README / docs/ before deleting

> Premise for the AI: "If `JUDGE.md` exists, reflect its criteria in the README's selection reasons." The AI never invents the criteria itself.

### Splitting into docs/

Splitting is not a goal; it is **a retreat that keeps the README a single argument**. Do not assume the split up front; write it in the README first, and retreat only the sections that bloat.

**Split when (either)**:
- The section's full text serves a different reader moment (deep dive, reference, operations) than the flow of the README's core message
- The README needs only the "points that matter for an adoption decision," and the full text is long enough to be skipped over

**Do not split when**:
- Even the full text is a few to a dozen lines, and splitting barely shrinks the README
- The README-side summary and the original would be nearly identical (leaving only double bookkeeping)

**Typical candidates** (not a closed list; create only what applies, never a set of empty files):

| File | Content | Applicable repos |
|---|---|---|
| `docs/design-decisions.md` | Full text of decisions (what was discarded, boundaries for reconsideration) | Any repo with a JUDGE.md |
| `docs/guarantees.md` | Guarantee ledger. Contract-level guarantee bullets + a table of corresponding tests (file, test name). Laid and promoted by the `guarantee-audit` skill | Any repo with tests |
| `docs/method.md` | Full text of task definition, corpus generation, measurement procedure | Type C |
| `docs/reproduce.md` | Full replication steps (only if they don't fit in the README) | Type C |
| `docs/usage.md` | API tables, environment variables, CLI details | Type B / app-style repos |
| `docs/release.md` | Release / publish procedure | Registry-published repos only |
| `docs/deploy.md` | Self-hosting steps for users | Clone-reference-style apps |

`docs/guarantees.md` is a default resident alongside design-decisions.md; the README links to it from the Scope section (as the detail page for "what is guaranteed and what is not").

After splitting, keep the key points + a link to `docs/` on the README side. `docs/` also doubles as the home for README assets (demo GIFs, recording scripts).

**Language pairs**: in repos with a `README.en.md`, create `docs/*.en.md` counterparts for split docs too, with language links at the top of both files (never the asymmetry where only the English README carries the docs/ content inline).

**Type C results are never split out**: the results table and discussion belong in the README body (§2 floor). Only the full method text, raw data, and extra graphs may go to docs/.

---

## 8. Diagrams and the Deploy Section

### Diagrams

Write architecture and data-flow diagrams in Mermaid, embedded inline in the README and rendered by GitHub.

If images are used, place them in `src/` or `docs/` and reference them by relative path. Do not depend on external hosting (imgur, etc.).

### Deploy

The README carries only the deployment-method overview and, if any, the demo URL.

```markdown
## Deploy

**Demo:** https://{subdomain}.{domain}

A push to the main branch triggers an automatic deploy via GitHub Actions (`cicd-guide.md` compose type).
Published via Cloudflare Tunnel.
```

Secrets lists, first-time setup, and server-side configuration are the responsibility of `cicd-guide.md` and operations docs. Do not duplicate them in the README.

---

<sub>*Acknowledgement — the "core message → target → outline" framing in this guide draws on yoshiko-pg's talk at ZennFes 2026: <https://yoshiko-pg.github.io/talks/zennfes-2026/>. With thanks and respect.*</sub>
