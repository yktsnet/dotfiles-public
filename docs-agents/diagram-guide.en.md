[🇯🇵 日本語](diagram-guide.md) | [🇬🇧 English](diagram-guide.en.md)

# Diagram Guide

A guide for authoring Mermaid diagrams. It applies to every diagram rendered on GitHub — READMEs, technical articles, explanatory documents.

The premise of this guide is that **GitHub scales a ```` ```mermaid ```` fence down to the body column width (roughly 768px)**. Diagrams are committed as fences, never baked into SVG (baking loses theme following and diff viewing). A diagram's width therefore *is* its font size.

The goal of this guide is not to produce pretty diagrams. It is to reach a state where **only what cannot be conveyed without a diagram gets drawn, at a size that can actually be read**.

---

## 0. The order to go through before drawing

```
Write it as a bulleted list → if that suffices, no diagram (most cases die here)
        ↓
Decide the subject (branching / boundaries / contrast — which one to show)
        ↓
Decide the direction (TD by default)
        ↓
Assign types to shapes and line styles
        ↓
Count the width
```

**Killing the diagram at step 1 is the highest-leverage judgment in this guide.** Every technique after it merely raises the quality of a diagram already decided on.

---

## 1. To draw or not to draw

**If there is no branching, no failure path, no grouping across a boundary, and no contrast, do not make a diagram.**

Processing that simply happens in order reads faster as a numbered list. Turning `A → B → C → D` into a diagram gives the arrows no information beyond "happens next."

A diagram is justified only when it has one of the following.

| Subject | Why only a diagram can express it |
|---|---|
| **Branching** | A condition splits processing and then rejoins it. In prose the whole shape stays invisible until you have read to the end of each branch |
| **Failure paths** | Retry loops, multiple terminal states. Control flow does not map onto linear prose |
| **Boundaries** | Placement across device, network, or trust boundaries. Only a subgraph expresses it |
| **Contrast** | Before/after, the intended shape versus the current one. The juxtaposition itself is the claim |

**"The big picture" is not a subject.** Attempting to draw the big picture always yields either a branchless straight line or a scattered diagram with mixed abstraction levels.

If the big picture itself is what is needed, present it as a **directory listing or a component table**, not a diagram. If it truly must be a diagram, split it by subject per §5 below.

### Where to put it instead when you don't draw

When you drop a diagram, replace it with the form that fits its content. "Dropping the diagram" and "dropping the information" are different things.

| What the diagram held | Replace with |
|---|---|
| An enumeration of steps that happen in order | Numbered list |
| A mapping of names to roles or stages (script name → phase, etc.) | Table |
| A single-step transformation | One sentence |

### Check that the subject hasn't been flattened

Once you decide to draw, check whether **the most interesting judgment in the repo has been flattened into a single node**. If it has, the diagram's subject is wrong.

Expanding that one node is the diagram that should have been drawn; the surrounding pipeline belongs in the body text.

---

## 2. Width — vertical is free, horizontal is billed

Growth downward only costs a scroll; the font size does not change. Growth sideways is scaled down by exactly that much, until it cannot be read.

| Rule | Reason |
|---|---|
| Default to `TD`. Use `LR` only when the chain is 4 nodes or fewer | `LR` width ∝ chain length; `TD` width ∝ number of branches. A branchless sequence is always narrower in `TD` |
| Keep edge labels minimal. No API enumerations, arguments, or conditional expressions | They add width without adding nodes — the worst information-per-unit-width in the diagram |
| Keep node labels to roughly 12 full-width characters. Details go in the body text below the diagram | A long label widens that entire rank |
| At most 2 subgraphs side by side. Three or more, stack them vertically with `TD` | A subgraph eats padding and border width on top of its contents |

The thresholds (4 nodes / ~12 full-width characters / 2 subgraphs) may be tuned in practice. Note that the character count is expressed in **full-width (CJK) characters**; in a Latin-script label the equivalent budget is roughly twice the character count, because width, not glyph count, is what is being constrained. **What must not move is the premise that width is font size.**

### How to count width

Estimate without rendering. **(Number of nodes in the widest rank × the label length on that row) + the sum of edge label lengths** approximates the width. For `LR` the widest rank is the whole chain; for `TD` it is the widest branching stage.

The order in which to cut: **edge labels → node labels → change of direction → splitting the diagram**.

---

## 3. Put information into shapes and line styles

Node shapes and line kinds **add a dimension of information at zero width cost**. A diagram where every node is the same rectangle and every edge the same arrow has thrown that away.

### Node shapes

| Notation | Type |
|---|---|
| `([ ])` | Actor (a person, an external caller) |
| `{{ }}` | Service, transformer |
| `[( )]` | Data store |
| `{ }` | Decision, branch point |
| `[/ /]` | External input, file |
| `[ ]` | Anything else |

### Line styles

| Notation | Meaning |
|---|---|
| `-->` solid | Local, within the same process |
| `-.->` dotted | Across the network, asynchronous |
| `==>` thick | Physical human action, primary path |

The assignment is not fixed, but **it must be consistent within a single diagram**. An inconsistent distinction is noise rather than information.

Emoji work as zero-width visual anchors. Place them **only where the kind of thing changes** — actors, external services.

### Notation

- Use `<br/>` for line breaks, not `\n` (newer Mermaid has changed how `\n` is treated)
- Quote labels containing symbols as `["..."]`

---

## 4. Don't mix abstraction levels

Keep the layer of what nodes refer to uniform within one diagram. **Do not place concepts (routes, phases, layers) and concrete things (processes, files, services) on the same plane.**

The typical mixture is naming a subgraph with a concept like "Route A / Route B" and then lining up concrete middleware or files outside it. In that case, drop the subgraph and **let the structure itself (joins and splits) do the talking** — it comes out narrower and more readable.

---

## 5. Split or merge

**One diagram, one subject.** Whether to split is decided by the number of subjects, never by the size of the diagram. "Too big, so split it" and "too small, so add to it" both lead the judgment astray.

Only these three axes justify a split. Diagrams split for any other reason usually multiplied while their subject stayed vague.

| Axis | Example |
|---|---|
| **Time** | Build time / run time, setup / steady-state operation |
| **Normal / abnormal** | The primary path / halt, retry, and forced-termination paths |
| **Before / after** | Structure before migration / after migration |

### Check this before merging

**First ask whether each one holds a subject on its own.** A diagram that does not is not a merge candidate — it is a **delete** candidate. Absorbing a subjectless diagram into another one dilutes the absorbing diagram's subject too.

### Rules once split

- Give each diagram **a heading or a sentence stating its subject**. Never place two diagrams unexplained under the same heading (the reader cannot tell which is which)
- When the same node appears across diagrams, keep its label exactly identical
- State the splitting axis itself in the body text ("the following is the normal path; the halt path is in the next diagram")

## 6. Where it applies

- The Architecture section of a README … delegated to this guide from `readme-guide.md` §8
- Technical articles and explanatory documents … apply this guide when writing them

The procedure for actually drawing, and for fixing existing diagrams, lives in the `mermaid-diagram` Skill. This guide holds only the criteria, never the procedure.
