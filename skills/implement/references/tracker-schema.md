# JSON Tracker Schema

The tracker file is the single source of truth for feature implementation progress.
It is a local working file - not committed to version control.

**Filename convention:** Trackers use `impl-tracker-<feature>.json`.

---

## Schema

```json
{
  "phase": "Human-readable phase/feature name",
  "issue": "GitHub/GitLab issue reference (e.g., org/repo#76)",
  "design_doc": "path/to/design-doc.md (optional)",
  "plan_doc": "path/to/plan.md (optional)",
  "plan_review": "PASS",
  "chunks": [
    {
      "id": 1,
      "name": "Short descriptive name",
      "status": "pending",
      "files_create": ["path/to/NewFile.ext"],
      "files_modify": ["path/to/ExistingFile.ext"],
      "test_files": ["path/to/TestFile.ext"],
      "acceptance_criteria": ["Criterion 1", "Criterion 2"],
      "tdd": "Write test for X. Run -> fail -> implement -> pass.",
      "depends_on": [],
      "notes": "Optional notes: decisions, constraints, pattern to follow (file:function), and pitfalls to avoid."
    }
  ],
  "quality_verification": {
    "completeness": "Summary of completeness check",
    "correctness": "Summary of correctness check",
    "gaps_functional": "Summary of functional gaps check",
    "standards": "Summary of standards check",
    "regression": "Summary of regression check",
    "robustness": "Summary of robustness check",
    "gaps_architectural": "Summary of architectural gaps check",
    "blindspots": "Summary of blindspots check"
  }
}
```

---

## Field Definitions

### Top-level Fields

| Field | Required | Description |
|-------|----------|-------------|
| `phase` | Yes | Human-readable name for the feature or phase |
| `issue` | Yes | Issue tracker reference |
| `design_doc` | No | Path to design document |
| `plan_doc` | No | Path to plan document |
| `plan_review` | No | Review-plan gate verdict: `"PASS"`, `"PASS-WITH-WARNINGS"`, or `"FAIL"`. Set in Phase 2.5. Session resumption checks this before Phase 3 |
| `chunks` | Yes | Array of implementation chunks |
| `quality_verification` | No | Filled after all chunks complete |

### Chunk Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Integer, sequential starting at 1 |
| `name` | Yes | Short descriptive name (5-10 words) |
| `status` | Yes | `pending`, `in_progress`, `complete`, or `error` |
| `files_create` | Yes | Paths of new files to create (empty array if none) |
| `files_modify` | Yes | Paths of existing files to modify (empty array if none) |
| `test_files` | Yes | Paths of test files (new or modified) |
| `acceptance_criteria` | Yes | Array of testable pass/fail conditions for this chunk |
| `tdd` | Yes | TDD instructions: what to test, expected fail, then pass |
| `depends_on` | Yes | Array of chunk IDs that must be `complete` first |
| `notes` | No | Optional decisions, constraints, pattern hints (file:function), and pitfalls. The chunk's `name` + `files_create`/`files_modify` + `tdd` already convey the rest of what a resuming session needs |

---

## Status Transitions

```text
pending ──> in_progress ──> complete
                │
                └──> error (with notes explaining the issue)
```

Rules:
- Set `in_progress` BEFORE starting work (not after)
- Set `complete` only after tests pass and tracker is verified
- Set `error` if blocked; add notes explaining what went wrong
- Never skip `in_progress` (helps session resumption)

---

## Resuming a Chunk

A resuming session reads the chunk's required fields directly:
`name` (what), `files_create` + `files_modify` (where), `tdd` (test
conditions), `acceptance_criteria` (pass/fail). Add a `notes` entry
when there's something a resuming session can't infer from those,
typically a `PATTERN: file:function` hint or a `DO NOT: ...` pitfall.

```json
{
  "notes": "PATTERN: follow getItemsByDate() in SqlItemRepository. DO NOT change service return types, wrap result internally."
}
```

---

## Batch Chunk Convention

When multiple files must change together (won't compile between), prefix the
`tdd` field with "BATCH":

```json
{
  "tdd": "BATCH - all 3 files must change together. No standalone unit test (UI). Verified by build + full suite regression. Update 16 breaking assertions in ServiceTest."
}
```

---

## Single-Chunk Features

For small features (1 chunk), the tracker is still created but simplified:

```json
{
  "phase": "Feature Name",
  "issue": "org/repo#XX",
  "chunks": [
    {
      "id": 1,
      "name": "Feature description",
      "status": "complete",
      "files_create": [],
      "files_modify": ["path/to/File.ext"],
      "test_files": ["path/to/Test.ext"],
      "acceptance_criteria": ["Describe the pass/fail condition"],
      "tdd": "Pre-test: existing TestClass covers logic. Pure UI change. Post-test: full suite regression.",
      "depends_on": [],
      "notes": "Optional context."
    }
  ],
  "quality_verification": { }
}
```

---

## Dependency Graph Notation

Document the execution order in the plan (not the tracker):

```text
Layer 1 (no deps):             Chunks 1, 2, 9
Layer 2 (depends on Layer 1):  Chunks 3, 4, 5, 6
Layer 3 (depends on Layer 2):  Chunks 7, 8
Layer N (final):               Chunk 10 (regression + quality)
```

The final chunk should always be a regression + quality verification chunk
that depends on all prior chunks.
