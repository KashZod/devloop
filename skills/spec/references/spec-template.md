# Spec Template

This is the output format for spec files. The `/spec` skill writes
specs to the location configured in `PROJECT.md` (default:
`docs/specs/<feature-name>.md`). Use kebab-case for filenames.

Load this file during Phase 2 (Specify) to understand the required
structure.

---

## Template

```markdown
---
feature: "<Feature Name>"
status: Draft
created: YYYY-MM-DD
source: "<the user's original request text>"
spec-version: 1
---

# Feature: <Feature Name>

## Overview

<2-3 sentences: WHAT this feature does and WHY it matters.
Focus on user value. No implementation details, no frameworks,
no file paths, no algorithms.>

## User Stories

### US1: <Story Title> [P1]

**As a** <role>, **I want** <goal>, **so that** <benefit>.

**Why P1:** <one sentence justifying this priority>

**Acceptance Criteria:**
1. **Given** <precondition>, **When** <action>, **Then** <outcome> (1 test)
2. **Given** <precondition>, **When** <error condition>, **Then** <error outcome> (1 test)
3. **Given** <varying inputs>, **When** <action>, **Then** <expected outcomes> (parameterized)

### US2: <Story Title> [P2]

**As a** <role>, **I want** <goal>, **so that** <benefit>.

**Why P2:** <one sentence justifying this priority>

**Acceptance Criteria:**
1. **Given** <precondition>, **When** <action>, **Then** <outcome> (1 test)

## Edge Cases

- <Edge case 1: scenario and expected behavior> [Category N]
- <Edge case 2: scenario and expected behavior> [Category N]

## Out of Scope

- <Explicitly excluded behavior 1>
- <Explicitly excluded behavior 2>

## Assumptions

- <Reasonable default chosen, with rationale>
- <Another assumption, with what would change if wrong>

## Affected Components

| File / Module | Role | Impact |
|---|---|---|
| <path/to/file> | <what it does> | <what changes> |
| <path/to/module> | <what it does> | <what changes> |

## Downstream Mapping

| Spec Section | Consumed by | How to Use |
|---|---|---|
| User Stories | /plan Phase 1 (Analysis) | Scope of what to explore |
| Affected Components | /plan Phases 1-2 | Starting point for chunk decomposition |
| Assumptions | /plan Phase 1 (Analysis) | Context for architecture decisions |
| Acceptance Criteria | /plan (chunk criteria), /implement (tests) | Become per-chunk criteria, then failing tests |
| Edge Cases | /implement Phase 2 (TDD Cycle) | Additional test cases |

## Clarifications

### Session YYYY-MM-DD

- Q: <question> -> A: <resolved answer>

## Notes

<Validation warnings, deferred items, or anything that doesn't
fit above. Remove this section if empty.>
```

---

## Section Guidelines

### Frontmatter

```yaml
---
feature: "User Search"        # Human-readable feature name
status: Draft                  # Draft | Ready | Ready-with-warnings
created: 2026-03-26            # Date spec was first created
source: "add search to..."    # The user's original $ARGUMENTS
spec-version: 1                # Bumped when spec is re-run/updated
---
```

- `status` transitions: Draft -> Ready (after validation passes)
  or Draft -> Ready-with-warnings (if validation has unresolved items)
- `spec-version` increments when `/spec` is re-run with "update"

### Overview

- Focus on user value, not technical approach
- One sentence for WHAT, one for WHY
- No framework names, no file paths, no API endpoints

### User Stories

- **P1:** Must-have for the feature to be useful
- **P2:** Important but the feature works without it
- **P3:** Nice-to-have, could be a separate follow-up spec
- Each story should be independently implementable and testable
- Avoid stories that are implementation tasks disguised as user needs
- Include a "Why P_" line to make priority reasoning explicit

### Acceptance Criteria

- Given/When/Then format keeps each criterion testable
- Each criterion should map to one or more tests
- Include both happy path and error scenarios for P1 stories
- Be specific: "error message appears" is too vague,
  "red banner shows 'Failed to save. Retry?'" is testable
- Hint at test complexity in parentheses:
  - `(1 test)`, single assertion
  - `(parameterized)`, multiple input/output combinations
  - `(integration)`, requires external dependency or multi-step setup
- Avoid criteria that test implementation ("database row is created");
  test behavior ("user sees the new item in their list")

### Edge Cases

- Focus on scenarios that would break a naive implementation
- Cross-reference taxonomy categories in brackets: `[Category 6]`
- At minimum for P1 features: empty state, error state, boundary values
- Domain-specific concerns from PROJECT.md get their own items

### Out of Scope

- Explicitly state what this feature does NOT do
- Prevents scope creep during TDD implementation
- "Out of scope" items are candidates for future specs
- Include at least one item for medium+ features

### Assumptions

- Only document non-obvious assumptions
- Each should include: what was assumed, why, and what changes
  if the assumption is wrong
- Don't document obvious defaults ("errors show error messages")

### Affected Components

- File paths and modules from Phase 1 exploration
- Brief role description so /plan can skip redundant exploration
- Impact column describes what will change, not how

### Downstream Mapping

- Always include this section, it's the bridge to planning and build
- Maps each spec section to the /plan or /implement phase that consumes it
- The /plan skill references this table to know where to look
- **Non-code projects:** If the deliverable is content, config, or
  documentation rather than executable code, adapt the mapping:
  replace "failing tests" with "validation criteria or review checks"
  and "chunk decomposition" with "content chunking." Suggest a
  structured build order rather than referencing `/plan` + `/implement`
  directly

### Clarifications

- Added during Phase 3 as questions are resolved
- One `### Session YYYY-MM-DD` heading per `/spec` invocation
- Format: `- Q: <question> -> A: <answer>`
- Preserved across re-runs (when user chooses "update")

### Notes

- Validation warnings from Phase 4
- Deferred items (ambiguities that weren't worth clarifying)
- Remove this section entirely if empty, don't leave an empty heading
