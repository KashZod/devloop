# Chunk Decomposition Guide

How to break a feature into implementation chunks for TDD workflow.

---

## Principles

1. **Each chunk is independently testable** (or explicitly BATCH)
2. **Smallest unit that makes sense** - don't over-chunk wiring
3. **Dependencies are explicit** - never start a chunk before its deps are complete
4. **Resume-friendly** - someone (or a future session) can pick up from the tracker

---

## Chunk Categories

### Data Layer Chunks
- New data classes, entities, models, schemas
- Repository/service interface + implementation
- Test double implementation (fakes, stubs)
- **Test strategy**: Unit tests for computed properties, conversion helpers

### Domain / Business Logic Chunks
- New domain models (sealed types, data classes, enums)
- Extension functions on domain types
- Coordinator/service method additions
- **Test strategy**: Unit tests for logic, integration tests for orchestration

### UI Layer Chunks
- New components, pages, views
- ViewModel / controller state changes
- Screen wiring (click handlers, navigation, routing)
- **Test strategy**: Build verification + manual testing (unless UI test infra exists)

### Migration Chunks (BATCH)
- Type changes that ripple through multiple files
- Shared type field changes
- Return type changes on shared interfaces
- **Test strategy**: Update breaking assertions, build + full suite

### Verification Chunks
- Final regression + quality check
- Depends on ALL prior chunks
- **Test strategy**: Full suite, build, lint, 8-point quality checklist

---

## Decomposition Process

### Step 1: Identify the Data Flow
Trace the feature through the application layers:
```text
User action
  -> UI handler
    -> Domain service / use case
      -> Data layer (DB, API, file)
```

### Step 2: Identify New Code vs Modified Code
- New files: need creation + test files
- Modified files: need careful diffing to avoid breaking existing behavior

### Step 3: Group by Compilation Unit
If changing file A requires changing file B to compile:
- Put A and B in the same chunk (BATCH)
- Or introduce an intermediate interface so they can change independently

### Step 4: Order by Dependencies
```text
Data layer (no deps) -> Domain layer -> UI layer -> Verification
```

### Step 5: Write Acceptance Criteria

For each chunk, define **acceptance criteria**, explicit pass/fail
conditions that determine whether the chunk is done. These are the
"sprint contract" agreed before implementation begins.

Good acceptance criteria are:
- **Testable**, each criterion maps to a test assertion or verifiable output
- **Specific**, "search returns filtered results" not "search works"
- **Complete**, cover happy path, edge cases, and error cases

A resuming session reads `files_create`/`files_modify` (where),
`name` (what), `tdd` (test conditions), and `acceptance_criteria`
(pass/fail) directly. Use the optional `notes` field only for hints
those required fields can't carry, typically a `PATTERN: file:function`
reference or a `DO NOT: ...` pitfall.

---

## Example: Share Feature

### Chunk 1: Domain Logic (data layer)
```json
{
  "id": 1,
  "name": "buildShareText and toDuplicate helpers",
  "acceptance_criteria": [
    "buildShareText returns formatted string with title and date",
    "buildShareText includes location when present, omits when empty",
    "toDuplicate copies all fields except generates new ID",
    "toDuplicate preserves timed format with start/end times"
  ],
  "files_create": [],
  "files_modify": ["src/domain/model/Item.ts"],
  "test_files": ["src/domain/model/Item.test.ts"],
  "tdd": "Write 6 tests: property mapping, default ID, date format, timed format, location present, location empty. Run -> compile error -> implement -> pass.",
  "depends_on": []
}
```

### Chunk 2: UI Components (depends on chunk 1)
```json
{
  "id": 2,
  "name": "Share button in QuickView",
  "acceptance_criteria": [
    "Share button renders in QuickView detail panel",
    "Button click triggers onShare callback with current item"
  ],
  "files_create": [],
  "files_modify": ["src/ui/components/QuickView.tsx"],
  "test_files": [],
  "tdd": "No unit test (UI: rendering only, pure callback threading, no hoisted state or branching effects). Verified by build.",
  "depends_on": [1]
}
```

> If this chunk introduced hoisted state, a `useEffect`/`LaunchedEffect`,
> or input transformation, it would be a UI: state-holder chunk and need a
> test on the extracted holder. See SKILL.md §3.1 state-holder detection.

### Chunk 3: Wiring (depends on chunks 1 and 2)
```json
{
  "id": 3,
  "name": "App-level callback wiring",
  "acceptance_criteria": [
    "Share callback connected from App to QuickView",
    "Share action calls buildShareText and opens share dialog"
  ],
  "files_create": [],
  "files_modify": ["src/App.tsx"],
  "test_files": [],
  "tdd": "No unit test (wiring). Verified by build + full suite regression.",
  "depends_on": [1, 2]
}
```

### Chunk 4: Regression + Quality
```json
{
  "id": 4,
  "name": "Full Regression + Quality Verification",
  "acceptance_criteria": [
    "Full test suite passes with no new failures",
    "Build compiles without errors or new warnings",
    "8-point quality checklist completed"
  ],
  "files_create": [],
  "files_modify": [],
  "test_files": [],
  "tdd": "Run full test suite + build. Run 8-point quality checklist.",
  "depends_on": [1, 2, 3]
}
```

---

## Anti-Patterns

### Over-Chunking
**Bad**: 10 chunks for a 3-file change
**Good**: 1-3 chunks that map to natural boundaries

### Missing BATCH Annotation
**Bad**: Chunk A changes shared type, Chunk B changes consumer
**Good**: Single BATCH chunk that changes both together

### Vague Chunk Names
**Bad**: `name: "Implement the feature"`
**Good**: `name: "buildShareText and toDuplicate helpers"`, paired with concrete `files_modify`, `tdd`, and (when needed) a `notes: "PATTERN: formatEvent() in EventService.ts:42. DO NOT change return type of getItems()."`

### Testing UI with Unit Tests
**Bad**: Writing DOM/render tests for a simple layout change
**Good**: Build verification + manual testing for pure UI, unit tests for extracted logic
