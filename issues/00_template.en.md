## {Title}
id: {00}
branch-slug: {slug}
github_issue:
status: draft
type: {cleanup|fix|feat}
target: {file paths}
description: {what to do}
verification: {static checks the AI Agent should run before submitting}
---
## Issue Creation Rules
### Fields
- `id`: 2-digit sequential number. Derived issues use `08a`, `08b` format (close original and create new)
- `target`: List all files to be modified or newly created. Mark new files with (new)
- `description`: Purpose and overview only. Implementation details go in the section below
- `verification`: Static checks the AI Agent runs before submitting. e.g., when changing a lib, list and verify all affected callers are updated. If none exist, write `visual inspection` rather than omitting
### Lifecycle
- `status: draft` → Under design
- `status: open`  → Available for selection via `issue()`
- `status: close` → Completed (updated by `issue-finish`)
If verification reveals problems, close the issue and create a new one as `{id}a`.
Do not reopen the original issue or send prompts directly to the AI Agent session.
### Granularity
- Size each issue so the AI Agent can complete it in a single session
- Target no more than ~7 files
- If verification requires 2+ distinct methods, consider splitting
  - e.g., server execution check AND browser visual check → separate issues
### Splitting Criteria
- Backend and frontend are separate PRs by default
- If there is a sequential dependency ("build frontend after seeing backend results"), always split
- If items on the same layer can be tested/verified independently, they can stay in one issue
### Detail Section
- Specs that don't fit in `description` go below the `---` separator
- Use headings per file
- If implementation order matters, note it at the end
