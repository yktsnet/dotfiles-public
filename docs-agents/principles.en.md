[🇯🇵 日本語](principles.md) | [🇬🇧 English](principles.en.md)

# Principles — Design Principles for AI Agent Operations

A development system that does not assume a human who stays alert. Presented as five stages, in the order they should be adopted.

Each stage is described by its essence, the mechanism that supports it, and the condition for moving on.

| This document covers | This document does not cover |
|---|---|
| Why this order. The essence, mechanism, and completion condition of each stage | Procedures, setting values, checklists (the individual guides in this directory) |

---

## Terms

### The Three Roles

| Role | Responsibility |
|---|---|
| **user** | Decision maker. Approves phases and guarantees; reviews, merges, deploys |
| **Consultant** | Investigation, design, Issue authoring. Does not implement. Runs in the open chat |
| **Builder** | Implementation and local commits based on an Issue. Runs on a dedicated branch and never touches the remote |

### Phases

The user decides which phase a repository is in and states it in CLAUDE.md.

- **MVP phase** — early stage where direction and structure are still fluid. The Consultant may implement directly. The driving documents are PLAN.md / JUDGE.md.
- **Issue-Driven phase** — direction is settled. Follow the separation of the three roles. The driving documents are the guarantee ledger and the tests.

### Driving Documents

The documents that move development forward during a given period, and that keep being updated.

- **PLAN.md** — the definition of the MVP, its completion conditions, and the work log.
- **JUDGE.md** — the record of technical choices and decisions made during implementation.
- **Ledger** (`docs/guarantees.md`) — a list pairing each guarantee on the public surface with the test that backs it.

### Around Guarantees

- **Guarantee** — behavior that must not break. Written in natural language.
- **Guarantee section** — the section of an Issue stating the guarantees newly declared and the guarantees preserved. Approved by the user.

### Three Relief Routes from the Separation

- **Real-time ops** — incident response that cannot be designed in advance.
- **One-off exception** — an occasion where the user explicitly instructs a direct edit.
- **Lightweight route** — a small diff that touches neither logic nor the ledger.

---

## The Underlying Premise

**Do not assume a human who stays alert.**

Conventions depend on the reader's concentration, and concentration drops with fatigue. A structure whose compliance depends on a person's condition should not be built in the first place. Prohibitions go into mechanisms rather than documents; indexes are generated rather than hand-written; CI runs the same checks as local verification, doubled. Writing something down to enforce it is the last resort, not the first.

This premise shows most plainly in the definition of a test, which is specified as "a device by which the Builder notices, on its own, that it broke something" (Step 4). Rather than a human catching it through vigilance, the one who broke it is given a path to notice before submitting.

---

## Order of Adoption

1. Decide the type before building
2. Put prohibitions in mechanisms, not documents
3. Place knowledge by the moment it is read
4. Approve the guarantees to be kept, first
5. Separate who decides from who builds

The order has dependencies. Until the type is settled, what to block is not settled. Adding knowledge while nothing is blocked only raises the speed of accidents. Without a settled place for knowledge, there is no ground on which to write guarantees. And separating the roles before the guarantees are settled sends the Builder off without knowing what must not break.

**The minimal configuration is 1–3.** These three stages hold regardless of publication status or team size. If an Agent is running, they are required. Stages 4–5 are added once there is something published, or once work runs in parallel across multiple people or multiple sessions.

---

## Step 1 — Decide the Type Before Building

### Essence

Before starting to build, decide which type it is. Every rule that follows is derived from the type: what to block, what counts as verification, what to write in the README, how far to test. If the type is not settled, nothing else can be.

The rules themselves also avoid fixed lists of required items. For each type only a **floor** is defined — the perspectives that must always be satisfied — and the structure above that floor is decided each time. The work becomes judgment rather than filling in a template.

The axis of judgment differs by target.

| Target | Axis of judgment |
|---|---|
| Repository | Category (config / logic / web / tool) × publication status |
| README | Is it to be used, or to be read? If read, is the evidence code or numbers? |
| Module | Does it get pulled into the user's runtime? If not, is what you hand over a machine or a practice? |
| Diagram | Is there a branch, a failure path, a boundary, or a contrast? |

