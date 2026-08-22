# Changelog

## 3.1.1

Documentation and consistency fixes surfaced by two independent
release-readiness reviews. No behavior change: the loop, gates, and
schemas are identical to 3.1.0.

### Fixed
- **Examples are concrete, not templates.** The README described the
  `examples/<stack>/` files as `YOUR_*_HERE` placeholder templates, but
  they are concrete, stack-specific instances. Reworded to "copy the
  closest to `.devloop/` and adapt it."
- **Examples surface the directory settings.** Each `examples/*/config.md`
  now shows the `spec-directory` / `tracker-directory` settings (with
  defaults `docs/specs/` and `.devloop/trackers/`), matching what the
  README says `config.md` owns.
- **Accurate config cross-references.** `quality-checklist.md` now cites
  the real config headings (`§Standards to Verify`, `§Blindspots to
  Check`); `examples/*/domain.md` attributes the Domain-Specific Concerns
  section to the Clarification Taxonomy (§9), not the Validation Checklist
  (which has only §1-8); and `chunk-template.md`'s state-holder pointer
  now resolves to `implement SKILL.md §2.2` instead of a non-existent
  `§3.1`.
- **`/implement` Process Overview** now states that a passing `plan_review`
  is `PASS` *or* `PASS-WITH-WARNINGS` (it previously named only `PASS`).
- **Marketplace descriptions de-drifted.** Both `marketplace.json` catalog
  entries now match their `plugin.json` description verbatim, so there is
  one canonical blurb per harness.
- **`validate.sh` housekeeping.** The dash guard now also scans
  `examples/*/config.md` and `examples/*/domain.md` (published files a user
  copies into `.devloop/`); a stale comment referencing an uncommitted
  `evals/` directory was removed.

## 3.1.0

