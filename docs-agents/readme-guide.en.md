[🇯🇵 日本語](readme-guide.md) | [🇬🇧 English](readme-guide.en.md)

# README Guide

A guide for writing READMEs for public repos. When writing a new README, think in this order: **decide the type → decide the core message and target → build the outline (H2s) that fits them**.

Deployment details live in `cicd-guide.md` and verification methods in `harness-guide.md`, so don't duplicate them in the README.

The goal of this guide is not to force every README into a single template. It is to make **each published repo's README a single coherent argument**. "Coherent" means these three things line up in a straight line:

- **Core message** … In one phrase, what should a reader think this repo is?
- **Target** … Who is it written for (assuming a developer audience: skill level, role/layer, or users of a specific technology)?
- **Outline** … The H2 structure that conveys the two above most effectively.

No fixed list of required sections is imposed. Instead, only a **per-type "floor" (the points that must be satisfied)** is defined; the outline above it is decided dynamically per repo.

---

## 0. The Order of Thinking (How to Use This Guide)

```
Type judgment (Type A / B)
   └─ Floor: the set of points that must be satisfied (orderless)   ← static, defined by this guide
        └─ Core message + Target                                     ← decided per repo
             └─ Outline (H2 order, naming, weight)                   ← dynamic, derived from the above
```

The floor is a set of "points to satisfy," not a fixed order or naming of H2s. Only once the core message and target are decided does the outline take shape in a way that satisfies the floor.

---

## 1. Type Judgment (Type A / Type B)

Public repos fall into two kinds. Decide which one first.

| | **Type A: Demonstration / Report** | **Type B: Usable Tool** |
|---|---|---|
| Nature | A "I tried it / I migrated it" sample or portfolio. Not premised on third-party adoption | A tool/library guaranteed to be usable by third parties |
| Reader (default target) | Reviewers, hiring managers, technical evaluators. **People who read the code and design decisions** | Users and integrators. **People who run it and embed it** |
| Core message type | "What was demonstrated, and with what judgment" | "What it can do, how to install it, what it guarantees" |
| Structural logic | Narrative (problem → solution → rationale) | Usage path (install → usage → config → constraints) |

Guiding question: **Is this repo "a report of a demonstration" or "a tool others use"?** If unsure, look at what the next action of a third-party reader would be: if it's "read the code and decisions," it's A; if it's "install and use," it's B.

---

## 2. The Floor (Points That Must Be Satisfied)

For each type, define the points the README must satisfy. **This is an orderless checklist, not the H2 structure itself.** As long as all points are satisfied, how you split, order, and name the H2s is free.

### Type A Floor

- The core message is placed in one sentence right under H1
- There are steps to run it (the entry point of the demonstration; copy-paste ready)
- The body of the demonstration is told as "problem → solution"
- Technology choices have a Why (not just what is used, but why that one)
- Scope is stated (what it specializes in / what it does not do)

### Type B Floor

- The core message is placed in one sentence right under H1
- There are installation steps (Installation / Quick Start)
- There is a minimal usage example (Usage)
- There is reference info needed to use it (configuration, API, etc.)
- Scope is stated (what is supported / what is not)

> **Criterion for coherence**: Does the chain core message → overview under H1 → each H2 support the same argument in a straight line? If something veers off mid-way, that H2 is misaligned with either the core message or the target.

---

## 3. How to Decide the Core Message

> In one phrase, what should a reader think this repo is?

On top of satisfying the floor, fix the per-repo "thing you want to convey" into one sentence here. This becomes the backbone of the whole README.

- Write **one sentence**. Begin the subject with "This repo" (or an equivalent subject)
- Include "**what it solves / demonstrates**" + "**by what means**"
- Banned: boastful adjectives ("fast," "modern," "high-quality") and bare feature lists
- **Make this one sentence match the 1–2 line overview right under H1** (core message = overview)

Example (Type A): "A sample that incrementally migrates a legacy WinForms business app to `.NET 8 + React`, demonstrating the teardown-and-restructuring process all the way to adding an AI natural-language interface."

---

## 4. How to Decide the Target

