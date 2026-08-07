# 8-Point Quality Verification Checklist

Run this checklist after all implementation chunks are complete.
Each point should be verified with specific evidence
(test results, grep output, build logs).

---

## 1. Completeness

Verify every acceptance criterion is met.

**Self-evaluation warning:** This is where generators most often
over-report. Cross-check each criterion against the tracker's
`acceptance_criteria` array, don't rely on memory of what was
planned. If using a subagent evaluator, have it verify independently.

**How to check:**

- List all acceptance criteria from the tracker (not from memory)
- For each criterion, identify the code that implements it
- For each criterion, identify the test that verifies it
- Mark any criteria that rely on manual testing (UI changes)

**Template:**

```markdown
- [ ] Criterion 1: [describe] - verified by [test or file:line]
- [ ] Criterion 2: [describe] - verified by [test or file:line]
```

**Common misses:**

- Feature works for happy path but edge cases aren't covered
- New parameter added but not wired at all call sites
- Test exists but doesn't assert the right thing

---

## 2. Correctness

Verify data mapping, conversions, and logic are correct.

**How to check:**

- Review each data transformation (entity -> UI model)
- Check boundary values (0, -1, MAX_VALUE, null, empty)
- Verify timezone handling if applicable
- Check numeric precision (type widths, float vs integer, units)

**Common misses:**

- Off-by-one errors in range calculations
- Nullable field treated as non-null (or vice versa)
- Enum/constant value mismatches between layers
- Unit confusion (milliseconds vs seconds, bytes vs kilobytes)

---

## 3. Gaps (Functional)

Verify no broken references, missing wiring, or orphaned code.

**Self-evaluation warning:** Generators tend to miss gaps in files
they didn't directly modify. Always grep, don't rely on recall of
which files reference the changed code.

**How to check:**

```bash
# Check for references to old/removed types
grep -r "OldTypeName" src/

# Check for TODO/FIXME left behind
grep -r "TODO\|FIXME" src/ --include="*.ext"

# Run linter to catch unused imports/variables
# (use project's lint command from PROJECT.md)
```

**Common misses:**

- Old type referenced in a file outside the chunk list
- Import statement left behind after removing usage
- Comment referencing "Phase 2" or "TODO" placeholder
- Callback parameter added but caller passes empty/noop handler

---

## 4. Standards

Verify implementation follows project standards and
platform conventions.

**How to check:**

- Cross-reference project guidelines (CLAUDE.md or equivalent)
- Verify framework conventions (component patterns, naming)
- Check naming conventions (language style, package/module structure)
- Verify architecture layers are respected

**Project-specific standards:** See `PROJECT.md` §Standards.

---

## 5. Regression

Verify existing functionality isn't broken.

**How to check:**

Run the project's test, build, and lint commands (see `PROJECT.md`).

**Evidence to record:**

- Total test count (should not decrease)
- Any pre-existing flaky tests (note but don't block)
- Build warnings count (should not increase)
- Lint warnings (should not increase)

**Distinguishing pre-existing vs new failures:**
Check if the failing test class was modified in this feature.
If not, it's likely pre-existing. Run the failing test in
isolation to confirm.

---

## 6. Robustness

Verify error handling, empty states, and cleanup.

**How to check:**

- What happens when the data source returns empty?
- What happens on permission/auth errors?
- What happens on network timeout?
- Are resources cleaned up on teardown/unmount/dispose?
- Are async operations cancelled on scope cancellation?

**Common scenarios:**

- Empty list: UI shows appropriate message, no crash
- Auth error: Feature shows error state, no crash
- Concurrent access: No race conditions in shared state
- Config/env change: State survives (if expected to)
- Large data: No performance cliff, no resource exhaustion

---

## 7. Gaps (Architectural)

Verify abstraction boundaries are respected.

**How to check:**

```bash
# Example: UI should NOT import data layer directly
grep -r "import.*data\." src/ui/ --include="*.ext"

# Example: Controllers should NOT import DB layer
grep -r "import.*db\." src/controllers/ --include="*.ext"
```

**Architecture rules to verify (see PROJECT.md):**

- Layer boundaries: UI -> Domain -> Data (no shortcuts)
- Test doubles match convention (fakes vs mocks)
- Dependency injection: no manual instantiation of services
- Type safety: sealed types where expected, not string enums

---

## 8. Blindspots

Verify edge cases that automated tests may miss.

**Self-evaluation warning:** This is the hardest point to
self-assess honestly. Generators naturally focus on what they
built, not what they missed. The `red-team` agent running in
parallel (see Phase 6) catches what self-evaluation misses, it
reviews the diff adversarially in a fresh context, so it isn't
anchored on what you intended to build.

**Always check:**

- [ ] **Security**: Input validation, injection, auth boundaries
- [ ] **Concurrency**: Race conditions, rapid clicks, parallel ops
- [ ] **Error propagation**: Errors surface to user, not swallowed
- [ ] **Resource cleanup**: Memory, file handles, connections
- [ ] **Future migration**: Will this design need breaking changes
  later? Document the migration path

**Platform-specific blindspots (see PROJECT.md §Blindspots):**

Common examples across platforms:
- Web: CORS, CSP, XSS, accessibility, browser compat
- Mobile: Dark theme, RTL layout, screen sizes, permissions
- Backend: Rate limiting, pagination, idempotency, timeouts
- CLI: Signal handling, stdin/stdout encoding, exit codes

**How to document:**

For each blindspot, note:

1. What could go wrong
2. Likelihood (low/medium/high)
3. Mitigation (if any)
4. Whether manual testing is needed