Litmus tests are placed at the boundaries that split most easily. "If every resulting number were removed, would the value remain?" "If every parameter were pushed out to external injection, would a working machine remain?" A question whose answer changes with the judge cannot serve as a criterion.

And the first judgment always includes the option of not doing it. Draw the diagram? Write the comment? File the Issue? Dropping things is what pays off most.

### Mechanism

Judgments are not shared verbally; they are fixed in the place where they will be read. The repository category and the verification methods it determines go into CLAUDE.md. The README's type goes into the structure of the README itself. The phase goes into CLAUDE.md as well.

The phase alone is decided by the user; the Consultant neither judges nor changes it. Moving the judgment outside of any single persona keeps it from swaying with the convenience of the moment.

### Completion Condition

The repository category, verification methods, and phase are written in CLAUDE.md. Subsequent decisions can be made by referring to that text.

### References

[repo-guide.en.md](repo-guide.en.md) / [harness-guide.en.md](harness-guide.en.md) §1 / [readme-guide.en.md](readme-guide.en.md) §1 / [module-guide.en.md](module-guide.en.md) §1 / [diagram-guide.en.md](diagram-guide.en.md) §1

---

## Step 2 — Put Prohibitions in Mechanisms, Not Documents

### Essence

A prohibition written in a document is not obeyed. Readers get tired, and Agents skim long instructions. So prohibitions go into `settings.json` deny rules and hooks rather than CLAUDE.md. The same content obeyed at an order-of-magnitude different rate, purely because of where it lives.

That said, deny alone is enough if all you want is a wall. The gain from a hook is that it can steer toward the correct path at the same moment it refuses. An Agent that is refused will try something else, and the refusal message can specify what that something else should be. **A block is not a negation but a switch.**

### Mechanism

deny only matches string prefixes. When the thing to prohibit is an action rather than a string, a PreToolUse hook interprets the command and decides. Strip quoted contents first, restrict the match to command position, and absorb `sudo` / `env` / path-qualified invocations.

Refusal messages carry both the reason and the alternative procedure. Where possible, assemble the correct edit target mechanically and return it.

attribution is left empty on the position that an Agent is a tool, not a co-author. Mixing non-human names into commit history also degrades the readability of blame.

Generation and blocking are separate measures, and both are needed. Even if an index is generated automatically, a write to the wrong location will never appear in it.

### Completion Condition

deny rules and hooks are in place, and refusal messages return both a reason and an alternative procedure. Not a single prohibition remains written in CLAUDE.md.

### References

[harness-guide.en.md](harness-guide.en.md) §3

---

## Step 3 — Place Knowledge by the Moment It Is Read

### Essence

Where knowledge goes is determined less by what it says than by when it is read. And jurisdictions must not overlap.

### Mechanism

| Moment it is read | Where it goes |
|---|---|
| A short rule that always applies | One line in CLAUDE.md |
| Anything you can state as "when you do X" | A skill (its description becomes a declaration of the trigger) |
| Shared dictionaries and guides pointed to from rules | A separate directory, referenced by absolute path |
| Unorganized thinking | Outside the harness. Never loaded automatically |

Listing the triggers in a skill's description turns tacit knowledge into a declaration. The trigger for migration is the moment you notice "I've handed over this document by hand again"; there is no bulk migration.

Each guide carries a jurisdiction table at the top and does not write about another guide's territory. The urge to quote is a sign that the source needs fixing.

Documents whose readers are not only human are written with English headings and Japanese body text: the structure reads internationally while the precision of the prose is kept in the native language. Where a document has an English edition, anything split out of it is created as a pair. No asymmetry where only one side folds the content inline.

### Review Sweep

As a consequence of separating the places, rule files keep multiplying. But no mechanism for detecting contradictions among rules exists inside the rules themselves. The only option is to look from outside, periodically.

The sweep goes through an index and reads closely only the files changed since the last recorded run. A design without an index re-reads every target on every run, and the cost accumulates in proportion to the number of targets. Exclusion lists are not maintained; targets are determined by criteria that can be separated mechanically. Findings are approved one at a time.

### Completion Condition

When a new rule is added, its location is determined uniquely by the moment it is loaded. Procedures are not accumulating in CLAUDE.md. The sweep runs on a schedule, and the index records the point in time of the last run.

