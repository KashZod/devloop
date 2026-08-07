# Changelog

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
