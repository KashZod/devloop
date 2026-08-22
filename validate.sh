#!/usr/bin/env bash
#
# Structural validation for the devloop ecosystem.
# Checks files, links, JSON, phases, agents, leaks, and cross-references.
#
# Usage: ./validate.sh
# Exit code: 0 = all checks pass, 1 = failures found

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0
ERRORS=()

pass() {
    PASS=$((PASS + 1))
    printf "  \033[32mPASS\033[0m %s\n" "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    ERRORS+=("$1")
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
}

section() {
    printf "\n\033[1m%s\033[0m\n" "$1"
}

# ─────────────────────────────────────────────
section "1. Required files exist"
# ─────────────────────────────────────────────

required_files=(
    ".claude-plugin/plugin.json"
    ".codex-plugin/plugin.json"
    "LICENSE"
    "README.md"
    # Implement skill
    "skills/implement/SKILL.md"
    "skills/implement/PROJECT.md"
    "skills/implement/references/quality-checklist.md"
    # Plan skill (owns the plan artifacts: tracker schema + chunk template)
    "skills/plan/SKILL.md"
    "skills/plan/references/chunk-template.md"
    "skills/plan/references/tracker-schema.md"
    # Spec skill
    "skills/spec/SKILL.md"
    "skills/spec/PROJECT.md"
    "skills/spec/references/spec-template.md"
    "skills/spec/references/clarification-taxonomy.md"
    "skills/spec/references/validation-checklist.md"
    # Agents
    "agents/review-plan.md"
    "agents/review-impl.md"
    "agents/red-team.md"
)

for f in "${required_files[@]}"; do
    if [[ -f "$f" ]]; then
        pass "$f exists"
    else
        fail "$f is missing"
    fi
done

# ─────────────────────────────────────────────
section "2. Internal markdown links resolve"
# ─────────────────────────────────────────────

check_links_in() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"

    local targets
    targets="$(sed -n 's/.*\[.*\](\([^)]*\.md[^)]*\)).*/\1/p' "$file" 2>/dev/null || true)"

    if [[ -z "$targets" ]]; then
        return
    fi

    while IFS= read -r target; do
        # Skip external links
        [[ "$target" == http* ]] && continue
        # Strip any anchor (#section)
        target="${target%%#*}"
        local resolved="$dir/$target"
        if [[ -f "$resolved" ]]; then
            pass "$file -> $target"
        else
            fail "$file -> $target (not found: $resolved)"
        fi
    done <<< "$targets"
}

check_links_in "README.md"
check_links_in "skills/implement/SKILL.md"
check_links_in "skills/plan/SKILL.md"
check_links_in "skills/spec/SKILL.md"
check_links_in "skills/plan/references/chunk-template.md"
check_links_in "skills/plan/references/tracker-schema.md"
check_links_in "skills/implement/references/quality-checklist.md"
check_links_in "skills/spec/references/spec-template.md"
check_links_in "skills/spec/references/clarification-taxonomy.md"
check_links_in "skills/spec/references/validation-checklist.md"

# ─────────────────────────────────────────────
section "3. JSON validity"
# ─────────────────────────────────────────────

# plugin.json (Claude Code)
if python3 -m json.tool .claude-plugin/plugin.json > /dev/null 2>&1; then
    pass "plugin.json is valid JSON"
else
    fail "plugin.json is invalid JSON"
fi

# plugin.json (Codex)
if python3 -m json.tool .codex-plugin/plugin.json > /dev/null 2>&1; then
    pass "codex plugin.json is valid JSON"
else
    fail "codex plugin.json is invalid JSON"
fi

# Codex manifest required fields + skills-dir pointer (Codex uses a
# directory string for skills, not Claude's array of objects).
for field in name version description skills; do
    if python3 -c "import json; d=json.load(open('.codex-plugin/plugin.json')); assert '$field' in d" 2>/dev/null; then
        pass "codex plugin.json has '$field' field"
    else
        fail "codex plugin.json missing '$field' field"
    fi
done

codex_skills="$(python3 -c "import json; print(json.load(open('.codex-plugin/plugin.json')).get('skills',''))" 2>/dev/null || echo '')"
if [[ "$codex_skills" == "./skills/" ]]; then
    pass "codex plugin.json skills points to ./skills/"
else
    fail "codex plugin.json skills should be './skills/' (got '$codex_skills')"
fi

