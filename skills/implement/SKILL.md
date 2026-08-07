---
name: implement
description: "Structured implementation process driven by TDD: explores code, plans with chunk decomposition, writes failing tests first, implements to pass, and runs an 8-point quality checklist. Use after /spec, or when implementing features, fixing bugs, or refactoring with test verification."
argument-hint: "[description of feature, fix, or refactor]"
effort: high
---

# Implementation Process (Test-Driven)

Implement the following using test-driven development: $ARGUMENTS

Tests give Claude a self-verification loop. Instead of producing code
that looks right, write tests first, then implement until they pass, so
correctness is checked by execution rather than by inspection.

## Mapping to Claude Code Workflow

| Claude Code Phase | Implement Phase | What Happens |
|---|---|---|
| **Explore** | Phase 1: Analysis | Read files, trace data flow, check standards |
| **Plan** | Phase 2: Planning | Chunk decomposition, dependency graph, approval |
| **Implement** | Phases 3-5: TDD Cycle | Per-chunk: failing test -> code -> passing test |
| **Commit** | (user-initiated) | Commit when user requests |

## When to Use This Process

| Scope | Approach |
|---|---|
| Trivial (typo, rename, version bump) | Don't use this skill -- just do it directly |
| Small (single-file logic, simple bug fix) | Small feature shortcut (1-chunk tracker) |
| Medium+ (multi-file, unfamiliar code) | Full process |
| Large (cross-cutting, multi-session) | Full process + session resets between chunks |

**Small feature shortcut:** For single-file or few-file changes
with no new domain logic, collapse to: Analysis -> Pre-Test (verify
existing coverage) -> Implement -> Post-Test (regression) -> Quality
Verification. Use a 1-chunk tracker (see
[tracker-schema.md](references/tracker-schema.md) §Single-Chunk
Features). Only Plan Mode (2.4) and chunk decomposition (2.1-2.2)
collapse, Phase 2.5 (review-plan) and Phase 6 (review-impl +
red-team) still run; small features carry the same regression risk.

## Supporting Files

Load these on demand, not all upfront:

| File | When to Load |
|---|---|
| [chunk-template.md](references/chunk-template.md) | Phase 2, when decomposing into chunks (skip for small features) |
| [tracker-schema.md](references/tracker-schema.md) | Phase 2.3, when creating the tracker (all features) |
| [quality-checklist.md](references/quality-checklist.md) | Phase 2.5 (plan review) and Phase 6 (final verification, or agent-failure fallback) |

## Process Overview

```text
Phase 1: Analysis
Phase 2: Planning
  └─ 2.5: Plan Review Gate (review-plan agent, blocks Phase 3)
Phase 3: Pre-Test (per chunk)
Phase 4: Implementation (per chunk)
Phase 5: Post-Test (per chunk)
Phase 6: Quality Verification
  └─ Gate: review-impl + red-team agents (parallel, blocks completion)
```

Each phase must complete before the next begins.
For multi-chunk features, Phases 3-5 repeat per chunk.
Gates are artifact-triggered: the tracker file triggers review-plan
(2.5), all chunks complete triggers review-impl + red-team (6).

---

## Phase 1: Analysis

### 1.1 Understand the Request

- Read the user's request carefully
- Identify: new feature, enhancement, bug fix, refactor, or test
- Check the spec directory (from `PROJECT.md`, default `docs/specs/`)
  for an existing spec file matching the feature. If found, use it as
  primary input, user stories, acceptance criteria, and edge cases
  become the basis for chunk decomposition in Phase 2. (Specs are
  produced by the companion `/spec` skill in this plugin, which writes
  to the same configurable location.)
- Ask clarifying questions if the scope is ambiguous

### 1.2 Explore Current Code

- Read the files that will be affected
- Trace the data flow through the application layers
- Identify existing patterns, utilities, abstractions to reuse
- Check for existing test coverage in the affected area

**Context tip:** For broad exploration across unfamiliar code, use
subagents to investigate. They run in a separate context and report
back summaries, keeping your main context clean for implementation.

### 1.3 Check Industry Standards

- Research platform-specific handling and conventions
- Check official documentation for frameworks in use
- Check changelogs and migration guides for your dependency
  versions, APIs may behave differently across releases
- Identify relevant specs (RFCs, W3C, language specs)
- Note platform-specific quirks and edge cases

### 1.4 Check Project Architecture Patterns

Load `PROJECT.md` for build/test/lint commands, architecture rules,
standards, and blindspots, and verify the change aligns with them. If it's
absent or only template placeholders (`YOUR_*_HERE`), proceed without it:
infer the test/build commands from the project (build files, CI config,
`Makefile`), confirm them with the user before relying on them in Phase 3+,
note the miss in the tracker, and suggest creating one.

