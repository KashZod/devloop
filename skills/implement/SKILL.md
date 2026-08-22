---
name: implement
description: "Test-driven implementation of a plan produced by /plan: loads the JSON tracker, then per chunk writes a failing test, implements until it passes, and runs a two-agent quality gate (review-impl conformance + red-team correctness). Use after /plan has produced an approved tracker. Requires a tracker whose plan_review gate passed."
argument-hint: "[feature name, or path to the impl-tracker JSON from /plan]"
effort: high
---

# Implementation Process (Test-Driven)

Implement the plan for: $ARGUMENTS

Tests give the implementer a self-verification loop. Instead of producing
code that looks right, write tests first, then implement until they pass,
so correctness is checked by execution rather than by inspection.

This skill is the **build** half of the loop. The **plan** half, code
exploration, chunk decomposition, and the plan-review gate, lives in the
companion `/plan` skill, which produces the tracker this skill reads. A
skill cannot invoke another skill, so if no approved tracker exists yet,
this skill stops and asks you to run `/plan` first.

## Mapping to the Explore -> Plan -> Code Loop

| Workflow Phase | Implement Phase | What Happens |
|---|---|---|
| **Explore / Plan** | (done in `/plan`) | Analysis, chunking, and plan review already happened |
| **Explore** | Phase 1: Load the Plan | Read the tracker, verify the gate, orient on the next chunk |
| **Code** | Phase 2: TDD Cycle | Per chunk: failing test -> code -> passing test |
| **Verify** | Phase 3: Quality Verification | review-impl + red-team gate; converge |
| **Commit** | (user-initiated) | Commit when the user requests |

## When to Use This Process

| Scope | Approach |
|---|---|
| Trivial (typo, rename, version bump) | Don't use this skill -- just do it directly |
| Anything larger | Run `/plan` first to produce a tracker, then `/implement` builds it |

`/plan` sizes the work (a small fix becomes a 1-chunk tracker; a
cross-cutting feature becomes a layered one). This skill reads whatever
the tracker holds and builds it chunk by chunk. If you invoke
`/implement` with no tracker in place, it will point you at `/plan`.

## Supporting Files

Load these on demand, not all upfront:

| File | When to Load |
|---|---|
| [tracker-schema.md](../plan/references/tracker-schema.md) | Phase 1, to read/update tracker status and resume fields |
| [quality-checklist.md](references/quality-checklist.md) | Phase 3 (final verification, or agent-failure fallback) |

## Process Overview

```text
Phase 1: Load the Plan (verify plan_review gate; blocks the TDD cycle)
Phase 2: TDD Cycle (per chunk: Red -> Green -> Verify)
Phase 3: Quality Verification
  └─ Gate: review-impl + red-team agents (parallel, blocks completion)
```

Each phase must complete before the next begins. For multi-chunk
features, Phase 2 repeats per chunk in dependency order. Gates are
artifact-triggered: a passing `plan_review` (`PASS` or
`PASS-WITH-WARNINGS`) in the tracker unblocks Phase 2;
all chunks complete triggers review-impl + red-team in Phase 3.

---

## Phase 1: Load the Plan

The engineering config (build/test/lint commands, standards, blindspots,
and the spec/tracker directory settings) resolves in this order:
`.devloop/config.md` in the project root, else generic mode. Later
mentions of `.devloop/config.md` in this skill refer to that file when it
exists.

### 1.1 Locate the Tracker

- Find the tracker `/plan` produced (filename `impl-tracker-<feature>.json`;
  the tracker-directory setting in `.devloop/config.md`, default
  `.devloop/trackers/`)
- If more than one matches, confirm which feature with the user
- Read the plan/spec files the tracker references (`plan_doc`,
  `design_doc`, and `spec_doc`, falling back to any file in the configured
  spec directory (the spec-directory setting in `.devloop/config.md`,
  default `docs/specs/`) only if `spec_doc` is absent) for chunk detail

### 1.2 Verify the Plan-Review Gate

Read the tracker's top-level `plan_review` field:

