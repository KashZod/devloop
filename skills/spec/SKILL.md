---
name: spec
description: "Structured specification process: explores code, generates user stories with testable acceptance criteria, resolves ambiguities through interactive clarification, validates completeness, and outputs a lightweight spec. Use before /plan to clarify WHAT to build."
argument-hint: "[description of feature, fix, or change]"
effort: high
---

# Feature Specification Process

Create a specification for the following: $ARGUMENTS

Specifications clarify WHAT to build before implementation begins.
Instead of discovering ambiguity mid-implementation (expensive),
surface it upfront through structured exploration and clarification,
where resolving it costs a question instead of a rewrite.

## Mapping to the Explore -> Plan -> Code Loop

| Workflow Phase | Spec Phase | What Happens |
|---|---|---|
| **Explore** | Phase 1: Explore | Read files, understand context, check `.devloop/domain.md` |
| **Plan** | Phase 2: Specify | User stories, acceptance criteria, edge cases |
| **Plan** | Phase 3: Clarify | Interactive disambiguation (max 5 questions) |
| **Plan** | Phase 4: Validate | 8-point spec quality checklist |
| **Plan** | Phase 5: Handoff | Summary report, suggest /plan |

## When to Use This Process

| Scope | Approach |
|---|---|
| Trivial (typo, config, rename) | Don't use this skill -- just do it directly |
| Small (well-understood, single concern) | Quick spec shortcut (skip clarification) |
| Medium (multi-concern, some ambiguity) | Full process |
| Large (cross-cutting, unfamiliar domain) | Full process, thorough clarification |

**Quick spec shortcut:** For small well-understood changes with
no domain ambiguity, collapse to: Explore -> Specify -> Validate
-> Handoff. Skip clarification entirely. Use when the feature can
be described in one sentence and has no competing interpretations.

**Scope negotiation:** If the request contains 3+ distinct features,
recommend splitting into separate specs before proceeding. Each spec
should cover one coherent feature with independent user value.

**Product vs feature:** If the request describes an entire product
or system (multiple independent capabilities, separate components,
its own installation story), treat it as a product-level spec:

- One user story per major capability (not per implementation task)
- Acceptance criteria verify capability, not component details
- Implementation chunking goes in Notes or during TDD, not as
  separate specs
- Spec size will exceed the standard guideline, this is expected

If a product spec exceeds 12 stories, consider splitting into a
product spec (overview) + separate feature specs (details).

Product specs with interacting capabilities need explicit
interface contracts, file paths, data formats, handoff
expectations. Document these in Assumptions or a dedicated
section. Without them, components may diverge on implicit
conventions that break silently at integration time.

## Supporting Files

Load these on demand, not all upfront:

| File | When to Load |
|---|---|
| [spec-template.md](references/spec-template.md) | Phase 2, when generating the spec |
| [clarification-taxonomy.md](references/clarification-taxonomy.md) | Phase 2 (scanning) and Phase 3 (questions) |
| [validation-checklist.md](references/validation-checklist.md) | Phase 4 (validation) |

## Process Overview

```text
Phase 1: Explore
Phase 2: Specify
Phase 3: Clarify (interactive, skippable)
Phase 4: Validate
Phase 5: Handoff
```

Each phase must complete before the next begins.
Phase 3 is skipped if no ambiguities are found.

---

## Phase 1: Explore

### 1.1 Understand the Request

- Read the user's feature description carefully
- Identify: new feature, enhancement, bug fix, behavior change,
  integration, or workflow change
- Extract key concepts: actors, actions, data, constraints, triggers
- Note initial assumptions about scope and intent

### 1.2 Explore Current Code

- Read files in the affected area (focus on files mentioned in the
  request + 1 layer of direct dependencies)
- Trace the data flow through the application layers
- Identify existing patterns, utilities, and conventions to reference
- Note what already exists, don't spec what you can grep

**Greenfield projects:** If the codebase doesn't exist yet, explore
the inputs that define WHAT to build: analysis docs, design docs,
reference materials, domain knowledge files, and similar projects.
The goal is the same, understand context before specifying, but
the context lives in documents rather than code.

**Context tip:** Steps 1.2 and 1.3 are independent. If your harness
supports parallel tool calls or subagents, run them concurrently when
the codebase is large or unfamiliar; otherwise run them sequentially,
that is the default and is correct.

### 1.3 Read Project Context