Common patterns to verify:

- **Layered architecture** respected (UI -> Domain -> Data)
- **Repository/service boundaries** not bypassed
- **Test double strategy** matches project convention (fakes/mocks/stubs)
- **Dependency injection** bindings exist for new dependencies
- **Type safety** enforced where expected (sealed types, enums, branded)

### 1.5 Verify Signatures and Dependencies

- Check constructor parameters, return types, method signatures
- Verify DI bindings exist for new dependencies
- Cross-reference project guidelines and `PROJECT.md`
- Run checks in parallel where possible

---

## Phase 2: Planning

### 2.1 Chunk Decomposition

Break the feature into implementation chunks.
See [chunk-template.md](references/chunk-template.md).

Rules:

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

### 2.3 Create JSON Tracker

Create a tracker file following the schema in
[tracker-schema.md](references/tracker-schema.md).
The tracker is always created, even for single-chunk features
(see §Single-Chunk Features in the schema).

The tracker is the single source of truth for progress.
Always update status to `in_progress` BEFORE starting a chunk.

**Why always?** The tracker is a file-based artifact that survives
context resets. Relying on in-context memory loses state when
sessions end or context is compacted. The tracker ensures any
session, current or future, can pick up exactly where work
stopped.

### 2.4 Present Plan to User

Enter Plan Mode (`Shift+Tab` twice from Normal Mode) and present:

- Context: why this change is needed
- Acceptance criteria
- Chunk breakdown with dependency graph
- Files affected
- Quality verification approach

Press `Ctrl+G` to open the plan in your text editor for direct
editing before proceeding.

Get user approval, then switch back to Normal Mode (`Shift+Tab`)
before proceeding to implementation.

### 2.5 Plan Review Gate

**GATE: The tracker artifact from 2.3 triggers this review.
Do not proceed to Phase 3 until review completes.**

The tracker file is the review input. Spawn the `review-plan`
agent as a subagent so the reviewer operates in a fresh context
without author bias:

```
Use the review-plan agent to review [path to tracker]
```

The agent evaluates 8 criteria against the plan: completeness,
correctness, functional gaps, standards, regression risk,
robustness, architectural gaps, and TDD quality.

**FAIL:** update the plan and re-run review-plan.
**PASS-WITH-WARNINGS:** proceed with a note.
**PASS:** proceed to Phase 3.
**Agent failure** (timeout, error): fall back to self-check against
[quality-checklist.md](references/quality-checklist.md) and proceed.

Record the verdict in the tracker's top-level `plan_review` field
(e.g., `"plan_review": "PASS"`) so the gate survives session resets.

---

## Phase 3: Pre-Test (per chunk)

### 3.1 Determine Test Strategy

| Chunk Type | Test Strategy |
|---|---|
| Data class with logic | Computed properties, boundary values |
| Sealed type / union | Property delegation for each variant |
| Repository / service impl | Conversion helpers, filtering, errors |
| Observer / manager | Lifecycle, debounce, state changes |
| Configuration / preferences | Defaults, type conversions, round-trips |
| Composite / aggregating layer | Merge logic, fallbacks, empty states |
| Interface / trait only | No test (tested via downstream fake) |
| UI: state-holder / hoisted state | TEST, extract holder, unit-test transitions |
| UI: rendering only (no logic) | No test (build + regression) |
| DI wiring / config | No test (verified by compilation) |
| Type migration / rename | No test (verified by compilation) |

**State-holder detection:** Hoisted state (`mutableStateOf`,
`useState`, `ref`, `@State`), branching effects (`LaunchedEffect`,
`useEffect` with deps), or input transformation = testable logic.
Extract the holder out of the framework component and unit-test
the transitions. "UI = no test" is the most-abused row in this
table; a state machine inside a Composable is still a state
machine.

### 3.2 Write Failing Tests (or Verify Existing Coverage)

If the test strategy says "No test," verify existing coverage
is green and skip to Phase 4. Otherwise:

- Write tests referencing the new function/class/property
- Tests describe expected behavior, not implementation
- For new functions: expect compile errors
- For behavior changes: expect assertion failures

### 3.3 Run Tests (Expect Failure)

Run the project's test command (see `PROJECT.md`) targeting
the specific test class. Confirm tests fail for the right
reason (compile error or assertion failure, not infrastructure).

---

## Phase 4: Implementation (per chunk)

### 4.1 Update Tracker

Set chunk status to `in_progress` in the JSON tracker.

### 4.2 Implement Production Code