# JSON blocks in markdown files
validate_json_blocks() {
    local file="$1"
    local block_num=0
    local in_json=false
    local json_buf=""

    while IFS= read -r line; do
        if [[ "$line" == '```json' ]]; then
            in_json=true
            json_buf=""
            block_num=$((block_num + 1))
            continue
        fi
        if [[ "$line" == '```' ]] && $in_json; then
            in_json=false
            if echo "$json_buf" | python3 -m json.tool > /dev/null 2>&1; then
                pass "$file JSON block #$block_num is valid"
            else
                fail "$file JSON block #$block_num is invalid JSON"
            fi
            continue
        fi
        if $in_json; then
            json_buf+="$line"$'\n'
        fi
    done < "$file"
}

validate_json_blocks "skills/plan/references/tracker-schema.md"
validate_json_blocks "skills/plan/references/chunk-template.md"

# ─────────────────────────────────────────────
section "4. plugin.json has required fields"
# ─────────────────────────────────────────────

for field in name description author; do
    if python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); assert '$field' in d" 2>/dev/null; then
        pass "plugin.json has '$field' field"
    else
        fail "plugin.json missing '$field' field"
    fi
done

# Skills and agents are auto-discovered from skills/ and agents/. The
# manifest must NOT enumerate them: the current Claude Code schema rejects
# skills/agents as arrays of objects (`claude plugin validate` reports
# "Invalid input"). Verify the directories instead, and guard against a
# regression that re-adds the keys.
for s in spec plan implement; do
    if [[ -f "skills/$s/SKILL.md" ]]; then
        pass "skills/$s/SKILL.md present (auto-discovered)"
    else
        fail "skills/$s/SKILL.md missing"
    fi
done
if python3 -c "import json,sys; d=json.load(open('.claude-plugin/plugin.json')); sys.exit(1 if ('skills' in d or 'agents' in d) else 0)" 2>/dev/null; then
    pass "plugin.json does not enumerate skills/agents (schema-valid auto-discovery)"
else
    fail "plugin.json must not enumerate skills/agents (current Claude Code schema rejects object arrays)"
fi

# Marketplace catalogs (both harnesses) exist, are valid JSON, and list devloop.
# `plugin install` pulls from a marketplace, so a bare plugin.json is not
# installable on its own.
for mpfile in ".claude-plugin/marketplace.json" ".agents/plugins/marketplace.json"; do
    if [[ ! -f "$mpfile" ]]; then
        fail "$mpfile missing (needed for plugin install)"
    elif python3 -c "import json,sys; d=json.load(open('$mpfile')); sys.exit(0 if any(p.get('name')=='devloop' for p in d.get('plugins',[])) else 1)" 2>/dev/null; then
        pass "$mpfile is valid JSON and lists the devloop plugin"
    else
        fail "$mpfile must be valid JSON and list a plugin named devloop"
    fi
done

# ─────────────────────────────────────────────
section "5. Skill phases are sequential (spec 1-5, plan 1-5, implement 1-3)"
# ─────────────────────────────────────────────

implement_skill="skills/implement/SKILL.md"
plan_skill="skills/plan/SKILL.md"
spec_skill="skills/spec/SKILL.md"

check_phase_sequence() {
    local file="$1"
    local label="$2"
    local want="$3"

    local phase_count
    phase_count="$(grep -cE '^## Phase [0-9]+:' "$file" || true)"
    if [[ "$phase_count" -eq "$want" ]]; then
        pass "$label has $phase_count phases"
    else
        fail "$label has $phase_count phases (expected $want)"
    fi

    local expected=1
    local phase_nums
    phase_nums="$(grep -E '^## Phase [0-9]+:' "$file" | sed 's/^## Phase //' | sed 's/:.*//' || true)"
    while IFS= read -r num; do
        [[ -z "$num" ]] && continue
        if [[ "$num" -eq "$expected" ]]; then
            pass "$label Phase $num is sequential"
        else
            fail "$label Phase $num out of order (expected $expected)"
        fi
        expected=$((expected + 1))
    done <<< "$phase_nums"
}

check_phase_sequence "$spec_skill" "Spec SKILL.md" 5
check_phase_sequence "$plan_skill" "Plan SKILL.md" 5
check_phase_sequence "$implement_skill" "Implement SKILL.md" 3

# ─────────────────────────────────────────────
section "6. Quality checklist has exactly 8 points"
# ─────────────────────────────────────────────

checklist="skills/implement/references/quality-checklist.md"
checklist_count="$(grep -cE '^## [0-9]+\.' "$checklist" || true)"
if [[ "$checklist_count" -eq 8 ]]; then
    pass "quality-checklist.md has $checklist_count points"