- Load the domain config for domain context, architecture overview,
  existing patterns, and domain-specific concerns. Resolve it in this
  order: `.devloop/domain.md` in the project root, else proceed
  generically
- These inform edge case detection, affected component identification,
  and project-specific validation in Phase 4
- `domain.md` holds only domain knowledge. The one operational path `/spec`
  needs, the spec directory, lives in `.devloop/config.md` and is read where
  it's used (Phase 1.5 and 2.7)
- If neither file exists or the file contains only template
  placeholders (`YOUR_*_HERE`), proceed without it, the generic
  taxonomy categories still apply
- If the project clearly needs a domain config (complex domain,
  multiple conventions, domain-specific concerns), note this in
  the spec's Notes section as a recommendation. Don't block the
  spec process, create the spec first, suggest `.devloop/domain.md` after

### 1.4 Identify Affected Components

- List files and modules that will likely change
- Note their role in the architecture (data layer, domain, UI, etc.)
- This becomes the spec's "Affected Components" section and later
  feeds into TDD chunk decomposition

### 1.5 Check for Existing Spec

- Check the spec directory (the spec-directory setting in
  `.devloop/config.md`, default `docs/specs/`) for an existing spec
  file matching this feature
- If found, load it and show a summary to the user
- Ask: "A spec already exists for this feature. Update it, or
  start fresh?"
  - **Update:** Preserve Clarifications history, bump `spec-version`,
    revise stories and criteria based on new request
  - **Fresh:** Archive old spec with `.bak` suffix (overwrite any
    existing `.bak`), generate new one

---

## Phase 2: Specify

### 2.1 Load Spec Template

Read [spec-template.md](references/spec-template.md) for the
output format. Use its section structure and frontmatter schema.

### 2.2 Generate User Stories

For each distinct user-facing behavior:

- Write a user story: **As a** <role>, **I want** <goal>,
  **so that** <benefit>
- Assign priority: P1 (must-have), P2 (should-have), P3 (nice-to-have)
- Include a "Why P_" line justifying the priority
- Ensure P1 stories form a coherent MVP that delivers value alone
- Each story should be independently implementable and testable

### 2.3 Write Acceptance Criteria

For each user story, write testable acceptance criteria:

- Use Given/When/Then format for every criterion
- P1 stories need both happy-path and error-path criteria
- P2/P3 stories need at least one criterion each
- Scan the domain config's Quality Standards while writing, criteria
  categories like accessibility are cheaper to add now than to
  discover in Phase 4 validation
- See spec-template.md §Acceptance Criteria for complexity hints
  and specificity guidelines
- **Depth target:** Criteria should be specific enough to write a
  test from, but not so specific that they dictate implementation.
  "Then the output contains a section for each finding" is testable.
  "Then the template uses a Handlebars {{#each}} loop" is
  implementation. When in doubt, describe the observable outcome

### 2.4 Identify Edge Cases

Load [clarification-taxonomy.md](references/clarification-taxonomy.md).
Scan all 9 categories against the feature:

- For each category, assess: Clear / Partial / Missing
- Document edge cases discovered in the spec's Edge Cases section
- Tag each edge case with its taxonomy category: `[Category N]`
- At minimum for P1 features: empty state, error state, boundary values
- Check the domain config's domain-specific concerns (Category 9)

### 2.5 Document Assumptions

Record reasonable defaults for unspecified details. See
spec-template.md §Assumptions for guidelines. Use the taxonomy's
"Reasonable defaults" as a guide.

### 2.6 Mark Ambiguities

For categories marked Partial or Missing where the ambiguity
materially impacts the spec:

- Add `[NEEDS CLARIFICATION: <specific question>]` markers
- **Maximum 5 markers** across the entire spec
- Prioritize by impact, see
  [clarification-taxonomy.md §Prioritization](references/clarification-taxonomy.md)
  for the full ranking
- Make informed guesses for everything else (document in Assumptions)
- Write the "Out of Scope" section, at least one item for medium+
  features

### 2.7 Write Spec File

- Create the spec directory if it doesn't exist
- Write the spec to the configured location (the spec-directory
  setting in `.devloop/config.md`, default `docs/specs/<feature-name>.md`)
  using kebab-case for the filename
- Include all sections from the template
- Set frontmatter status to `Draft`
- **Size check:** Standard features should target ~80-150 lines
  before Clarifications. If well over, reconsider scope,
  it may be multiple features. Apply scope negotiation (see §When
  to Use). Product-level specs (see §Product vs feature)
  exceed this, up to ~300 lines is expected for products with
  6-12 user stories