- `PASS` or `PASS-WITH-WARNINGS`: proceed (note any warnings)
- Anything else, `PENDING` (created but the gate has not run), `FAIL`,
  missing, or no tracker at all: **stop.** Do not write code. Report: "No
  approved plan found. Run `/plan <feature>` first, it decomposes the
  work and gates the plan through review-plan." A skill cannot invoke
  another skill, so this is a hard stop, not a fallback.

### 1.3 Validate the Chunk Graph

Before building, confirm the chunk graph is sound, these are the states
where "next `pending` chunk" selection and the "all chunks complete" gate
would otherwise disagree and leave the feature silently unfinished:

- Every `depends_on` id exists and the graph is acyclic (no chunk depends,
  directly or transitively, on itself). A cycle or a dangling id means no
  chunk ever becomes selectable and the loop stalls, so **stop and report
  the bad edge to the user** instead of building.
- No chunk is stuck at `status: error`. An `error` chunk (set when a chunk
  was blocked) is re-entered here like `in_progress`: read its `notes`,
  resolve the blocker, set it back to `in_progress`, and finish it. If it
  cannot be resolved, **stop and surface it**, never skip past it (a
  skipped `error` chunk means Phase 3 never triggers).

### 1.4 Orient on the Next Chunk

- Find the next `pending` chunk whose `depends_on` are all `complete`
- Read its `name`, `files_create`/`files_modify`, `test_files`, `tdd`,
  `acceptance_criteria`, and any `notes`, this is a complete handoff
- Read the current state of the files it touches

**Context tip:** If your harness provides a subagent or parallel-tool
capability, use it for broad exploration across unfamiliar code;
otherwise explore sequentially in-context, that is the default and is
correct.

---

## Phase 2: TDD Cycle (per chunk)

Repeat for each chunk in dependency order: **Red** (failing test) ->
**Green** (implement) -> **Verify** (tests pass, no regression).

### 2.1 Start the Chunk

Set the chunk `status` to `in_progress` in the tracker BEFORE writing
anything. The tracker is a file-based artifact that survives context
resets; update it first so a resuming session knows where work stopped.

### 2.2 Determine Test Strategy (Red)

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
Extract the holder out of the framework component and unit-test the
transitions. "UI = no test" is the most-abused row in this table; a
state machine inside a Composable is still a state machine.

### 2.3 Write Failing Tests (or Verify Existing Coverage)

If the test strategy says "No test," verify existing coverage is green
and skip to 2.5. Otherwise:

- Write tests referencing the new function/class/property
- Tests describe expected behavior, not implementation
- For new functions: expect compile errors
- For behavior changes: expect assertion failures

**Pre-written tests skip the Red step.** When failing tests already
exist (compliance review, bug reproduction, user-provided case), this
step collapses to "verify they still fail for the right reason." Don't
rewrite or duplicate them.

### 2.4 Run Tests, Expect Failure

Run the project's test command (see `.devloop/config.md`) targeting the
specific test class. Confirm tests fail for the right reason (compile error or
assertion failure, not infrastructure).

### 2.5 Implement Production Code (Green)