else
    fail "quality-checklist.md has $checklist_count points (expected 8)"
fi

expected=1
checklist_nums="$(grep -E '^## [0-9]+\.' "$checklist" | sed 's/^## //' | sed 's/\..*//' || true)"
while IFS= read -r num; do
    [[ -z "$num" ]] && continue
    if [[ "$num" -eq "$expected" ]]; then
        pass "Checklist point $num is sequential"
    else
        fail "Checklist point $num out of order (expected $expected)"
    fi
    expected=$((expected + 1))
done <<< "$checklist_nums"

# ─────────────────────────────────────────────
section "7. Gate structure and 8-point summaries"
# ─────────────────────────────────────────────

# Implement Phase 3 lists the 8 concern names in bold (the code-time
# checklist). The plan-review gate now lives in /plan Phase 5; its 8
# criteria live in the review-plan agent, not inline in the skill.
phase3_names=(
    "Completeness"
    "Correctness"
    "Gaps (Functional)"
    "Standards"
    "Regression"
    "Robustness"
    "Gaps (Architectural)"
    "Blindspots"
)

for name in "${phase3_names[@]}"; do
    count="$(grep -c "\*\*$name\*\*" "$implement_skill" || true)"
    if [[ "$count" -ge 1 ]]; then
        pass "\"$name\" in Implement Phase 3 checklist"
    else
        fail "\"$name\" not found in Implement SKILL.md"
    fi
done

# The plan-review gate is artifact-triggered in /plan Phase 5.
if grep -q "GATE.*tracker.*triggers" "$plan_skill"; then
    pass "Plan SKILL.md has artifact-triggered plan-review gate"
else
    fail "Plan SKILL.md missing artifact-triggered gate pattern"
fi

# The /implement quality gate is triggered when all chunks complete.
if grep -qE "GATE.*(chunks complete|parallel review)" "$implement_skill"; then
    pass "Implement SKILL.md has artifact-triggered quality gate"
else
    fail "Implement SKILL.md missing quality gate pattern"
fi

# /plan records the gate field; /implement verifies it before the TDD cycle.
if grep -q "plan_review" "$plan_skill" && grep -q "plan_review" "$implement_skill"; then
    pass "plan_review tracker field referenced in /plan and /implement"
else
    fail "plan_review tracker field not referenced in both skills"
fi

# ─────────────────────────────────────────────
section "8. Lessons learned are sequentially numbered"
# ─────────────────────────────────────────────