---

## Phase 3: Clarify

Skip this phase if no `[NEEDS CLARIFICATION]` markers exist.
Report: "No critical ambiguities detected. Skipping clarification."

### 3.1 Prioritize Questions

From the `[NEEDS CLARIFICATION]` markers:

- Rank by (impact x uncertainty), highest first
- Select up to 5 for the question queue
- Each question must materially affect implementation or testing
- Never reveal upcoming questions, one at a time only

### 3.2 Interactive Questioning Loop

For each question in the queue:

1. **State context:** Quote the relevant spec section
2. **Recommend an answer:** Based on codebase patterns, project
   context, and best practices. Format:
   `**Recommended:** Option X -- <one sentence reasoning>`
3. **Present options** as a markdown table:

   | Option | Description | Implications |
   |---|---|---|
   | A | ... | ... |
   | B | ... | ... |
   | C | ... | ... |

4. **Accept response:** User replies with:
   - Option letter (e.g., "A")
   - "yes" or "recommended" to accept the recommendation
   - A custom short answer
5. **Update the spec immediately** after each answer:
   - Replace the `[NEEDS CLARIFICATION]` marker with the answer
   - Add to Clarifications section: `- Q: <question> -> A: <answer>`
   - Save the file (atomic update)
6. **Handle scope changes:** If the user's answer introduces new
   scope (new scenarios, new capabilities, new actors), update
   affected stories and criteria before proceeding. Treat the
   answer as a mini re-spec of the affected section, don't just
   record it and move on
7. **Proceed to next question** or stop

### 3.3 Stop Conditions

Stop asking questions when:

- All markers are resolved
- User signals completion ("done", "skip", "proceed", "no more")
- 5 questions have been asked
- Remaining ambiguities are low-impact

### 3.4 Full Abort

If the user says "wrong approach", "start over", or similar:

- Delete the spec file
- Report: "Spec discarded. Re-run /spec with a revised description."
- Stop the process

### 3.5 Deferred Markers

If questions remain after early termination, replace unresolved
markers with: `[DEFERRED: not clarified -- <brief reason>]`

---

## Phase 4: Validate

### 4.1 Load Validation Checklist

Read [validation-checklist.md](references/validation-checklist.md)
for the 8-point criteria.

### 4.2 Run 8-Point Check

For each point, verify with specific evidence from the spec:

1. **Testability**, Every Given/When/Then maps to a test assertion
2. **Completeness**, Every story has criteria; every P1 has error paths
3. **Clarity**, No vague adjectives without measurable targets
4. **Scope**, Out of Scope section exists and is non-empty
5. **Independence**, P1 stories deliver standalone value
6. **Priority**, P1/P2/P3 assigned; P1 set forms coherent MVP
7. **Edge Cases**, Failure modes identified per P1 story
8. **Resolution**, No unresolved `[NEEDS CLARIFICATION]` markers

### 4.3 Project-Specific Validation

Using the domain config (already loaded in Phase 1), run the
project-specific checks per validation-checklist.md
§Project-Specific Validation.

### 4.4 Fix Issues

If points fail, fix the spec directly and re-run the checklist.
See validation-checklist.md §Handling Failures for the iteration
limit and fallback behavior.

### 4.5 Mark Spec Ready

Update frontmatter status:
- All points pass: `status: Ready`
- Some warnings remain: `status: Ready-with-warnings`

---

## Phase 5: Handoff

### 5.1 Summary Report

Output to the user:

- Spec file path
- Number of user stories by priority (P1/P2/P3)
- Number of acceptance criteria total
- Number of clarifications resolved (if Phase 3 ran)
- Validation result (Ready or Ready-with-warnings)
- Any deferred ambiguities or validation warnings

### 5.2 Downstream Integration

Explain how the spec feeds `/plan` (which decomposes it into chunks) and
then `/implement` (which builds them):

| Spec Section | Consumed by | How to Use |
|---|---|---|
| User Stories | /plan Phase 1 (Analysis) | Scope of what to explore |
| Affected Components | /plan Phases 1-2 | Starting point for chunk decomposition |
| Assumptions | /plan Phase 1 (Analysis) | Context for architecture decisions |
| Acceptance Criteria | /plan (chunk criteria), /implement (tests) | Become per-chunk criteria, then failing tests |
| Edge Cases | /implement Phase 2 (TDD Cycle) | Additional test cases |