Assuming a developer audience, pick one target. The target does not change the floor. It acts as a **lever, on top of the floor, that decides what to weight, what to put first, and how to name things**.

| Axis | Examples | Effect on structure |
|---|---|---|
| Skill level | Junior / Mid / Senior | How hand-holding Quick Start is; whether prerequisites can be omitted |
| Role / Layer | Frontend / Backend / Infra / specific domain | Whether to weight Architecture or Tech Stack |
| Technology user | For "people who use this technology" vs "people who use the artifact" | Whether to show usage examples / API, or design philosophy |

When the target changes, the same material changes in weight and order. The two — core message and target — derive the outline that follows.

---

## 5. Building the Outline

With satisfying the floor (§2) as the minimum condition, decide the H2s dynamically from the core message (§3) and target (§4). **Do not fix the H2 order, naming, or splitting.**

Once the floor is satisfied, pull H2s as needed from the following "material pool."

| Material | Content | Suited type |
|---|---|---|
| **Overview** | Purpose, background, demo URL | A / B |
| **Architecture** | Diagram (Mermaid), data flow, layer structure. Prefer diagrams over prose | A / B |
| **Before / After** (free naming) | Pre-migration problems and post-migration structure. The body of the demonstration | A |
| **Tech Stack** | Table. Technology names + selection rationale (Reason column) | A / B |
| **Design Decisions** | Selection rationale integrated from JUDGE.md. Write the Why | A / B |
| **Usage / API** | Usage examples, endpoints, configuration | B |
| **Scope** | Focus (what it specializes in) and Out-of-Scope (what it doesn't do) | A / B |
| **Deploy** | Deployment method, overview only (see §8) | Public apps only |
| **Comparison** | Comparison with sibling repos or existing approaches | A |
| **Directory Structure** | Tree format. Comments on key files | A / B |

### H1 + Badge

```markdown
# Project Name

[![CI](https://github.com/{owner}/{repo}/actions/workflows/ci.yml/badge.svg)](...)
[![Deploy](https://github.com/{owner}/{repo}/actions/workflows/deploy.yml/badge.svg)](...)

(1–2 line overview matching the core message)
```

Deploy badge only for repos with auto-deployment.

### Run Steps (Quick Start / Installation)

If it runs with Docker, write the Docker-only steps first. Individual language runtime installation goes in the Local Development section. Make it copy-paste ready.

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

### Tech Stack

Write technology names and selection rationale in a table. Not just "what is used" but "why that one."

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

English headings make the structure internationally readable; Japanese body text keeps precision.

---

## 7. JUDGE.md Integration

During development, record the criteria for technology selections in `JUDGE.md` (why that technology/architecture was chosen). This is not an instruction file for AI — it's the user's work product.

At publication, integrate `JUDGE.md` content into the README's Design Decisions section and the Tech Stack Reason column.

- `JUDGE.md` … Decision log during development (ADR-like). Whether to keep it in the repo is optional
- README … Integrated selection rationale. Organized for public consumption

> AI premise: "If `JUDGE.md` exists, reflect its decision criteria into the README's selection rationale." AI does not fabricate decision criteria.

---

## 8. Diagrams and the Deploy Section

### Diagrams

Architecture diagrams and data flows are written in Mermaid. Embedded inline in the README and rendered on GitHub.

When using images, place them in `src/` or `docs/` and reference with relative paths. Do not depend on external hosting (imgur, etc.).

### Deploy

Write only the deployment-method overview and, if any, the demo URL in the README.

```markdown
## Deploy

**Demo:** https://{subdomain}.{domain}

A push to the main branch triggers an automatic deploy via GitHub Actions (`cicd-guide.md` compose type).
Published via Cloudflare Tunnel.
```

The Secrets list, initial setup steps, and server-side configuration are the responsibility of `cicd-guide.md` and operational docs. Don't duplicate them in the README.

---

<sub>*Acknowledgement — the "core message → target → outline" framing in this guide draws on yoshiko-pg's talk at ZennFes 2026: <https://yoshiko-pg.github.io/talks/zennfes-2026/>. With thanks and respect.*</sub>
