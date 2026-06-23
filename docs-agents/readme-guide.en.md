[🇯🇵 日本語](readme-guide.md) | [🇬🇧 English](readme-guide.en.md)

# README Guide

Guide for creating READMEs for public repositories. Rules for structure and writing when composing the README after implementation is complete.

Integrates the technical decision rationale recorded in JUDGE.md during development into the README, making visible not just "what is used" but "why that choice was made."

---

## 1. Language Rules

- Headings H1–H3 are in English
- Body text, H4 and below, and table contents are in Japanese


---

## 2. Structure

Arranged top to bottom. The flow lets the reader get it running quickly, then understand the design intent.

| Section | Content | Required |
|---|---|---|
| **H1 + Badge + Overview** | Project name, CI/Deploy badge, 1–2 line overview | ○ |
| **Quick Start** | Prerequisites → setup steps → startup confirmation URL. Copy-paste ready | ○ |
| **Overview** | Purpose, background, demo URL. What problem does this project solve | ○ |
| **Architecture** | Diagram (Mermaid), data flow, layer structure. Prefer diagrams over prose | ○ |
| **Tech Stack** | Table format. Include selection rationale alongside technology names (see JUDGE.md integration below) | ○ |
| **Design Decisions** | Selection rationale integrated from JUDGE.md. Write the Why | ○ |
| **Scope** | Explicitly state Focus (what it specializes in) and Out-of-Scope (what it doesn't do) | ○ |
| **Deploy** | Deployment method, Secrets list, initial setup procedure | Public apps only |
| **Development** | Local development steps, test execution, type check commands, etc. | ○ |
| **Directory Structure** | Tree format. Comments on key files | Optional |

### H1 + Badge

```markdown
# Project Name

[![CI](https://github.com/{owner}/{repo}/actions/workflows/ci.yml/badge.svg)](...)
[![Deploy](https://github.com/{owner}/{repo}/actions/workflows/deploy.yml/badge.svg)](...)

1–2 line overview.
```

Deploy badge only for repos with auto-deployment.

### Quick Start

If it runs with Docker, write the Docker-only steps first. Individual language runtime installation goes in the Local Development section.

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

## 3. JUDGE.md Integration

During development, record the criteria for technology selections in `JUDGE.md` (why that technology/architecture was chosen). This is not an instruction file for AI — it's the user's work product.

At publication, integrate `JUDGE.md` content into the README's Design Decisions section and the Tech Stack Reason column.

- `JUDGE.md` … Decision log during development (ADR-like). Whether to keep it in the repo is optional
- README … Integrated selection rationale. Organized for public consumption

> AI premise: "If `JUDGE.md` exists, reflect its decision criteria into the README's selection rationale." AI does not fabricate decision criteria.

---

## 4. Diagrams

Architecture diagrams and data flows are written in Mermaid. Embedded inline in the README and rendered on GitHub.

When using images, place them in `src/` or `docs/` and reference with relative paths. Do not depend on external hosting (imgur, etc.).