### 5.3 Suggest Next Step

```
Next: /plan <feature> (spec: docs/specs/<feature>.md)
```

If the spec has warnings, note them:
"The spec has N unresolved warnings, review the Notes section
before planning."

**Non-code projects:** If the spec covers content, configuration,
or documentation (no executable code), adapt the mapping:
- "Write these as failing tests" → "Write these as validation
  criteria or review checks"
- "Starting point for chunks" → "Starting point for content chunks"
- Suggest a structured build order rather than `/plan` + `/implement`

---

## Post-Validation Pivot

If the user challenges a fundamental assumption after the spec is
marked Ready (e.g., changing the architecture, switching platforms,
redefining scope), handle it as a controlled re-spec:

1. **Acknowledge the pivot**, don't defend the existing spec
2. **Assess impact**, which stories survive the pivot vs need rewriting?
3. **Bump `spec-version`** and update the frontmatter
4. **Rewrite affected sections**, stories, criteria, affected components
5. **Re-run Phase 4 validation** on the updated spec
6. **Log the pivot** in Clarifications: `- Pivot: <old> → <new> (<reason>)`

This is cheaper than starting fresh because unaffected stories,
edge cases, and clarifications are preserved.

This is also the landing point when `/plan` or `/implement` discovers
mid-build that an acceptance *criterion itself* was wrong: they route the
user back here to fix the criterion rather than inventing the fix
downstream, then re-run `/plan` so §3.1 merges the revised spec into the
existing tracker and `review-plan` re-gates.

---

## Lessons Learned (Apply Every Time)

1. **Acceptance Criteria That Can't Fail Aren't Criteria** -
   If a Given/When/Then always passes regardless of implementation,
   it tests nothing. "System handles errors" is not testable.
   "When API returns 500, user sees error banner with retry button" is
2. **Edge Cases Come from the Domain, Not the Feature** -
   The most dangerous edge cases aren't in the feature itself, they're
   in how the feature interacts with existing domain rules. A "delete"
   feature seems simple until you consider: shared items, items in
   progress, items with dependencies, undo expectations, sync conflicts
3. **The Spec Is Not the Plan** -
   Specs define WHAT and WHY. Plans define HOW. If you catch yourself
   writing framework names, file paths, or algorithm choices, stop,
   those belong in TDD, not here
4. **Three Clarifications Beat Ten Assumptions** -
   A single well-chosen clarification question that resolves a P1 scope
   ambiguity saves more rework than ten documented assumptions. The
   max-5 limit forces prioritization, use it on what matters most
5. **"Simple" Features Hide Domain Complexity** -
   "Add search" sounds simple until you consider: fuzzy matching,
   pagination, permissions filtering, empty states, indexing strategy.
   The taxonomy exists to surface this complexity before implementation
6. **User Stories Should Survive a Pivot** -
   If changing the tech stack invalidates your user stories, they
   contain implementation details. "User finds events by keyword"
   survives a rewrite. "User calls GET /api/search" doesn't
7. **Don't Spec What You Can Grep** -
   If the codebase already implements a pattern, reference it instead
   of re-specifying it. "Follow the same pattern as OrderService"
   is more accurate than re-describing what OrderService does
8. **Scope Creep Starts in the Spec** -
   Every "while we're at it" in a spec doubles implementation time.
   Be aggressive about P2/P3 classification. Ship P1, then spec P2
   separately. The Out of Scope section is your best defense
9. **The Best Specs Are Boring** -
   A good spec reads like a checklist, not a narrative. If it's
   exciting to read, it probably contains opinions instead of criteria.
   Save the creativity for the code
10. **Check Quality Standards During Specification, Not Just Validation** -
    Phase 4 catches missing criteria categories (accessibility, offline
    behavior) but fixing them there costs a validation iteration. Scan
    the domain config's Quality Standards during Phase 2.3 while writing
    criteria, it's cheaper to include them upfront than to discover them late

---

## Session Scope

Specs complete in one session. There is no tracker or session
resumption mechanism. To revisit a feature's spec later, re-run
`/spec`, Phase 1.5 detects the existing file and offers update
or fresh start.

---

## Commit Guidance

Do not commit proactively. Wait for the user to request it.
Refer to `.devloop/config.md` for project-specific commit conventions
(author, message format, trailers).