A single project-local home for devloop's per-project files: `.devloop/`.
This fixes config discovery under a plugin install (where the skills live
in a read-only shared cache and a `PROJECT.md` beside `SKILL.md` never
resolves in the user's project) and gives trackers a stable home outside
`docs/`.

### Added
- **`.devloop/` convention**: skills and agents read project config from
  `.devloop/` in the project root:
  - `config.md`, engineering config (build/test/lint commands, architecture
    rules, standards, blindspots, commit conventions, and the spec/tracker
    directory settings), read by `/plan`, `/implement`, `review-plan`,
    `review-impl`, `red-team`, and `/spec` (for the spec-directory setting).
  - `domain.md`, pure domain knowledge (domain context, architecture
    overview, domain-specific concerns, existing patterns, quality
    standards), read by `/spec`.
  - `trackers/`, home for `impl-tracker-<feature>.json`, written by `/plan`.
- **Config discovery**: each skill and agent resolves config as
  `.devloop/<file>` in the project, else generic mode. This is why a plugin
  install now works: the read-only cache holds the skills, but they read
  `.devloop/` from the project. There is no copied-in `PROJECT.md` fallback
  (the old template files are removed); `.devloop/` is the only
  project-config source.
- **`validate.sh` section 17**: fails if a core file reintroduces the
  plugin-cache config pointer ("plugin's skill directory") and requires each
  skill and review agent to name the `.devloop/` home.
- **`validate.sh` section 16** now also rejects en dashes (not just em
  dashes), closing a gap in the standard-punctuation guard.
- **Plugin marketplaces**: `.claude-plugin/marketplace.json` (Claude Code)
  and `.agents/plugins/marketplace.json` (Codex, its native catalog
  location) so devloop installs via
  `/plugin marketplace add KashZod/devloop` then
  `/plugin install devloop@kashzod`, and the `codex plugin marketplace add`
  / `codex plugin add` equivalents.

### Changed
- **Config ownership**: `config.md` owns the operational paths (spec
  directory, tracker directory) alongside the engineering settings;
  `domain.md` is now purely domain knowledge. Commit conventions live only
  in `config.md` (read by the skills that commit). `/spec` reads its output
  path from `config.md` and its domain context from `domain.md`.
- **Tracker home**: `/plan` writes trackers to `.devloop/trackers/` by
  default (was `docs/`); `/implement`, `review-plan`, and `review-impl`
  look there.
- **Example configs** live in one place per stack under a top-level
  `examples/<stack>/` (`typescript-node`, `python`, `rust`,
  `android-kotlin`), each holding a `config.md` and a `domain.md`; copy the
  closest directory to `.devloop/`. This replaces the split
  `skills/spec/project-configs/` (domain) and
  `skills/implement/project-configs/` (engineering) layout, and
  `validate.sh` now checks the examples in a single section (the former
  duplicate example-config check is removed).
- **`/implement` Phase 3 sizes the `red-team` half by diff size**, the
  same way `/plan` sizes work (its Trivial / Small / Medium+ / Large
  table). A single-file change (or a trivial one with no new logic) runs
  one `red-team` in `mode: both`, unchanged from before. A broader,
  multi-file or cross-cutting diff (`/plan` Medium+ and Large) splits the
  `red-team` half into parallel `mode: bugs` and `mode: cleanup` runs so
  neither family crowds the other out. `review-impl` runs alongside in
  every case. Because `red-team` in `mode: cleanup` can apply fixes, the
  split invokes the `cleanup` run report-only, so all three concurrent
  agents only report and the parallel gate stays read-only. No new
  `red-team` mode was added; report-only is an invocation instruction
  inside `cleanup` mode.
- **`validate.sh` section 18** asserts the Phase 3 spawn stays
  size-adaptive (it names the `mode: both`, `mode: bugs`, `mode: cleanup`,
  and `report-only` markers), so a future edit can't silently revert to
  the fixed single-agent gate.

### Migration
- **Move in-flight trackers.** Trackers previously written under `docs/`
  now live in `.devloop/trackers/`, and this release drops the `docs/`
  read-fallback. Move any existing `docs/impl-tracker-*.json` into
  `.devloop/trackers/`, or pass an explicit tracker path when invoking
  `/implement` or the review agents.
- **Migrate an old `PROJECT.md`.** The copied-in `PROJECT.md` fallback is
  gone; `.devloop/` is the only project-config source. Split any old
  `PROJECT.md` into `.devloop/config.md` (engineering settings and paths)
  and `.devloop/domain.md` (domain knowledge), or copy the closest
  `examples/<stack>/` directory as a starting point.

### Fixed
- **Valid Claude Code manifest.** `.claude-plugin/plugin.json` no longer
  enumerates `skills`/`agents` as arrays of objects, a shape the current
  schema rejects (`claude plugin validate` reported `skills: Invalid input`
  / `agents: Invalid input`). Claude Code auto-discovers `skills/` and
  `agents/`, so the keys are dropped; the manifest now passes
  `claude plugin validate --strict`. The Claude manifest also gains
  `repository` and `license`, matching the Codex manifest.

## 3.0.0

Three-command split, a harness-agnostic rewrite, and a de-overlapped
review layer. The loop is now `/spec -> /plan -> /implement`, mapping to
three gates (spec validation, plan review, code review) one gate per
command, with a convergence back-edge where `/implement` re-runs the
plan-review gate in-session. This release rolls up every change since
2.5.0. Breaking change: `/implement` no longer plans.

### Added
- **`/plan` skill**: decomposes a spec into an ordered, dependency-aware
  chunk plan, writes the JSON tracker, and runs the `review-plan` gate
  before any code is written. This is the old `/implement` Phases 1-2.5
  (analysis, chunk decomposition, dependency graph, tracker creation,
  plan-review gate), promoted from a buried mid-`/implement` checkpoint to
  a first-class command. The plan-review gate is the most important
  checkpoint in the loop, now its own visible step.
- **Convergence back-edge**: when a code-time finding (Phase 3) reveals
  that the *plan* was wrong (not just the code), `/implement` appends
  corrective chunks to the tracker and re-gates in-session by spawning the
  `review-plan` agent directly (not by re-invoking `/plan`, which would
  regenerate the tracker), preserving completed chunks and looping under a
  bounded guard until the plan and code converge. `/plan` gained a
  `/spec`-style detect-existing-tracker branch so a re-run merges into the
  existing tracker instead of resetting completed work.
- **`spec_doc` tracker field**: `/plan` records the source spec path so
  `/implement` and `review-impl` bind to the exact spec instead of
  globbing the spec directory (sharpens spec -> tracker traceability).
- **Shared concern vocabulary**: the seven concerns common to `review-plan`
  (plan-time) and the Phase 3 checklist (code-time) are now documented as
  one vocabulary in `quality-checklist.md`, so the reviewers speak the same
  language at both altitudes (the eighth concern is phase-specific: TDD
  Quality of the plan vs Blindspots in the code).
- **Three-state acceptance-criteria verification**: `review-impl`
  classifies each criterion CONFIRMED / PLAUSIBLE / REFUTED, each backed by
  a quoted line, recall-biased (default PLAUSIBLE; only CONFIRMED when a
  real test would go red on regression). Ported from the `red-team`
  verification model.
- **Spec validation evidence rule**: every WARN/FAIL in the spec
  validation checklist must quote the exact spec line it refers to, the
  same discipline the review agents apply to code.
- **validate.sh checks**: a harness-agnosticism check fails if any
  harness-specific mechanic (`Shift+Tab`, `Ctrl+G`, `/compact`, `/rename`,
  `--resume`, and similar) reappears in the skill or agent prose; the
  structural suite (~220 checks) also enforces the three-skill layout,
  phase sequencing, JSON validity, no project-specific leaks, and no em
  dashes in any published file.
- **Empirical validation**: the higher-risk changes, the
  `review-impl`/`red-team` de-overlap (does a defect ever fall between
  them?) and the three-state false-positive catch, were validated with an
  A/B eval harness over seeded fixtures rather than by inspection alone.

### Changed
- **`/implement` is now build-only** (3 phases): Load the Plan (locate the
  tracker, hard-stop unless its `plan_review` gate passed, orient on the
  next chunk), TDD Cycle per chunk (red/green/verify), and Quality
  Verification (8-point checklist + parallel `review-impl` + `red-team`
  gate). It refuses to start the TDD cycle on a tracker whose `plan_review`
  is missing or FAIL, telling the user to run `/plan` first.
- **`/spec` hands off to `/plan`** instead of `/implement`; its downstream
  mapping now routes spec sections to `/plan` (analysis, chunking) and
  `/implement` (tests) phases.
- **Plan artifacts moved with the plan**: `tracker-schema.md` and
  `chunk-template.md` now live under `skills/plan/references/`;
  `quality-checklist.md` stays under `skills/implement/references/` (it is
  the Phase 3 code checklist). Each skill cross-references the one shared
  file it needs.
- **review-impl narrowed to a conformance gate**: it verifies plan match,
  acceptance criteria (with quoted test evidence), test quality, and
  regression only. Adversarial correctness, robustness/blindspots,
  standards violations, and cleanup are deferred to `red-team`, which
  already does them better. This removes the overlap between the two
  Quality-Verification reviewers while preserving their
  conformance-vs-correctness separation.
- **Harness-agnostic instructions**: removed terminal-specific mechanics
  from the skill prose in favor of portable behavior. Plan presentation
  states the principle (planning is read-only; present a plan; get explicit
  approval) and lets the harness supply the mechanism; context management
  and session resumption describe the intent instead of naming specific
  keystrokes or commands. Exploration and check-running steps use
  conditional phrasing: use a subagent or parallel-tool capability if the
  harness has one, otherwise sequential is the default. The workflow tables
  are retitled "Mapping to the Explore -> Plan -> Code Loop" with no harness
  brand in the header.
- **review-plan / review-impl repointing**: `review-plan`'s description now
  says "in the /plan skill"; both agents read "the project's engineering
  `PROJECT.md`" rather than "PROJECT.md in the skill directory" (there are
  now three skills); `review-impl`'s Criterion 5 and the checklist
  reference `/implement` Phase 3 (Quality Verification). Agent names are
  unchanged (`review-plan`, `review-impl`, `red-team`).
