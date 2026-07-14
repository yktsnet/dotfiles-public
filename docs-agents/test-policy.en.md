[🇯🇵 日本語](test-policy.md) | [🇬🇧 English](test-policy.en.md)

# Test Policy

Tests guarantee changeability. They exist so the Builder (AI) notices for itself when it has broken something; they do not assume a human keeps watching.

Guarantees (what must not break) are approved by a human in the Issue's guarantee section; the Builder writes the tests that implement them.

Depth is risk-based: thorough for public APIs and contract surfaces, light for internal implementation, and left to the user's manual verification for UI and appearance.

Fixes ship with a regression test.

External dependencies are received via DI; tests substitute fakes for them (never connect to real services).

Each repository may keep a guarantee ledger for its public surface at `docs/guarantees.md`. It consists of natural-language guarantee bullets paired with a table of corresponding tests (file and test name), and holds the same standing as design-decisions.md (flag it when the implementation drifts from it). Only contract-level guarantees belong there; tests for internal implementation do not. The first version is laid down by a contract-inventory Issue (guarantees extracted from existing tests and approved by the user); after that it tracks updates via the Issue's guarantee section in the same PR.