- Follow existing patterns in the codebase
- Reuse existing utilities (don't reinvent)
- Keep changes minimal and focused
- For BATCH chunks: all files change together

### 4.3 Handle Constructor / Signature Cascading

When adding a dependency to a class or changing a function signature:

- Grep for all test files that instantiate the class or call the function
- Add the new parameter to every test call site
- This is the most common source of compile failures

### 4.4 Clean Up Dead Code

When a fix eliminates a code path, remove the dead code in the
same chunk. Don't leave it for a future cleanup pass.

Examples:
- Exception class no longer thrown -> remove class + all catch sites
- Feature flag removed -> remove both branches
- Method parameter no longer used -> remove parameter + update callers

**Why same chunk?** Dead code left behind confuses future readers
and creates false grep matches. The person implementing the fix
has the best context for what's now unreachable.

---

## Phase 5: Post-Test (per chunk)

### 5.1 Run Chunk Tests

Run the project's test command targeting the specific test class.
All tests must pass. If a test fails, fix the code (not the
test) unless the test is wrong about expected behavior.

### 5.2 Run Full Suite (Last Chunk Only)

For intermediate chunks, skip the full suite - chunk tests
are sufficient. Run the full suite after the **last** chunk
before Phase 6 (or if a chunk touches widely-shared code).

Check for regressions. Note pre-existing flaky tests but
don't block.

### 5.3 Build Verification

Run the project's build command. Compilation must succeed.

### 5.4 Update Tracker

Set chunk status to `complete` in the JSON tracker.

### 5.5 Manage Context

Prefer **context resets** over compaction. A clean session with
the tracker as handoff preserves more fidelity than compacted
context, which loses information unpredictably.

**Between chunks (preferred):** Start a new session. The JSON
tracker (`name` + `files_*` + `tdd` + `acceptance_criteria` + any
`notes`) gives the new session everything it needs. Use `/rename`
to name the session for reference.

**Mid-chunk (fallback only):** If you must compact within a chunk,
run `/compact Focus on the current chunk, tracker path, and test
results`. This is a fallback, finish the chunk and reset.

---

## Phase 6: Quality Verification

After all chunks complete, run the 8-point checklist. See
[quality-checklist.md](references/quality-checklist.md) for detail:
1. **Completeness** 2. **Correctness** 3. **Gaps (Functional)**
4. **Standards** 5. **Regression** 6. **Robustness**
7. **Gaps (Architectural)** 8. **Blindspots**

**GATE: All chunks complete triggers parallel review.** Spawn two
independent agents in a single message so they run concurrently. Both
are read-only (`red-team` in `both` mode reports; it does not apply),
so concurrent runs are safe:

1. **`review-impl` agent**, plan-conformance reviewer. Runs the 8
   quality-checklist criteria against the tracker. Answers "does the
   implementation match what was planned?"
2. **`red-team` agent** (`mode: both`), adversarial diff reviewer.
   Hunts correctness bugs (5 angles) and flags cleanup (reuse,
   simplification, efficiency, altitude), verifies each finding
   (recall-biased), then sweeps for gaps. Answers "what is wrong or
   wasteful in this diff, regardless of the plan?"

```
In parallel:
- Use the review-impl agent to review implementation against [path to tracker]
- Use the red-team agent in mode: both to review the changed files (pass the tracker path)
```

Complementary by design: `review-impl` checks conformance to intent
(conservative, PASS when the plan is met); `red-team` checks
correctness independent of intent (recall-biased, surfaces
everything, then verifies). A bug conforming to a flawed plan is caught
only by `red-team`; a correct-but-off-spec change only by `review-impl`.

Merge findings. Address every `red-team` **FAIL** (CONFIRMED
correctness) and every `review-impl` FAIL before completing; treat WARN
as a judgment call. Re-run the suite after any fix.

> **Why not `/code-review`?** A skill runs in the main loop and can't
> invoke another skill or slash command, so it can't trigger
> `/code-review` (itself a forked subagent). `red-team` ports the same
> finder-angle engine into an agent this skill *can* spawn via the Agent
> tool. For the cleanup-only pass (the `/simplify` equivalent), spawn
> `red-team` in `mode: cleanup`: only the four cleanup angles, applies
> safe fixes, skips anything behavior-changing, no bug hunting.

**Agent failure** (timeout, error): fall back to self-check against
the full [quality-checklist.md](references/quality-checklist.md).
Document any agent failures in the tracker.

### Post-Implementation Documentation

Create or update a reference document **when the work will outlive
this session**, multi-chunk features, deferred follow-ups, bug fixes
with a non-obvious root cause, or changes to a subsystem that already
has a design/analysis doc. It's the single source of truth for what was
done, why, and what remains, and it survives context compaction.

**Skip it** for small, self-contained changes whose full story is
already in the diff, the commit message, and the tracker's acceptance
criteria. Writing one anyway is scope the user didn't ask for. When in
doubt: would a future session be lost without it? If the diff and commit
answer that, don't write the doc.

When you do write one, cover: what changed and why (bugs found, spec
sections, fixes applied); what was tested and confirmed working; what
remains (known gaps, future work); test file locations and counts.

If the feature already has an analysis/design doc or issue tracker,
update it instead of creating a new one: update implemented-item
status, add a commit/version reference, mark remaining items pending.

---

## Lessons Learned (Apply Every Time)

1. **Tracker discipline** -
   Update status to `in_progress` BEFORE starting work
2. **Batch interconnected type changes** -
   Changing a shared type's field? Change all consumers in one chunk
3. **Platform quirks** -
   Research boundary values, write tests BEFORE implementing
4. **Don't over-chunk UI wiring** -
   Keep compatible signatures to avoid cascading changes
5. **Sealed type formatting** -
   Use common properties first; branch only for unique data
6. **Catch narrow exceptions for skip+continue** -
   When converting `throw` to `continue` (resilience fix),
   narrow catch scope. Fatal errors (OOM, stack overflow) mean
   the runtime is broken, continuing cascades failures. Verify
   cancellation exceptions can't reach the catch site
7. **Fix sibling components together** -
   If two components share the same bug pattern, fix both
   in one pass. Don't leave one broken for a future session
8. **Check ALL required constructor params** -
   When creating instances in tests or extensions, verify
   no required params are missing
9. **Adding checks breaks existing tests** -
   When adding validation/permission checks to production
   code, existing tests that skip setup for that check
   will fail. Grep test files and add required setup
10. **Guard against false positive tests** -
    When asserting string/pattern presence, verify the match
    is in the right context - not in a comment, label, or
    unrelated field. Use precise assertions (line-level,
    regex-anchored) instead of broad substring checks.
    A broad check can pass for the wrong reason, hiding
    the real bug
11. **Pre-written tests skip Phase 3** -
    When failing tests already exist (compliance review, bug
    reproduction, user-provided test case), Phase 3 collapses
    to "verify tests still fail for the right reason." Don't
    rewrite or duplicate them - go straight to Phase 4
12. **Stress-test your process scaffolding** -
    Every process step encodes assumptions about model
    limitations. As models improve, re-evaluate whether
    scaffolding (sprint decomposition, heavy chunking,
    frequent resets) is still needed. Remove what no longer
    helps, simpler processes with fewer handoffs are faster
    and lose less context. With a strong-instruction-following
    model, prefer fewer/larger chunks and fewer resets: the
    tracker and review gates are load-bearing, chunk-granularity
    and reset-frequency are not. Such a model also follows a
    conservative instruction literally and will under-report,
    so where a step says "be careful" or "only flag important
    issues," prefer surface-everything-then-filter (why the
    red-team gate is recall-biased with a downstream verify)
