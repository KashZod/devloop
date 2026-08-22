---
name: plan
description: "Structured planning process: explores the code, decomposes a feature into independently-testable TDD chunks with a dependency graph, writes a JSON tracker, and gates the plan through an independent review-plan agent before any code is written. Use after /spec (or on its own) and before /implement, to decide HOW to build it."
argument-hint: "[description of feature, fix, or refactor]"
effort: high
---

# Planning Process (Chunk Decomposition + Plan Review)

Plan the following before implementation begins: $ARGUMENTS

Planning decides HOW to build what the spec described. Fixing a wrong
abstraction in a plan costs minutes; fixing it in code costs hours. So
this skill produces a reviewable plan, a JSON tracker of independently
testable chunks, and runs it through an independent plan-review gate
before any code is written. When the gate passes, hand off to
`/implement`.

## Mapping to the Explore -> Plan -> Code Loop

| Workflow Phase | Plan Phase | What Happens |
|---|---|---|
| **Explore** | Phase 1: Analysis | Read files, trace data flow, check standards |
| **Plan** | Phase 2: Decompose | Chunk breakdown, dependency graph |
| **Plan** | Phase 3: Tracker | Write the JSON tracker (source of truth) |
| **Plan** | Phase 4: Present | Present the plan, get explicit approval |
| **Plan** | Phase 5: Review Gate | `review-plan` agent gates the plan |

Code and Commit happen in the companion `/implement` skill, which reads
the tracker this skill produces.

## When to Use This Process

| Scope | Approach |
|---|---|
| Trivial (typo, rename, version bump) | Don't plan -- just do it directly |
| Small (single-file logic, simple bug fix) | Small feature shortcut (1-chunk tracker) |
| Medium+ (multi-file, unfamiliar code) | Full process |
| Large (cross-cutting, multi-session) | Full process, thorough decomposition |

**Small feature shortcut:** For single-file or few-file changes with no
new domain logic, collapse Phase 2 to a single chunk and keep Phase 4
(present) light, but still write the tracker (Phase 3) and run the
Phase 5 review gate. Small features carry the same regression risk, so
the gate is not optional. Use a 1-chunk tracker (see
[tracker-schema.md](references/tracker-schema.md) §Single-Chunk Features).

## Supporting Files

Load these on demand, not all upfront:

| File | When to Load |
|---|---|
| [chunk-template.md](references/chunk-template.md) | Phase 2, when decomposing into chunks (skip for small features) |
| [tracker-schema.md](references/tracker-schema.md) | Phase 3, when creating the tracker (all features) |
| [quality-checklist.md](../implement/references/quality-checklist.md) | Phase 5, only as the fallback self-check if the review-plan agent is unavailable |

## Process Overview

```text
Phase 1: Analysis
Phase 2: Decompose (chunks + dependency graph)
Phase 3: Tracker (JSON, source of truth)
Phase 4: Present Plan (explicit approval)
Phase 5: Plan Review Gate (review-plan agent, blocks handoff)
```

Each phase must complete before the next begins. The tracker artifact
from Phase 3 triggers the review gate in Phase 5.

---

## Phase 1: Analysis

### 1.1 Understand the Request

- Read the user's request carefully
- Identify: new feature, enhancement, bug fix, refactor, or test
- Check the spec directory (the spec-directory setting in
  `.devloop/config.md`, default `docs/specs/`) for an existing spec
  file matching the feature. If found, use it as
  primary input, its user stories, acceptance criteria, and edge cases
  become the basis for chunk decomposition. (Specs are produced by the
  companion `/spec` skill, which writes to the same configurable
  location.) Note its path, you record it as the tracker's `spec_doc`
  field in Phase 3 so `/implement` and the review agents bind to this
  exact spec instead of globbing the spec directory.
- Ask clarifying questions if the scope is ambiguous

### 1.2 Explore Current Code

- Read the files that will be affected
- Trace the data flow through the application layers
- Identify existing patterns, utilities, abstractions to reuse
- Check for existing test coverage in the affected area

**Context tip:** If your harness provides a subagent or parallel-tool
capability, use it for broad exploration across unfamiliar code, workers
run in a separate context and report back summaries, keeping your main
context clean. If it does not, explore sequentially in-context, that is
the default and is correct.

### 1.3 Check Industry Standards

- Research platform-specific handling and conventions
- Check official documentation for frameworks in use
- Check changelogs and migration guides for your dependency
  versions, APIs may behave differently across releases
- Identify relevant specs (RFCs, W3C, language specs)
- Note platform-specific quirks and edge cases

### 1.4 Check Project Architecture Patterns