- Follow existing patterns in the codebase
- Reuse existing utilities (don't reinvent)
- Keep changes minimal and focused
- For BATCH chunks: all files change together

### 2.6 Handle Constructor / Signature Cascading

When adding a dependency to a class or changing a function signature:

- Grep for all test files that instantiate the class or call the function
- Add the new parameter to every test call site
- This is the most common source of compile failures

### 2.7 Clean Up Dead Code

When a fix eliminates a code path, remove the dead code in the same
chunk. Don't leave it for a future cleanup pass.

- Exception class no longer thrown -> remove class + all catch sites
- Feature flag removed -> remove both branches
- Method parameter no longer used -> remove parameter + update callers

**Why same chunk?** Dead code confuses future readers and creates false
grep matches. The person implementing the fix has the best context for
what's now unreachable.

### 2.8 Run Chunk Tests (Verify)

Run the project's test command targeting the specific test class. All
tests must pass. If a test fails, fix the code (not the test) unless the
test is wrong about expected behavior.

### 2.9 Regression + Build (last chunk)

For intermediate chunks, chunk tests are sufficient. After the **last**
chunk (or if a chunk touches widely-shared code), run the full suite and
the build/compile command. Check for regressions. Note pre-existing
flaky tests but don't block.

### 2.10 Complete the Chunk + Manage Context

Set the chunk `status` to `complete`. Then decide on context:

Modern models hold multi-chunk features in a single session without
losing fidelity. Default to continuing in the same session, the tracker
and review gates are load-bearing; frequent resets are not. Reset only
when context is genuinely degrading. When you do reset, the tracker
(`name` + `files_*` + `tdd` + `acceptance_criteria` + any `notes`) is a
complete handoff. Prefer a clean reset over lossy compaction. If your
harness supports focused compaction, scope it to the current chunk,
tracker path, and test results.

---

## Phase 3: Quality Verification

After all chunks complete, the primary gate is the two review agents
below. The 8-point checklist in
[quality-checklist.md](references/quality-checklist.md) is the shared
concern vocabulary the reviewers use, and your fallback self-check when an
agent cannot run, you do not run it in addition to the agents when they
are available:
1. **Completeness** 2. **Correctness** 3. **Gaps (Functional)**
4. **Standards** 5. **Regression** 6. **Robustness**
7. **Gaps (Architectural)** 8. **Blindspots**

"All chunks complete" means every chunk is `status: complete`. A chunk at
`error`, or a graph where no `pending` chunk is selectable but not all are
`complete` (see Phase 1.3), is a **blocked feature**: do not treat it as
complete or trigger this gate, stop and surface it to the user.

**GATE: All chunks complete triggers parallel review.** Spawn the review
agents in a single message so they run concurrently. They are read-only
(`review-impl` and `red-team` in `bugs`/`both`, plus `cleanup` when
invoked report-only, all report; none apply), so concurrent runs are
safe:

1. **`review-impl` agent**, the conformance gate. Verifies plan match,
   acceptance criteria met with quoted test evidence, test quality, and
   regression against the tracker. Answers "does the implementation match
   what was planned, and does the suite prove it?" It does **not** hunt
   correctness bugs, robustness gaps, standards violations, or cleanup,
   that is `red-team`'s territory, so the two no longer overlap.
2. **`red-team` agent**, adversarial diff reviewer. Hunts correctness
   bugs (5 angles) and flags cleanup (reuse, simplification, efficiency,
   altitude), verifies each finding (recall-biased), then sweeps for gaps.
   Answers "what is wrong or wasteful in this diff, regardless of the
   plan?"

**Size the red-team half** the same way `/plan` sizes work (its Trivial /
Small / Medium+ / Large table), by the set of files touched across the
completed chunks:

- **Small diff** (a single-file change, or a trivial one with no new
  logic, matching `/plan`'s Small row): one `red-team` in `mode: both`.
- **Large diff** (broader: multiple files or cross-cutting, i.e. `/plan`
  Medium+ and Large): split the red-team half into `mode: bugs` and
  `mode: cleanup` run in parallel, so neither family crowds the other
  out. Invoke that `mode: cleanup` run **report-only** (it can otherwise
  apply fixes), which keeps the whole gate read-only.

Small diff (default):

```
In parallel:
- Use the review-impl agent to review implementation against [path to tracker]
- Use the red-team agent in mode: both to review the changed files (pass the tracker path)
```

Large diff (split the red-team half):

```
In parallel:
- Use the review-impl agent to review implementation against [path to tracker]
- Use the red-team agent in mode: bugs to review the changed files (pass the tracker path)
- Use the red-team agent in mode: cleanup to review the changed files, report only (pass the tracker path)
```

Complementary by design: `review-impl` is conservative (PASS once the
plan is met); `red-team` is recall-biased (surfaces everything, then
verifies). A bug conforming to a flawed plan is caught only by `red-team`;
a correct-but-off-spec change only by `review-impl`.

Merge findings. Address every `red-team` **FAIL** (CONFIRMED
correctness) and every `review-impl` FAIL before completing; treat WARN
as a judgment call. Re-run the suite after any fix.

**No project rule file?** When neither `.devloop/config.md` nor a project
rules file (`CLAUDE.md`/`AGENTS.md`) exists, `review-impl` still defers
standards and architecture to `red-team`, but `red-team`'s conventions
angle has no rules to quote and returns nothing, so those concerns fall
through the gap between the two agents. Cover them yourself: run checklist
points 4 (Standards) and 7 (Gaps, Architectural) as an in-context
self-check so they are not silently dropped.

### Converge (when a finding invalidates the plan or the spec)

Most findings are fixed in place, edit the code, re-run the suite, done.
But some findings reach past the code:

- **The spec was wrong** (a finding shows an acceptance *criterion itself*
  is wrong, missing, or contradictory, not just the plan's approach to
  it): **stop and route to `/spec`.** The plan-review gate is built to
  *reject* divergence from the spec, so re-gating a plan that contradicts
  the spec would just FAIL. Tell the user to re-run `/spec` (update mode)
  to fix the criterion; then `/plan` merges the revised spec into this
  tracker (§3.1) and re-gates. Do not invent the corrected requirement
  here.
- **The plan was wrong** (a whole chunk's approach is wrong, or the review
  surfaces work no chunk covers, but the spec's criteria still stand):
  converge in-session, without leaving or discarding the tracker:

1. Append the corrective/remaining work to the tracker as new `pending`
   chunks (with acceptance criteria and `tdd`), and in the same (atomic)
   write set the tracker's `plan_review` to `FAIL`. Leave the already-built
   chunks at `status: complete`, do not reset them. Setting
   `plan_review: FAIL` *before* re-gating is what makes this window
   crash-safe: if the session is lost between here and step 3, resumption
   sees `FAIL`, routes to `/plan`, and `/plan` §3.1 merges into this
   tracker (preserving the completed and appended chunks) rather than
   building the ungated corrective chunks under a stale `PASS`.
2. Bump `convergence_rounds` (treat absent as `0`), then re-gate the
   updated plan by spawning the `review-plan` **agent** directly, the same
   way this phase spawns `review-impl` and `red-team`. This is *not* the
   same as re-running the `/plan` skill: a skill cannot invoke another
   skill, but any skill can spawn an agent, and re-running the `/plan`
   skill would regenerate the tracker and lose the completed and
   just-appended chunks. Keep convergence in-session, on this tracker.
   Bumping the counter here (not only when chunks are appended) counts
   every re-gate attempt, so the bound below covers both loops.

   ```
   Use the review-plan agent to review [path to tracker]
   ```

   If the harness cannot spawn agents at all (not just a failed spawn),
   fall back to the in-context self-check against
   [quality-checklist.md](references/quality-checklist.md), the same
   fallback the Phase 3 gate uses, and note the lost isolation in the
   tracker.
3. Record the agent's verdict in the tracker's `plan_review` field, then:
   - `PASS` / `PASS-WITH-WARNINGS`: return to Phase 2 and build the new
     `pending` chunks in dependency order.
   - `FAIL`: revise the appended chunks per the findings and re-gate
     (return to step 2, which bumps `convergence_rounds` again). Do not
     enter Phase 2 while `plan_review` is `FAIL`, that is the same
     hard-stop invariant Phase 1.2 enforces.

**Bounded loop:** `convergence_rounds` lives in the tracker (bumped before
each re-gate in step 2), so the cap survives session resets and bounds
both the append loop and the re-gate loop. When it reaches 2, or the same
criterion FAILs twice, **stop and surface to the user**, the plan needs a
human decision, not another automatic round. This keeps the plan and the
code converging on the same target instead of drifting apart.

**Bailing out of a convergence round.** If the user abandons a round (or
the bound is hit and they choose not to continue), the tracker is left
with `plan_review: FAIL` plus appended `pending` chunks, and `/implement`
refuses to run in that state. To discard the round cleanly, **with the
user's confirmation** (it throws away the corrective work): drop the
appended `pending` chunks and set `plan_review` back to `PASS`, the
completed chunks were already gated. Leave `convergence_rounds` as a
record of the attempt.

> **Cleanup-only pass:** spawn `red-team` in `mode: cleanup`, the four
> cleanup angles only, applies safe fixes, no bug hunting. `red-team`
> exists because a skill runs in the main loop and cannot invoke another
> skill or slash command; it ports the finder-angle engine into an agent
> this skill *can* spawn via the Agent tool.

**Agent failure** (timeout, error): fall back to a self-check against
the full [quality-checklist.md](references/quality-checklist.md).
Document any agent failures in the tracker.

### Post-Implementation Documentation

Create or update a reference document **when the work will outlive this
session**, multi-chunk features, deferred follow-ups, bug fixes with a
non-obvious root cause, or changes to a subsystem that already has a
design/analysis doc. **Skip it** for small, self-contained changes whose
full story is already in the diff, commit message, and tracker, writing
one anyway is scope the user didn't ask for. When in doubt: would a
future session be lost without it?

When you do write one, cover what changed and why, what was tested and
confirmed, and what remains (known gaps, future work, test locations).
If the feature already has a design doc or issue tracker, update that
instead of creating a new one.

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
   When converting `throw` to `continue` (resilience fix), narrow catch
   scope. Fatal errors (OOM, stack overflow) mean the runtime is broken,
   continuing cascades failures. Verify cancellation exceptions can't
   reach the catch site
7. **Fix sibling components together** -
   If two components share the same bug pattern, fix both in one pass.
   Don't leave one broken for a future session
8. **Check ALL required constructor params** -
   When creating instances in tests or extensions, verify no required
   params are missing
9. **Adding checks breaks existing tests** -
   When adding validation/permission checks to production code, existing
   tests that skip setup for that check will fail. Grep test files and
   add required setup
10. **Guard against false positive tests** -
    When asserting string/pattern presence, verify the match is in the
    right context, not in a comment, label, or unrelated field. Use
    precise assertions (line-level, regex-anchored) instead of broad
    substring checks. A broad check can pass for the wrong reason,
    hiding the real bug
11. **Stress-test your process scaffolding** -
    Every process step encodes assumptions about model limitations. As
    models improve, re-evaluate whether scaffolding (heavy chunking,
    frequent resets) is still needed. With a strong-instruction-following
    model, prefer fewer/larger chunks and fewer resets: the tracker and
    review gates are load-bearing, chunk-granularity and reset-frequency
    are not. Such a model also follows a conservative instruction
    literally and will under-report, so where a step says "only flag
    important issues," prefer surface-everything-then-filter (why the
    red-team gate is recall-biased with a downstream verify)
12. **Calibrate evaluation criteria over time** -
    After Phase 3, compare your quality assessment to what the user
    actually flagged. If you marked "all criteria met" but the user
    found gaps, tighten the checklist or acceptance criteria for next
    time. Read evaluator output, find divergences from human
    expectations, refine, this QA tuning loop compounds over sessions
13. **Check dependency version changelogs during planning** -
    APIs can change behavior across minor versions without changing
    their signature. A method that fully re-executes in v1.0 may only
    recompose a subset in v1.1. `/plan` checks the changelog/migration
    guide for each major dependency at the pinned version; if you find a
    behavior change here, it may invalidate the plan (see Converge)

---

## Commit Guidance

Do not commit proactively. Wait for the user to request it.
Refer to `.devloop/config.md` for project-specific commit conventions
(author, message format, trailers).

---

## Session Resumption

When resuming work on an in-progress feature:

1. Read the JSON tracker to find current progress
2. Check `plan_review`, if it is `"PENDING"`, `"FAIL"`, or missing, the
   plan is not gated, run `/plan` before proceeding (this skill cannot
   invoke it for you)
3. Read the plan file for detailed chunk descriptions
4. **Re-enter any unfinished chunk first.** A chunk left at `in_progress`
   or `error` (e.g. a crash mid-build) is neither `pending` nor
   `complete`, so the next-`pending` search below would skip it forever.
   Re-enter it, finish or re-verify it, before looking for new work (see
   Phase 1.3)
5. Find the next `pending` chunk where all `depends_on` are `complete`
6. Read `name`, `files_create`/`files_modify`, `tdd`,
   `acceptance_criteria`, and any `notes` on that chunk
7. Follow the Phase 2 TDD cycle
8. Update tracker status

**Tip:** Resume by reading the JSON tracker, it is a complete handoff.
If your harness supports named or resumable sessions, use that to return
to the same context instead of starting fresh.
