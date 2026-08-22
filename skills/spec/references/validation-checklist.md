# Spec Validation Checklist

Run this checklist during Phase 4 after the spec is drafted and
clarifications are resolved. Each point must be verified with
specific evidence from the spec file.

**Evidence rule:** Every WARN or FAIL must quote the exact spec line it
refers to, the way the review agents quote a code line. Do not flag from
memory or paraphrase, if you cannot point at the offending text, it is
not a finding.

Pass criteria: all 8 points pass, or remaining failures are
documented in the spec's Notes section with rationale.

Max 2 fix iterations. If issues persist after 2 rounds, mark
the spec as Ready-with-warnings and proceed.

---

## 1. Testability

Every acceptance criterion can be converted to a test.

**How to check:**
- For each Given/When/Then, ask: "Can I write a test that passes
  when this works and fails when it doesn't?"
- The test complexity hint, `(1 test)`, `(parameterized)`,
  `(integration)`, should be present and accurate
- Red flags: criteria using "appropriate", "graceful", "intuitive",
  "fast" without a measurable threshold

**Common misses:**
- "System handles errors properly", HOW? What does the user see?
- "Performance is acceptable", What's the threshold?
- "UI is responsive", At what breakpoint? What changes?
- "Data is validated", Which fields? What rules? What error?

**Self-evaluation warning:** It's tempting to say "all criteria
are testable" without actually imagining the test. For each
criterion, mentally construct the specific assertion, don't
just pattern-match the Given/When/Then structure.

**Adversarial check technique:** For each criterion, ask: "Could
an implementation pass this criterion while being completely wrong?"
If yes, the criterion is too vague. Example: "Then the system
responds appropriately" passes for ANY response. "Then the system
returns a 400 status with field-level error messages" can only
pass when correct.

---

## 2. Completeness

Every user story has acceptance criteria. Every P1 story has
both happy-path and error-path criteria.

**How to check:**
- Count stories vs criteria. P1 stories should have 2+ criteria
  (at least one happy path, one error path)
- P2/P3 stories need at least 1 criterion each
- No story should have an empty acceptance criteria section

**Variant completeness:** If a story's behavior branches by N
variants (scenarios, user roles, platforms, modes), each variant
needs at least one criterion. Count the variants mentioned in
the story, count the criteria covering each, flag uncovered
variants. Example: a story says "generates output for 4 scenarios"
but only 2 of 4 have criteria, the other 2 are untested.

**Common misses:**
- Happy path only (no error scenarios for P1 stories)
- Missing "what if the user cancels midway?"
- Missing "what if input is empty/invalid?"
- Missing "what if the operation partially succeeds?"
- Story branches by N variants but only some have criteria

---

## 3. Clarity

No vague adjectives without measurable targets. No jargon
without definition. No pronouns with ambiguous referents.

**How to check:**
- Search for: fast, slow, large, small, many, few, appropriate,
  suitable, robust, scalable, intuitive, seamless, modern,
  responsive, secure, efficient, reliable
- Each must have a measurable qualifier or be removed/replaced
- Domain terms should be self-evident from context or defined
  on first use

**Common misses:**
- "Large files", how large? 1MB? 1GB? 100GB?
- "Recent items", how recent? Last hour? Last 7 days?
- "Quickly loads", under 200ms? Under 1s? Under 5s?
- "Secure access", authentication? authorization? encryption?

---

## 4. Scope

Boundaries are explicit. There is an "Out of Scope" section.
P1/P2/P3 boundaries are defensible.

**How to check:**
- "Out of Scope" section exists and has at least one item
  (for medium+ features)
- No "while we're at it" additions hiding in P1 stories
- Could someone argue a P2 should be P1? If yes, the "Why P_"
  rationale should address it

**Common misses:**
- Scope defined by what's IN but not what's OUT
- P3 stories that are actually essential for P1 to be usable
- Feature creep disguised as "edge case handling"
- Unbounded requirements ("supports all formats")

---

## 5. Independence

User stories can be implemented and tested independently.
P1 stories deliver standalone value.

**How to check:**
- For each P1 story, ask: "Can I ship this alone and demo it?"
- No circular dependencies between stories
- P2/P3 may depend on P1 but not on each other
- Stories don't share setup assumptions ("US2 assumes US1 ran first")

**Common misses:**
- Stories that are really sub-tasks of a single story
- A "view" story that assumes a "create" story shipped first
  (acceptance criteria should handle the empty state)
- Stories that require shared infrastructure not in any story's
  acceptance criteria

---

## 6. Priority

Stories are prioritized P1/P2/P3. The P1 set forms a coherent
MVP that delivers user value on its own.

**How to check:**
- At least one P1 story exists
- The P1 set alone would be a useful, shippable increment
- Every story has a "Why P_" justification
- Everything is NOT P1, if it is, priorities aren't real

**Priority dependency check:** If a P1 story depends on work
that's currently P2 or P3 (or doesn't exist yet), flag it:
- Option A: Promote the dependency to P1
- Option B: Restructure the P1 story to remove the dependency
- Option C: Document the dependency in Notes with a plan

**Common misses:**
- All stories marked P1 (no real prioritization)
- P1 stories that can't function without P2 stories
- Priority based on technical ordering instead of user value

---

## 7. Edge Cases

Key failure modes and boundary conditions are identified.
At minimum: empty state, error state, boundary values.

**How to check:**
- Edge Cases section is non-empty
- Cross-reference with taxonomy categories 5 (Error Handling)
  and 6 (Edge Cases & Boundaries)
- Each P1 story has at least one edge case
- Domain-specific concerns from .devloop/domain.md are addressed
- Category tags `[Category N]` are present for traceability

**Common misses:**
- Only feature-level edge cases (missing domain interaction)
- Timezone/locale edge cases for time-sensitive features
- Concurrent operation scenarios for shared data
- Empty state (no data yet) vs error state (failed to load)

---

## 8. Resolution

No unresolved `[NEEDS CLARIFICATION]` markers remain.

**How to check:**
- Search the spec for `[NEEDS CLARIFICATION]`
- If any remain, they must be either:
  - Resolved (marker replaced with the answer)
  - Deferred with rationale in Notes section:
    `[DEFERRED: not clarified, <reason>]`

**Common misses:**
- Markers buried in nested sections
- Markers resolved in Clarifications section but not updated
  in the original location
- New ambiguities introduced during Phase 4 fixes

---

## Project-Specific Validation

After the 8 generic points above, check the spec against
project-specific criteria:

1. Load `.devloop/domain.md` "Domain-Specific Concerns" section
2. Verify each concern is addressed (in Edge Cases, Acceptance
   Criteria, or explicitly in Out of Scope)
3. Load `.devloop/domain.md` "Quality Standards" section
4. Verify each standard is met

Document project-specific failures the same way as generic
failures, fix or add to Notes with rationale.

---

## Handling Failures

**If all 8 points pass:** Mark spec status as `Ready`. Proceed
to Phase 5 (Handoff).

**If points fail (iteration 1):** Fix the spec directly. Re-run
the checklist. Most failures are fixable without user input
(adding missing error criteria, removing vague adjectives,
adding Out of Scope items).

**If points still fail (iteration 2):** Fix what you can.
Document remaining issues in the spec's Notes section with
rationale for why they couldn't be resolved. Mark spec status
as `Ready-with-warnings`. Proceed to Phase 5 with a warning
in the handoff summary.

**Do not iterate more than twice.** Diminishing returns. The
remaining issues are likely ambiguities that need human input
during TDD implementation, not spec-level resolution.
