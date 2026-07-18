[🇯🇵 日本語](test-policy.md) | [🇬🇧 English](test-policy.en.md)

# Test Policy

Tests guarantee changeability. They exist so the Builder (AI) notices for itself when it has broken something; they do not assume a human keeps watching.

Guarantees (what must not break) are approved by a human in the Issue's guarantee section; the Builder writes the tests that implement them. This division of labor is called **Guarantee-Driven Development (GDD)**. Tests are not the definition of truth; they are executable projections of the approved guarantees. If TDD is the discipline of writing tests first, GDD is the discipline of approving promises first: the human's job shifts from writing tests to approving promises. Repositories in the Issue-driven phase are maintained this way (each repository declares its phase in its CLAUDE.md).

Depth is risk-based: thorough for public APIs and contract surfaces, light for internal implementation, and left to the user's manual verification for UI and appearance.

Fixes ship with a regression test.

External dependencies are received via DI; tests substitute fakes for them (never connect to real services).

Each repository may keep a guarantee ledger for its public surface at `docs/guarantees.md`.

- **Structure**: natural-language guarantee bullets paired with a table of corresponding tests (file and test name). Only contract-level guarantees belong there; tests for internal implementation do not. Drift between the ledger and the implementation is something to flag.
- **Laying it down**: the first version is laid by the `guarantee-audit` skill — for a new repository as part of publish preparation (before the README is written, since the README links to the ledger), for an existing repository as an inventory pass over its tests.
- **Tracking**: after that, the ledger is updated in the same PR as the Issue's guarantee section. Drift between the ledger and the tests is detected by periodic audits with `guarantee-audit`.
- **Reachability**: the ledger should be reachable from the README (link placement follows the readme guide).
- **Gaps section**: records things that should be guaranteed but lack tests, each with its deferral reason; delete the section entirely once empty.