### References

[harness-guide.en.md](harness-guide.en.md) §4 / §4.6 / [readme-guide.en.md](readme-guide.en.md) §6

---

## Step 4 — Approve the Guarantees to Be Kept, First

### Essence

Tests are what secures changeability. They are written not to prove quality but to create a state in which things can be changed safely. Code whose breakage goes unnoticed is code nobody touches for as long as it happens to work.

On that basis, it is the Builder who writes the tests. The human's job shifts to approving the guarantees. If TDD is the discipline of writing tests first, GDD (Guarantee-Driven Development) is the discipline of approving first.

The test itself is not the source of truth. What is authoritative is an approved guarantee written down in executable form.

### Mechanism

The user reads the Issue's guarantee section, trims, adds, corrects, and then sets `status: open`. `open` means approved, and the Builder never touches `status:`. A change with no accompanying tests states `保証: なし（理由）` explicitly.

The ledger carries only the contract surface; tests of internal implementation stay off it. Depth is decided by risk: thick on public APIs, thin on internal implementation, and appearance is routed to the user's manual verification.

### Handover of the Driving Documents

The driving documents of the MVP phase are PLAN.md and JUDGE.md. PLAN.md holds what counts as done, JUDGE.md holds why the implementation is what it is, and the Agent implements while updating both. But these two are scaffolding, and permanence is not asked of them. At publication they are raised into the README, and **once raised, they are deleted**. If the full text of a decision is needed, it moves into `docs/`; no dual maintenance is left between the README and an original. The history is in git.

The moment the ledger enters official operation is the handover point of the driving documents. Once the behavior that must not break is fixed in the ledger, PLAN.md has finished its job. The phase transition *is* this handover; changing the declaration alone moves nothing real.

### Doubling the Verification

Approved guarantees are run in two places: the Builder's local environment and CI. CI does not add new checks; it repeats the same ones as local verification. The goal is not coverage but catching what slips through when the Builder forgets to run them. If the two places diverge in content, one of them will inevitably stop being trusted.

A repository where local verification is enough carries no CI. It comes down to whether it holds anything visible from outside.

### Completion Condition

The ledger is promoted to official operation and is reachable from the README. PLAN.md / JUDGE.md have been raised into the README and `docs/`, and deleted. At this point the phase moves up to Issue-Driven. Promoting the ledger, discarding the driving documents, and changing the phase are bundled as a single event.

### References

[test-policy.en.md](test-policy.en.md) / [issue-driven-workflow.en.md](issue-driven-workflow.en.md) (guarantee section, phase transition) / [readme-guide.en.md](readme-guide.en.md) §7 / [cicd-guide.en.md](cicd-guide.en.md) §2

---

## Step 5 — Separate Who Decides from Who Builds

### Essence

The three roles are separated to protect decisions from the convenience of implementation. Deciding and executing within the same stretch of time lets the decision get dragged along by the execution, until it can no longer be examined.

### Mechanism

The Consultant writes the Issue and stops. The Builder implements in a worktree, stops at a local commit, and never touches the remote. The user reviews, and a dedicated command handles push through PR creation, merge, and recording in one go. What lands on the remote is only what has been reviewed locally.

The local Issue file is the single source of truth; the GitHub Issue is a mirror kept for the record. When a problem surfaces, the original Issue is not reopened — a derived Issue is filed instead, so that the record is never overwritten.

Deployment removes human hands the same way. It pushes out automatically on a passing CI run, with no manual operation in between. Judgment is required up to the merge; beyond that there is no reason for a person to stand in the path.

The rigidity is relieved by the three routes (see Terms). If any of them becomes routine, move the phase itself back.

### Completion Condition

From Issue to publication, human judgment has converged onto the user's review and approval alone.

### References

[issue-driven-workflow.en.md](issue-driven-workflow.en.md) / [cicd-guide.en.md](cicd-guide.en.md)

---

## Scope of Application

The phase concept applies only to repositories on the publishing pipeline. Personal infrastructure and ops repositories are excluded and default to direct editing. Steps 1–3, however, hold regardless of publication status. Judging the type, blocking, and placing knowledge are required for as long as an Agent is running.