check_lessons() {
    local file="$1"
    local label="$2"
    local lesson_nums=()
    local in_lessons=false

    while IFS= read -r line; do
        if [[ "$line" == "## Lessons Learned"* ]]; then
            in_lessons=true
            continue
        fi
        if $in_lessons && [[ "$line" == "---" || "$line" == "## "* ]]; then
            break
        fi
        if $in_lessons; then
            num=""
            if echo "$line" | grep -qE '^[0-9]+\. \*\*'; then
                num="$(echo "$line" | sed 's/\..*//')"
            fi
            if [[ -n "$num" ]]; then
                lesson_nums+=("$num")
            fi
        fi
    done < "$file"

    local count=${#lesson_nums[@]}
    if [[ "$count" -gt 0 ]]; then
        pass "$label: found $count lessons"
    else
        fail "$label: no lessons found"
    fi

    local expected=1
    for num in "${lesson_nums[@]}"; do
        if [[ "$num" -eq "$expected" ]]; then
            pass "$label: lesson $num is sequential"
        else
            fail "$label: lesson $num out of order (expected $expected)"
        fi
        expected=$((expected + 1))
    done
}

check_lessons "$implement_skill" "Implement"
check_lessons "$plan_skill" "Plan"
check_lessons "$spec_skill" "Spec"

# ─────────────────────────────────────────────
section "9. PROJECT.md templates have required sections"
# ─────────────────────────────────────────────

implement_sections=(
    "Build & Test Commands"
    "Architecture Patterns"
    "Standards to Verify"
    "Blindspots to Check"
    "Commit Conventions"
    "Documentation Location"
)

for section_name in "${implement_sections[@]}"; do
    if grep -q "$section_name" "skills/implement/PROJECT.md"; then
        pass "Implement PROJECT.md has \"$section_name\""
    else
        fail "Implement PROJECT.md missing \"$section_name\""
    fi
done

spec_sections=(
    "Domain Context"
    "Architecture Overview"
    "Domain-Specific Concerns"
    "Quality Standards"
)

for section_name in "${spec_sections[@]}"; do
    if grep -q "$section_name" "skills/spec/PROJECT.md"; then
        pass "Spec PROJECT.md has \"$section_name\""
    else
        fail "Spec PROJECT.md missing \"$section_name\""
    fi
done

# ─────────────────────────────────────────────
section "10. No project-specific leaks in core files"
# ─────────────────────────────────────────────

core_files=(
    "skills/implement/SKILL.md"
    "skills/plan/SKILL.md"
    "skills/spec/SKILL.md"
    "skills/plan/references/chunk-template.md"
    "skills/plan/references/tracker-schema.md"
    "skills/implement/references/quality-checklist.md"
    "skills/spec/references/spec-template.md"
    "skills/spec/references/clarification-taxonomy.md"
    "skills/spec/references/validation-checklist.md"
    "agents/review-plan.md"
    "agents/review-impl.md"
    "agents/red-team.md"
)
leaked_terms=("SapClient" "fetchFn" "vitest" "npx tsc" "CSRF" "Zod" "gradlew" "Hilt" "Room" "Jetpack" "AndroidManifest")

leak_found=false
for file in "${core_files[@]}"; do
    for term in "${leaked_terms[@]}"; do
        if grep -qi "$term" "$file" 2>/dev/null; then
            fail "$file contains project-specific term \"$term\""
            leak_found=true
        fi
    done
done
if ! $leak_found; then
    pass "No project-specific terms in core files"
fi

# ─────────────────────────────────────────────
section "11. Agent frontmatter is valid"
# ─────────────────────────────────────────────

for agent in agents/*.md; do
    basename="$(basename "$agent")"
    for field in name description tools model; do
        if grep -q "^${field}:" "$agent"; then
            pass "$basename has '$field' field"
        else
            fail "$basename missing '$field' field"
        fi
    done
done

# ─────────────────────────────────────────────
section "12. Skills reference their review agents"
# ─────────────────────────────────────────────

# review-plan is /plan's gate; review-impl + red-team are /implement's.
if grep -q "review-plan" "$plan_skill"; then
    pass "Plan SKILL.md references review-plan agent"
else
    fail "Plan SKILL.md does not reference review-plan agent"
fi

if grep -q "review-impl" "$implement_skill"; then
    pass "Implement SKILL.md references review-impl agent"
else
    fail "Implement SKILL.md does not reference review-impl agent"
fi

if grep -q "red-team" "$implement_skill"; then
    pass "Implement SKILL.md references red-team agent"
else
    fail "Implement SKILL.md does not reference red-team agent"
fi

# ─────────────────────────────────────────────
section "13. SKILL.md frontmatter follows spec"
# ─────────────────────────────────────────────

check_skill_frontmatter() {
    local file="$1"
    local label="$2"

    if grep -q '^name:' "$file"; then
        local skill_name
        skill_name="$(sed -n 's/^name:[[:space:]]*//p' "$file" | head -1 | tr -d ' ')"
        pass "$label has 'name' field: $skill_name"
        if echo "$skill_name" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
            pass "$label name format is valid"
        else
            fail "$label name '$skill_name' should be lowercase letters, numbers, and hyphens"
        fi
    else
        fail "$label missing 'name' field"
    fi

    if grep -q '^description:' "$file"; then
        pass "$label has 'description' field"
    else
        fail "$label missing 'description' field"
    fi

    if grep -q '\$ARGUMENTS' "$file"; then
        pass "$label uses \$ARGUMENTS placeholder"
    else
        fail "$label missing \$ARGUMENTS (user input won't reach the process)"
    fi
}

check_skill_frontmatter "$implement_skill" "Implement SKILL.md"
check_skill_frontmatter "$plan_skill" "Plan SKILL.md"
check_skill_frontmatter "$spec_skill" "Spec SKILL.md"

# ─────────────────────────────────────────────
section "14. SKILL.md files are under 500 lines"
# ─────────────────────────────────────────────

for skill_file in "$implement_skill" "$plan_skill" "$spec_skill"; do
    label="$(basename "$(dirname "$skill_file")")"
    lines="$(wc -l < "$skill_file")"
    if [[ "$lines" -le 510 ]]; then
        pass "$label SKILL.md is $lines lines (limit: 510)"
    else
        fail "$label SKILL.md is $lines lines (recommended limit: 510)"
    fi
done

# ─────────────────────────────────────────────
section "15. Example project configs are valid"
# ─────────────────────────────────────────────