13. **Calibrate evaluation criteria over time** -
    After Phase 6, compare your quality assessment to what
    the user actually flagged. If you marked "all criteria
    met" but the user found gaps, tighten the checklist or
    acceptance criteria for next time. This QA tuning loop
   , read evaluator output, find divergences from human
    expectations, refine criteria, compounds over sessions
14. **Check dependency version changelogs during analysis** -
    APIs can change behavior across minor versions without
    changing their signature. A method that fully re-executes
    in v1.0 may only recompose a subset in v1.1. During
    Phase 1.3, check the changelog/migration guide for each
    major dependency at your pinned version. This is
    especially important for framework-level dependencies
    (UI toolkits, DI containers, async runtimes) where
    lifecycle semantics evolve between releases

---

## Commit Guidance

Do not commit proactively. Wait for the user to request it.
Refer to `PROJECT.md` for project-specific commit conventions
(author, message format, trailers).

---

## Session Resumption

When resuming work on an in-progress feature:

1. Read the JSON tracker to find current progress
2. Check `plan_review` field, if missing or `"FAIL"`, run Phase 2.5
   before proceeding
3. Read the plan file for detailed chunk descriptions
4. Find next `pending` chunk where all `depends_on` are `complete`
5. Read `name`, `files_create`/`files_modify`, `tdd`,
   `acceptance_criteria`, and any `notes` on that chunk
6. Follow TDD workflow (Phase 3 -> 4 -> 5)
7. Update tracker status

**Tip:** Use `--resume` to continue a named session, or read the
JSON tracker if starting a fresh session on an existing feature.