- **review-plan Criterion 1** renamed "Scope, Completeness & Traceability"
  with explicit spec -> plan -> tracker forward/backward traceability
  language.
- **Scaffolding trim**: default to continuing multi-chunk work in one
  session rather than resetting between chunks; reset only when context
  degrades. Chunk decomposition prefers the fewest independently-testable
  chunks.

### Migration
- The workflow gains one user-invoked step: after `/spec`, run `/plan`,
  then `/implement`. Trackers created by an older `/implement` run without
  a `plan_review` field will be refused by the new `/implement`; run
  `/plan` (pointed at the existing tracker/spec) to gate them, or set
  `plan_review` manually if the plan was already reviewed. Hand-setting
  `plan_review: "PASS"` bypasses the review-plan gate: `/implement` trusts
  the field and cannot tell a gate-written verdict from a typed one.

### Fixed (design stress-test)
Hardening from an adversarial review of the whole v3.0.0 design:
- **Plan-time gate crash-safety**, the symmetric twin of the convergence
  fix. `/plan` creates the tracker with `plan_review: "PENDING"` (never a
  pre-stamped `PASS`), writes `FAIL` to disk *before* re-running on a gate
  FAIL, and bounds the FAIL/re-run loop, so a crash mid-review can no
  longer leave a stale `PASS` that `/implement` would build against.