for config in skills/implement/project-configs/*.md; do
    basename="$(basename "$config")"
    for section_name in "${implement_sections[@]}"; do
        if grep -q "$section_name" "$config"; then
            pass "implement/$basename has \"$section_name\""
        else
            fail "implement/$basename missing \"$section_name\""
        fi
    done
done

for config in skills/spec/project-configs/*.md; do
    basename="$(basename "$config")"
    for section_name in "${spec_sections[@]}"; do
        if grep -q "$section_name" "$config"; then
            pass "spec/$basename has \"$section_name\""
        else
            fail "spec/$basename missing \"$section_name\""
        fi
    done
done

# ─────────────────────────────────────────────
section "16. No harness-specific mechanics in skill/agent prose"
# ─────────────────────────────────────────────

# devloop is harness-agnostic: skill and agent instructions describe
# behavior, not the keystrokes/slash-commands/brand of any one harness.
# Each pattern is anchored so it matches the mechanic, not an innocent
# word (e.g. "/rename" must not match "removed/renamed").
harness_patterns=(
    'Shift\+Tab'
    'Ctrl\+G'
    '/compact([^a-zA-Z]|$)'
    '/rename([^a-zA-Z]|$)'
    '[-]-resume'
    'Claude Code'
    'Plan Mode'
    'Normal Mode'
)

harness_leak=false
for file in "${core_files[@]}"; do
    for pat in "${harness_patterns[@]}"; do
        if grep -qE "$pat" "$file" 2>/dev/null; then
            fail "$file contains harness-specific mechanic matching /$pat/"
            harness_leak=true
        fi
    done
done
if ! $harness_leak; then
    pass "No harness-specific mechanics in skill/agent prose"
fi

# ─────────────────────────────────────────────
section "17. No em or en dashes in published files"
# ─────────────────────────────────────────────

# The repo uses standard punctuation, not em (U+2014) or en (U+2013) dashes.
# Scan every published markdown file (core skill/agent prose plus the
# top-level docs). evals/ and docs/ are not part of the release, so they are
# out of scope. (Arrows U+2192 are used deliberately and are not flagged.)
em_dash_files=("${core_files[@]}" "README.md" "CHANGELOG.md" "PRIVACY.md")

em_dash_found=false
for file in "${em_dash_files[@]}"; do
    [[ -f "$file" ]] || continue
    if grep -qP "\x{2014}|\x{2013}" "$file" 2>/dev/null; then
        fail "$file contains an em or en dash (use standard punctuation)"
        em_dash_found=true
    fi
done
if ! $em_dash_found; then
    pass "No em or en dashes in published files"
fi

# ─────────────────────────────────────────────
section "18. Config discovery points at .devloop/"
# ─────────────────────────────────────────────

# The plugin-install-safe convention: skills and agents read project
# config from a .devloop/ directory in the project root, not from a
# PROJECT.md in the read-only plugin cache. Guard against reintroducing
# the cache pointer, and require each skill to name the .devloop/ home.
pointer_found=false
for file in "${core_files[@]}"; do
    if grep -q "plugin's skill directory" "$file" 2>/dev/null; then
        fail "$file points config discovery at the plugin's skill directory (use .devloop/)"
        pointer_found=true
    fi
done
if ! $pointer_found; then
    pass "No plugin-cache config pointer in core files"
fi

for skill_file in "$spec_skill" "$plan_skill" "$implement_skill"; do
    label="$(basename "$(dirname "$skill_file")")"
    if grep -q "\.devloop/" "$skill_file"; then
        pass "$label SKILL.md references .devloop/"
    else
        fail "$label SKILL.md does not reference the .devloop/ config home"
    fi
done

# The review agents discover project config too; each must name the
# .devloop/ home so a future edit can't silently revert one to the
# plugin-cache model.
for agent in agents/review-plan.md agents/review-impl.md agents/red-team.md; do
    basename="$(basename "$agent")"
    if grep -q "\.devloop/" "$agent"; then
        pass "$basename references .devloop/"
    else
        fail "$basename does not reference the .devloop/ config home"
    fi
done

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
printf "\n\033[1m━━━ Results ━━━\033[0m\n"
printf "  \033[32m%d passed\033[0m\n" "$PASS"

if [[ "$FAIL" -gt 0 ]]; then
    printf "  \033[31m%d failed\033[0m\n" "$FAIL"
    printf "\n\033[31mFailures:\033[0m\n"
    for err in "${ERRORS[@]}"; do
        printf "  - %s\n" "$err"
    done
    exit 1
else
    printf "  \033[32m0 failed\033[0m\n"
    printf "\n\033[32mAll checks passed.\033[0m\n"
    exit 0
fi
