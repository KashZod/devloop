# Clarification Taxonomy

Structured categories for detecting ambiguity in feature specs.
Use this during Phase 2 (to identify edge cases and mark ambiguities)
and Phase 3 (to prioritize clarification questions).

For each category, assess: **Clear** | **Partial** | **Missing**

**Category filtering:** Not all 9 categories apply to every project.
Skip categories that are structurally irrelevant, e.g., skip
"Users & Roles" for single-user CLI tools, skip "Interaction Flow"
for non-interactive content packages. Mark skipped categories as
"N/A" rather than "Clear" to distinguish "doesn't apply" from
"assessed and satisfied."

Categories marked Partial or Missing are candidates for
`[NEEDS CLARIFICATION]` markers. Only promote to a marker when:
- The ambiguity would materially change implementation or tests
- No reasonable default exists
- Multiple interpretations have materially different implications

Make informed guesses for everything else and document in Assumptions.

---

## Categories

### 1. Scope & Boundaries

What is included in this feature? What is explicitly excluded?

**Check for:**
- Feature boundaries (where this feature starts and stops)
- MVP vs future work (what's P1 vs deferred)
- Size/volume limits (max items, file sizes, user counts)
- Version boundaries (does this replace existing behavior?)
- Behavioral migration (what happens to users of the old behavior?)
- Feature flags (gradual rollout or all-at-once?)

**Reasonable defaults:** If not specified, assume all-at-once
rollout, no feature flags, standard volume for the project type.

### 2. Users & Roles

Who uses this feature? Does behavior differ by user type?

**Check for:**
- Primary user persona (who benefits most?)
- Permission levels (admin, user, guest, anonymous)
- Multi-tenancy (data isolation between users/orgs)
- Authentication requirements (logged in vs public)

**Reasonable defaults:** If not specified, assume single user type,
authentication required, no multi-tenancy.

### 3. Data & State

What data does this feature create, read, update, or delete?

**Check for:**
- Entities and relationships (what data objects are involved?)
- Required vs optional fields
- State transitions (draft -> published -> archived)
- Data volume assumptions (hundreds vs millions of records)
- Data retention and cleanup
- Migration needs (does existing data need transformation?)

**Reasonable defaults:** If not specified, assume standard CRUD,
industry-standard retention, no migration needed.

### 4. Interaction Flow

What is the primary user journey?

**Check for:**
- Happy path (the main user flow from trigger to completion)
- Entry points (how does the user reach this feature?)
- Multi-step flows (can they be interrupted and resumed?)
- Loading states (what does the user see while waiting?)
- Empty states (what does the user see with no data?)
- Confirmation steps (destructive actions need confirmation?)

**Reasonable defaults:** If not specified, assume single entry
point, loading spinner, "no items yet" empty state, confirmation
for destructive actions.

### 5. Error Handling

What happens when things go wrong?

**Check for:**
- Input validation errors (what's invalid? how communicated?)
- Network/service failures (timeout, 500, offline)
- Permission denied (unauthorized access attempts)
- Partial failure (3 of 5 items succeed, what happens?)
- Retry behavior (automatic? manual? how many times?)
- Degraded mode (can the feature work with reduced capability?)

**Reasonable defaults:** If not specified, assume user-friendly
error messages, manual retry, no degraded mode.

### 6. Edge Cases & Boundaries

What boundary conditions and concurrent scenarios exist?

**Check for:**
- Zero/one/max values (empty list, single item, overflow)
- Null/missing/malformed data
- Concurrent operations (two users editing the same thing)
- Race conditions (rapid clicks, parallel requests)
- Timezone and locale sensitivity
- Unicode, emoji, RTL text in user input
- Long strings, large files

**Reasonable defaults:** If not specified, assume reasonable
max limits for the platform, no special concurrent handling
beyond standard framework protections.

### 7. Integration & Dependencies

What existing systems does this feature interact with?

**Check for:**
- External services/APIs (what happens if they're down?)
- Existing features affected (does this change existing behavior?)
- Data format contracts (JSON schema, protobuf, XML)
- Versioning (API version, protocol version)
- Timeouts and circuit breakers
- Backward compatibility (old clients, old data)

**Reasonable defaults:** If not specified, assume current API
version, standard timeout (30s), no backward compatibility
concerns unless the project has existing consumers.

### 8. Non-Functional Concerns

What quality attributes matter beyond correctness?

**Performance:**
- Response time targets (P50, P95, P99 latency)
- Throughput requirements (requests/sec, items processed/sec)
- Resource constraints (memory, CPU, battery, bandwidth)

**Security:**
- Authentication and authorization requirements
- Data protection (encryption at rest, in transit)
- Input sanitization (injection prevention)
- Audit trail (who did what, when)

**Accessibility:**
- Screen reader support (ARIA labels, semantic HTML)
- Keyboard navigation
- Color contrast requirements
- WCAG compliance level (A, AA, AAA)

**Observability:**
- Logging (what events, what severity levels)
- Metrics (what to measure, what thresholds to alert on)
- Tracing (distributed tracing across services)

**Reasonable defaults:** If not specified, assume standard
performance for the platform, basic auth, no specific WCAG
target, standard logging at info/error levels.

### 9. Domain-Specific Concerns

Project-specific patterns from `.devloop/domain.md`.

**Check for:**
- Domain-specific edge cases listed in .devloop/domain.md
- Industry standards or regulations that apply
- Known domain pitfalls from the project's Lessons Learned
- Patterns that every feature in this project must address

This category has no reasonable defaults, it's entirely
project-specific. If .devloop/domain.md doesn't exist or has no
domain concerns listed, skip this category.

---

## Prioritization

When multiple categories have ambiguities, promote to
`[NEEDS CLARIFICATION]` in this priority order:

1. **Scope & Boundaries**, Wrong scope = wasted implementation
2. **Data & State**, Wrong model = expensive rework
3. **Error Handling**, Missing error handling = production incidents
4. **Users & Roles**, Wrong permissions = security issues
5. **Edge Cases**, Missing edge cases = bugs found later
6. **Integration**, Missed dependencies = broken features
7. **Interaction Flow**, Wrong flow = poor UX
8. **Non-Functional**, Missing NFRs = tech debt
9. **Domain-Specific**, Context-dependent priority

Use this order when selecting which ambiguities to promote to
`[NEEDS CLARIFICATION]` (max 5) and which to resolve with
reasonable defaults documented in Assumptions.

---

## Question Design

When promoting an ambiguity to a clarification question:

- **Multiple-choice format** (2-5 options) as a markdown table
- **Always include a recommendation** with reasoning above the table
- **Options must be mutually exclusive**, no overlapping choices
- **Include a "Custom" row** if free-form answer makes sense
- **One question at a time**, never reveal upcoming questions
- **State the impact**, why this question matters for the spec

Example:

```markdown
**Context:** The spec says "users can export data" but doesn't
specify the format.

**Recommended:** Option A, CSV is the most universally supported
format and doesn't require additional libraries.

| Option | Description | Implications |
|---|---|---|
| A | CSV export | Simple, universal, no formatting |
| B | JSON export | Structured, good for re-import |
| C | Both CSV and JSON | More work, covers more use cases |

Reply with option letter, "yes" to accept recommendation, or
your own answer.
```
