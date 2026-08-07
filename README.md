[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet.svg)](https://claude.com/claude-code)

# devloop

A test-driven development loop for
[Claude Code](https://docs.anthropic.com/en/docs/claude-code):
specify, plan, review, implement, verify, with independent review
agents that catch design bugs before coding and correctness bugs
before commit.

```
/spec          Clarify WHAT to build (user stories, acceptance criteria)
    ↓
/implement     Plan HOW to build it (chunks, dependencies, tracker)
    ↓
review-plan    Independent agent validates the plan (8-point review)
    ↓
/implement     Implement with TDD (failing test → code → pass)
    ↓
review-impl    Independent agent verifies implementation matches plan
   +
red-team       Independent agent hunts bugs + cleanups in the diff
```

`/implement` handles both planning and implementation. The three
review agents run in isolated context, they didn't write the plan or
code, so they evaluate honestly.

## Why This Workflow

- **The reviewer didn't write the code.** Review agents spawn in a
  fresh context, separate from the author, so author-evaluator bias is
  cut by the setup, not just by asking the reviewer to be objective.
- **Design bugs are caught before coding starts.** An 8-point plan
  review runs before any code is written. Fixing a wrong abstraction
  in a plan costs minutes; in code, hours.
- **Two complementary reviews at the end, not one.** `review-impl`
  checks *conformance*, does the code match the plan? `red-team`
  checks *correctness*, is the diff wrong or wasteful, regardless of
  the plan? A bug that faithfully implements a flawed plan is caught
  only by `red-team`; a correct-but-off-spec change only by
  `review-impl`.
- **The bug hunter is recall-biased, then verified.** `red-team`
  surfaces candidate defects freely (conservative reviewers
  under-report), then runs a verify pass that keeps only
  CONFIRMED/PLAUSIBLE findings and drops the rest, trading a noisier
  find phase for higher recall without shipping the false positives.
- **Work survives context resets.** A JSON tracker tells a new session
  exactly where to pick up.

## What's Included

| Piece | Type | Invocation | Purpose |
|-------|------|-----------|---------|
| [spec](skills/spec/SKILL.md) | Skill | `/spec <feature>` | User stories, acceptance criteria, edge cases |
| [implement](skills/implement/SKILL.md) | Skill | `/implement <feature>` | Chunk decomposition, JSON tracker, per-chunk red-green-refactor, 8-point quality gate |
| [review-plan](agents/review-plan.md) | Agent | auto (Phase 2.5) | 8-point plan review in fresh context |
| [review-impl](agents/review-impl.md) | Agent | auto (Phase 6) | Verifies implementation matches plan |
| [red-team](agents/red-team.md) | Agent | auto (Phase 6) / manual | Adversarial diff review, bugs + cleanup |

## The `red-team` agent

`red-team` is the plugin's bug-and-cleanup reviewer. It reads the diff
in a fresh context and runs a two-family review:

- **Correctness** (5 angles): line-by-line diff scan, removed-behavior
  auditor, cross-file caller/callee tracer, language-pitfall
  specialist, wrapper/proxy correctness.
- **Cleanup** (4 angles): reuse, simplification, efficiency, altitude
 , plus a conventions angle that reads the project's own `CLAUDE.md` /
  `PROJECT.md` at runtime and only flags rules it can quote.

It then **verifies** each candidate (recall-biased: PLAUSIBLE by
default, REFUTED only when the code proves it) and **sweeps** once more
for gaps the first pass missed.

It takes a mode:

| Mode | What it does |
|---|---|
| `bugs` | correctness angles only, then verify + sweep |
| `cleanup` | quality angles only, the tidy pass; can apply fixes |
| `both` *(default)* | everything |

```
Use the red-team agent in mode: both to review the changed files
Use the red-team agent in mode: cleanup to tidy the changed files
```

`red-team` reads no project assumptions of its own, it discovers
standards from the project's `CLAUDE.md` / `PROJECT.md` each run, so
the same agent works across projects.

## Install

Copy `skills/` and `agents/` into your project's `.claude/` directory,
or install as a Claude Code plugin.

Then give the loop project context. There are **two** `PROJECT.md`
templates, each skill reads the one in its own directory:

- `skills/implement/PROJECT.md`, build/test/lint commands, architecture
  rules, standards, and blindspots. Read by `/implement` and `red-team`.
- `skills/spec/PROJECT.md`, domain context, architecture overview, and
  domain-specific concerns. Read by `/spec`.

Fill in both (each is a template of `YOUR_*_HERE` placeholders). The
fastest start is to copy the closest example from
[`skills/implement/project-configs/`](skills/implement/project-configs/)
and [`skills/spec/project-configs/`](skills/spec/project-configs/),
ready-made configs for Node/TypeScript, Python, Rust, and
Android/Kotlin. Both skills run fine with no `PROJECT.md` (generic
defaults apply), just with less project-specific insight.

**Installing as a plugin?** Your filled-in `PROJECT.md` belongs in your
own project, not in the read-only plugin directory.

## License

Apache-2.0. See [LICENSE](LICENSE).