Load the project's engineering config (build/test/lint commands,
architecture rules, standards, and blindspots, the same context
`/implement` uses). Resolve it as `.devloop/config.md` in the project
root. Verify the change aligns with it. If it's absent or only template
placeholders (`YOUR_*_HERE`), proceed without it:
infer the test/build commands from the project (build files, CI config,
`Makefile`), confirm them with the user before recording them in the
tracker, note the miss in the tracker, and suggest creating one.

Common patterns to verify:

- **Layered architecture** respected (UI -> Domain -> Data)
- **Repository/service boundaries** not bypassed
- **Test double strategy** matches project convention (fakes/mocks/stubs)
- **Dependency injection** bindings exist for new dependencies
- **Type safety** enforced where expected (sealed types, enums, branded)

### 1.5 Verify Signatures and Dependencies

- Check constructor parameters, return types, method signatures
- Verify DI bindings exist for new dependencies
- Cross-reference project guidelines and the engineering config
- Run these checks in parallel if your harness supports parallel tool
  calls, otherwise sequentially

---

## Phase 2: Decompose

### 2.1 Chunk Decomposition

Break the feature into implementation chunks.
See [chunk-template.md](references/chunk-template.md).

Rules:

- Prefer the fewest chunks that keep each independently testable,
  over-chunking adds handoffs without safety (see Lessons Learned #4)
- Each chunk is independently testable (or marked BATCH)
- Chunks list files to create and modify
- Chunks specify test files and TDD instructions
- Chunks declare dependencies on other chunks
- Optional `notes` field captures pattern hints / pitfalls a resuming
  session can't infer from `name` + files + `tdd`

### 2.2 Dependency Graph

Organize chunks into layers:

```text
Layer 1 (no deps):     Chunks that can start immediately
Layer 2 (deps on L1):  Chunks needing Layer 1 complete
Layer N (final):       Regression + quality verification
```

---

## Phase 3: Tracker

### 3.1 Check for an Existing Tracker

Before writing, check the tracker location (the tracker-directory
setting in `.devloop/config.md`, default `.devloop/trackers/`)
for an existing `impl-tracker-<feature>.json`. If one exists,
you are revisiting or re-gating a plan (an `/implement` convergence round
routed back here, or a resumed session), not starting fresh:

- **Preserve** every chunk already at `status: complete`, and any
  `pending` chunks `/implement` appended during convergence. Do not reset
  their status and do not drop them, regenerating from scratch would make
  `/implement` rebuild finished work and lose the corrective chunks a
  convergence round just added.
- **Merge** the new or revised plan into it: add or edit chunks, update
  `depends_on`, keep the completed work intact.
- **Preserve the top-level fields** on the existing tracker
  (`plan_review`, `convergence_rounds`, `spec_doc`, `issue`): a merge
  edits chunks, it does not re-serialize a fresh object with the schema
  defaults. Resetting `convergence_rounds` to `0` here would defeat the
  bounded-loop cap it exists to make crash-safe.
- If the old chunks no longer apply, confirm with the user before
  discarding completed chunks, the same way `/spec` Phase 1.5 asks
  "update or start fresh?"

Only when no tracker exists do you create one from scratch in 3.2.

### 3.2 Create or Update the JSON Tracker

Create (or update per 3.1) a tracker file following the schema in
[tracker-schema.md](references/tracker-schema.md). Write it to the
tracker directory (the tracker-directory setting in `.devloop/config.md`,
default `.devloop/trackers/`); create the directory if it doesn't exist.
The tracker is always present, even for single-chunk features
(see §Single-Chunk Features in the schema). Record the spec path noted in
Phase 1.1 in the `spec_doc` field. Create the tracker with
`plan_review: "PENDING"` (never `"PASS"`): the
gate has not run yet, and pre-stamping `PASS` would let a crash before
Phase 5 leave `/implement` free to build an ungated plan. The Phase 5
gate overwrites `plan_review` with the real verdict.

The tracker is the single source of truth for progress and the handoff
to `/implement`.

**Why a file?** The tracker is a file-based artifact that survives
context resets; in-context memory does not, so the tracker is what lets
any session, current or future, pick up exactly where work stopped. It
carries the acceptance criteria, files, and TDD instructions `/implement`
needs, so planning and implementation can run in separate sessions.

New chunks start at `status: pending` (planning writes no code); chunks
carried over from an existing tracker keep their current status. Record
the acceptance criteria per chunk so `/implement` and the review agents
have a concrete checklist.

Ensure `depends_on` forms a directed acyclic graph: every referenced id
exists and no chunk depends (directly or transitively) on itself.
`/implement` validates this before building and hard-stops on a cycle or
dangling id, so a bad graph caught here saves a stall there.

---

## Phase 4: Present Plan

Before handing off, present the plan and get explicit approval.
Planning is read-only, do not modify code.

Present:

- Context: why this change is needed
- Acceptance criteria
- Chunk breakdown with dependency graph
- Files affected
- Quality verification approach

Wait for explicit approval before proceeding to the review gate. If your
harness has a dedicated plan/approval mode or a structured-choice prompt,
use it; otherwise present the plan as a message and ask the user to
approve or request changes. Incorporate requested changes and re-present
until approved.

---

## Phase 5: Plan Review Gate

**GATE: The tracker artifact from Phase 3 triggers this review.
Do not hand off to /implement until review completes.**

The tracker file is the review input. Spawn the `review-plan`
agent as a subagent so the reviewer operates in a fresh context
without author bias:

```
Use the review-plan agent to review [path to tracker]
```

The agent evaluates 8 criteria against the plan: completeness (including
spec -> plan -> tracker traceability), correctness, functional gaps,
standards, regression risk, robustness, architectural gaps, and TDD
quality. The first seven share the concern vocabulary in
[quality-checklist.md](../implement/references/quality-checklist.md);
the eighth (TDD quality) is plan-specific.

**FAIL:** write `plan_review: "FAIL"` to the tracker first (so a crash
cannot leave a stale `"PENDING"`/`"PASS"` that lets `/implement` build an
ungated plan), then update the plan and re-run review-plan. **Bounded:**
if the gate FAILs twice on the same criterion, or after two full
update/re-run cycles, stop and surface the plan to the user for a
decision rather than looping, the same cap `/implement` convergence
applies.
**PASS-WITH-WARNINGS:** record the verdict and hand off with a note.
**PASS:** hand off to `/implement`.
**No subagent capability** (the harness cannot spawn agents at all, not
just a failed spawn) **or agent failure** (timeout, error): fall back to
an in-context self-check against
[quality-checklist.md](../implement/references/quality-checklist.md) and
proceed. Note in the tracker that the gate ran without isolation, this
forfeits the author-evaluator separation the agent exists to provide.

Record the verdict in the tracker's top-level `plan_review` field
(e.g., `"plan_review": "PASS"`) so the gate survives session resets.
`/implement` refuses to start the TDD cycle unless `plan_review` is
`PASS` or `PASS-WITH-WARNINGS`.

### Handoff

Output to the user:

- Tracker file path
- Number of chunks and the dependency layers
- Acceptance criteria count
- Plan review verdict (and any warnings)

```
Next: /implement <feature> (tracker: .devloop/trackers/impl-tracker-<feature>.json)
```

If the review has warnings, note them:
"The plan has N warnings, review them before starting implementation."

**Non-code projects:** If the work covers content, configuration, or
documentation (no executable code), the chunk/tracker model still
applies, treat each chunk as a content unit with validation criteria
instead of tests, and suggest a structured build order.

---

## Lessons Learned (Apply Every Time)

1. **The plan is the cheapest place to fix a mistake** -
   A wrong abstraction caught in review costs minutes; the same mistake
   caught after coding costs hours. Spend the effort here.
2. **Every criterion needs a chunk; every chunk needs a criterion** -
   Traceability runs both ways. A criterion with no chunk is a gap; a
   chunk with no criterion is scope creep. The plan-review gate checks
   both directions.
3. **Batch interconnected type changes** -
   If changing a shared type's field forces consumers to change to
   compile, put them in one BATCH chunk, don't split what won't compile
   independently.
4. **Don't over-chunk** -
   Prefer the fewest independently-testable chunks. Each extra chunk is
   a handoff, not safety. Ten chunks for a three-file change is a smell.
5. **The tracker is the handoff** -
   `name` + `files_create`/`files_modify` + `tdd` + `acceptance_criteria`
   + any `notes` must let a fresh `/implement` session build the chunk
   without re-deriving the plan. Write it so a stranger could pick it up.
6. **Plan HOW, not WHAT** -
   Acceptance criteria come from the spec (WHAT). The plan adds files,
   chunks, dependencies, and test strategy (HOW). If you find yourself
   rewriting the acceptance criteria, the spec was wrong, fix it in
   `/spec`, not here.
7. **Stress-test your scaffolding** -
   Every process step encodes an assumption about model limitations. As
   models improve, re-evaluate whether heavy chunking and frequent
   resets still help. The tracker and the review gate are load-bearing;
   chunk granularity is not. Prefer fewer, larger chunks.

---

## Commit Guidance

Do not commit proactively. Wait for the user to request it.
Refer to `.devloop/config.md` for project-specific commit conventions
(author, message format, trailers).

---

## Session Scope

Planning completes in one session and produces the tracker. To revisit a
plan later, re-run `/plan`, or edit the tracker directly and re-run the
Phase 5 review gate. When resuming implementation, `/implement` reads the
tracker, which is a complete handoff.
