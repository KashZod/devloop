[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet.svg)](https://claude.com/claude-code)
[![Codex](https://img.shields.io/badge/Codex-Plugin-10A37F.svg)](https://developers.openai.com/plugins/build/plugins)

# devloop

A test-driven development loop for
[Claude Code](https://docs.anthropic.com/en/docs/claude-code) and
[Codex](https://developers.openai.com/plugins/build/plugins):
specify, plan, implement, with independent review agents that catch
design bugs before coding and correctness bugs before commit.

```
/spec          Clarify WHAT to build (user stories, acceptance criteria)
    ↓            spec validation gate (8-point checklist)
/plan          Plan HOW to build it (chunks, dependencies, tracker)
    ↓
review-plan    Independent agent validates the plan (8-point review)
    ↓
/implement     Build it with TDD (failing test → code → pass), per chunk
    ↓
review-impl    Independent agent verifies implementation matches plan
   +
red-team       Independent agent hunts bugs + cleanups in the diff
   │
   └─ converge  If a review finding invalidates the *plan* (not just the
      (back-edge) code), /implement appends corrective chunks, re-gates
                 via the review-plan agent in-session, then resumes
```

Three commands map to three gates, one gate per command: `/spec` (WHAT,
spec validation), `/plan` (HOW, plan review), `/implement` (BUILD,
conformance + red-team review). The one exception is the convergence
back-edge below, where `/implement` re-runs the plan-review gate
in-session. The three review agents run in isolated context, they didn't
write the plan or code, so they evaluate honestly.

## Why not just prompt the AI?

You can tell a coding agent to "build feature X" in one prompt, and it
will often return working code. What a single prompt cannot give you is
everything *around* the code:

- **One pass conflates what, how, and build.** A misread requirement or a
  wrong abstraction gets decided and written as code in the same breath,
  where it is most expensive to unwind.
- **The author grades its own work.** "I verified it works," from the
  context that just wrote the code, is a self-report, not a review, it is
  blind to its own assumptions.
- **Context is fragile.** A long session degrades and a resumed one starts
  cold, so the plan and the reasoning behind it evaporate.
- **Ungated agents report optimistically.** With no hard gate, "done"
  tends to mean "I stopped," not "a test proves it."
- **Prompts do not compose or persist.** They live in your head and drift
  from run to run and project to project.

devloop exists to close exactly these gaps: it separates WHAT / HOW /
BUILD into three gated steps, runs review in a context that did not write
the code, persists a tracker so work survives resets, makes every gate an
evidence-backed hard-stop, and ships as a versioned artifact that behaves
the same across projects and harnesses. The next section is how each piece
pays off; [How the loop works](#how-the-loop-works) is the mechanics.

## Why This Workflow

- **The reviewer didn't write the code.** Review agents spawn in a
  fresh context, separate from the author, so author-evaluator bias is
  cut by the setup, not just by asking the reviewer to be objective.
- **Design bugs are caught before coding starts.** An 8-point plan
  review runs before any code is written. Fixing a wrong abstraction
  in a plan costs minutes; in code, hours.
- **Two complementary reviews at the end, not one.** `review-impl`
  checks *conformance*, does the code match the plan, and does a test
  prove each acceptance criterion (CONFIRMED / PLAUSIBLE / REFUTED,
  each with a quoted line)? `red-team` checks *correctness*, is the diff
  wrong or wasteful, regardless of the plan? The two are scoped to not
  overlap: `review-impl` defers correctness, robustness, standards, and
  cleanup to `red-team`. A bug that faithfully implements a flawed plan
  is caught only by `red-team`; a correct-but-off-spec change only by
  `review-impl`.
- **The bug hunter is recall-biased, then verified.** `red-team`
  surfaces candidate defects freely (conservative reviewers
  under-report), then runs a verify pass that keeps only
  CONFIRMED/PLAUSIBLE findings and drops the rest, trading a noisier
  find phase for higher recall without shipping the false positives.
- **Work survives context resets.** A JSON tracker tells a new session
  exactly where to pick up.

## How the loop works

The loop is not strictly linear. If an `/implement` review finding
invalidates the plan itself (a chunk's whole approach is wrong, or the
review surfaces work no chunk covers), `/implement` converges: it appends
corrective chunks to the tracker and re-runs the plan-review gate by
spawning the `review-plan` agent in-session (not by re-invoking `/plan`,
which would regenerate the tracker), then resumes building. That keeps the
plan and the code from drifting apart.

**Skills vs agents.** The user-facing, interactive steps are skills
(`/spec`, `/plan`, `/implement`); the isolated steps that return a
verdict are agents (`review-plan`, `review-impl`, `red-team`). The split
is by the nature of the work, not by a harness quirk, so it ports across
harnesses. It also means the loop is three user invocations, one per
command; a skill cannot call another skill, and coupling them into one
agent would tie the loop to a single harness.

The gates depend on spawning those agents. On a harness with no subagent
capability at all, each gate degrades to an in-context self-check and
loses the author-evaluator isolation that is the point, the skills say so
at each gate rather than pretending the guarantee still holds.

## What's Included

| Piece | Type | Invocation | Purpose |
|-------|------|-----------|---------|
| [spec](skills/spec/SKILL.md) | Skill | `/spec <feature>` | User stories, acceptance criteria, edge cases |
| [plan](skills/plan/SKILL.md) | Skill | `/plan <feature>` | Chunk decomposition, dependency graph, JSON tracker, plan-review gate |
| [implement](skills/implement/SKILL.md) | Skill | `/implement <feature>` | TDD chunk cycle against the tracker, 8-point quality gate |
| [review-plan](agents/review-plan.md) | Agent | auto (`/plan`; `/implement` convergence) | 8-point plan review in fresh context |
| [review-impl](agents/review-impl.md) | Agent | auto (`/implement` Phase 3) | Verifies implementation matches plan |
| [red-team](agents/red-team.md) | Agent | auto (`/implement` Phase 3) / manual | Adversarial diff review, bugs + cleanup |

**Reviewing arbitrary changes.** `review-impl` is a *conformance* gate:
it checks code against a plan, so it needs a tracker to review against.
To review an ad-hoc diff with no plan (a hotfix, someone else's branch),
invoke `red-team` directly, it is plan-agnostic and discovers the
project's standards at runtime.

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

**Claude Code.** Copy `skills/` and `agents/` into your project's
`.claude/` directory, or install as a plugin (manifest:
`.claude-plugin/plugin.json`, which registers the three skills and three
agents).

**Codex.** Install as a plugin (manifest: `.codex-plugin/plugin.json`).
The same three skills power both harnesses; Codex discovers them from the
`skills/` directory the manifest points at. Codex's plugin manifest
registers skills, not agents, so the three review agents under `agents/`
ride along as prompt files: the skills spawn them as subagents where the
harness supports delegation, and otherwise degrade to the in-context
self-check the gates already document.

Then give the loop project context. There are **two** `PROJECT.md`
templates:

- `skills/implement/PROJECT.md`, the engineering config, build/test/lint
  commands, architecture rules, standards, and blindspots. Read by
  `/plan`, `/implement`, `review-plan`, `review-impl`, and `red-team`.
  `/plan` and `/implement` share this one config; there is no separate
  plan config.
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

## Optional: proof that the check actually ran (rung)

devloop's reviews are evidence-backed (`review-impl` quotes the test line
that proves each acceptance criterion; `red-team` verifies each finding
before reporting), but the green step still trusts that the agent *ran*
the tests it says passed. [rung](https://github.com/rung-dev/rung) closes
that last gap: it records whether a check drove the real surface (not just
an isolated test or a reading of the code) and whether an independent
context ran it, then gates on that record deterministically.

It maps cleanly onto devloop. rung's author-vs-independent context is the
same author-evaluator split the review agents enforce, and its rung-level
(drove the real surface vs isolated test) hardens the TDD green step into
a re-checkable artifact instead of a self-report.

This is optional and unbundled by design. devloop ships only markdown and
a bash validator, with no runtime dependencies; rung is a separate
`pip install rung-ai` CLI (or GitHub Action). To use it, wrap the
regression run in `rung run --rung 1` and gate CI on `rung gate`
(exit `0` is the only pass). Keep it out of the core loop unless you want
CI-enforceable proof that the checks were real.

## License

Apache-2.0. See [LICENSE](LICENSE).