- **`error` and `in_progress` chunks are no longer dead-ends.** `error` is
  documented as non-terminal (re-entered like `in_progress`); `/implement`
  Phase 1.3 validates the chunk graph (rejecting `depends_on` cycles and
  dangling ids); resumption re-enters an unfinished chunk before searching
  for the next `pending` one, so a blocked feature is surfaced, not
  silently left with the Phase 3 gate un-triggered.
- **Convergence re-gate loop is now counted.** `convergence_rounds` is
  bumped before *each* `review-plan` re-gate (not only when chunks are
  appended), so the two-round cap bounds the re-gate loop too; a bail-out
  cleanup path is documented.
- **Spec back-edge.** A finding that an acceptance *criterion itself* is
  wrong now routes to `/spec` (update mode) instead of into the plan gate
  built to reject it.
- **Honest degradation without subagents / without a project rule file.**
  The gates document that a harness with no subagent capability degrades
  to a non-isolated self-check; `/implement` Phase 3 covers standards and
  architecture with a self-check when no `PROJECT.md`/`CLAUDE.md` exists
  (where `red-team`'s conventions angle would otherwise return nothing).
- **Docs.** Softened the "1:1 gates" phrasing (`/implement` touches two
  gates via convergence); README's table notes review-plan's convergence
  spawn; tracker writes documented as atomic.

## 2.5.0

### Changed
- **red-team `mode: cleanup` can now apply fixes**: added `Edit`/`Write`
  to its tools so the tidy pass can edit files, not just report.
- **red-team is no longer git-only**: Phase 0 shows git as the common
  case but instructs substituting another VCS (hg, jj, Perforce) or
  asking the caller for the changed set, and clarifies that a tracker or
  plan path is context, not the review target.
- **`/implement` degrades gracefully with no PROJECT.md**: infers the
  test/build commands, confirms them with the user, notes the miss in
  the tracker, and suggests creating one, matching how `/spec` already
  behaves.
- Wired the conventions angle into every red-team mode and disambiguated
  "all modes" from the mode literally named `both`.

### Fixed
- review-impl no longer treats the post-implementation document as
  mandatory; its absence on a small self-contained change is no longer a
  false finding, matching the implement skill's conditional-docs rule.
- The plan-review gate branches on the verdict review-plan actually
  emits (`PASS-WITH-WARNINGS`) instead of a `WARN` value it never
  produces.
- `/implement` reads the spec directory from `PROJECT.md` (default
  `docs/specs/`), matching where `/spec` writes, instead of a hard-coded
  path.
- README install now documents both `PROJECT.md` templates, points at
  the `project-configs/` examples, and clarifies where `PROJECT.md`
  lives for plugin installs.
- Removed every em dash from the repository in favor of standard
  punctuation.

## 2.0.0

Renamed from `ai-agent-dev-workflow` to `devloop`.

### Added
- **`red-team` agent**, adversarial diff reviewer that hunts
  correctness bugs (5 angles) and flags cleanup (reuse, simplification,
  efficiency, altitude), verifies each finding (recall-biased,
  3-state), then sweeps for gaps. Modes: `bugs`, `cleanup`, `both`.
  The `cleanup` mode is a standalone tidy pass.

### Changed
- Renamed the `tdd` skill to `implement`.
- **Phase 6 quality gate now spawns `review-impl` + `red-team` in
  parallel** instead of `review-impl` + `/code-review`. A skill runs in
  the main loop and cannot invoke another skill or slash command, so it
  could not trigger `/code-review`. `red-team` ports the same
  finder-angle engine into an agent the skill *can* spawn via the Agent
  tool.
- Post-implementation documentation is now **conditional** (write it
  when the work outlives the session or has deferred follow-ups; skip
  it for small closed fixes) instead of mandatory for every change.
- Sharpened the scaffolding-calibration guidance for
  strong-instruction-following models: prefer fewer/larger chunks and
  fewer resets; keep the tracker and review gates; make bug review
  recall-biased-then-verified rather than conservative single-pass.

### Removed
- Dependency on `/code-review` from within the `implement` skill (a
  skill cannot invoke it).
- The `extension.yml` spec-kit manifest. `.claude-plugin/plugin.json`
  is the single source of truth; the spec-kit convention added a second
  manifest to keep in sync with no consumer in this project.
