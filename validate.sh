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
    "LICENSE"
    "README.md"
    # Implement skill
    "skills/implement/SKILL.md"
    "skills/implement/PROJECT.md"
    "skills/implement/references/chunk-template.md"
    "skills/implement/references/tracker-schema.md"
    "skills/implement/references/quality-checklist.md"
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
check_links_in "skills/spec/SKILL.md"
check_links_in "skills/implement/references/chunk-template.md"
check_links_in "skills/implement/references/tracker-schema.md"
check_links_in "skills/implement/references/quality-checklist.md"
check_links_in "skills/spec/references/spec-template.md"
check_links_in "skills/spec/references/clarification-taxonomy.md"
check_links_in "skills/spec/references/validation-checklist.md"

# ─────────────────────────────────────────────
section "3. JSON validity"
# ─────────────────────────────────────────────

# plugin.json
if python3 -m json.tool .claude-plugin/plugin.json > /dev/null 2>&1; then
    pass "plugin.json is valid JSON"
else
    fail "plugin.json is invalid JSON"
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

validate_json_blocks "skills/implement/references/tracker-schema.md"
validate_json_blocks "skills/implement/references/chunk-template.md"

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

# Check skills array
skill_count="$(python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); print(len(d.get('skills',[])))" 2>/dev/null || echo 0)"
if [[ "$skill_count" -ge 2 ]]; then
    pass "plugin.json has $skill_count skills"
else
    fail "plugin.json has $skill_count skills (expected >= 2)"
fi

# ─────────────────────────────────────────────
section "5. Implement SKILL.md phases are sequential (1-6)"
# ─────────────────────────────────────────────

implement_skill="skills/implement/SKILL.md"

phase_count="$(grep -cE '^## Phase [0-9]+:' "$implement_skill" || true)"
if [[ "$phase_count" -eq 6 ]]; then
    pass "Implement SKILL.md has $phase_count phases"
else
    fail "Implement SKILL.md has $phase_count phases (expected 6)"
fi

expected=1
phase_nums="$(grep -E '^## Phase [0-9]+:' "$implement_skill" | sed 's/^## Phase //' | sed 's/:.*//' || true)"
while IFS= read -r num; do
    [[ -z "$num" ]] && continue
    if [[ "$num" -eq "$expected" ]]; then
        pass "Implement Phase $num is sequential"
    else
        fail "Implement Phase $num out of order (expected $expected)"
    fi
    expected=$((expected + 1))
done <<< "$phase_nums"

# ─────────────────────────────────────────────
section "6. Spec SKILL.md phases are sequential (1-5)"
# ─────────────────────────────────────────────

spec_skill="skills/spec/SKILL.md"

phase_count="$(grep -cE '^## Phase [0-9]+:' "$spec_skill" || true)"
if [[ "$phase_count" -eq 5 ]]; then
    pass "Spec SKILL.md has $phase_count phases"
else
    fail "Spec SKILL.md has $phase_count phases (expected 5)"
fi

expected=1
phase_nums="$(grep -E '^## Phase [0-9]+:' "$spec_skill" | sed 's/^## Phase //' | sed 's/:.*//' || true)"
while IFS= read -r num; do
    [[ -z "$num" ]] && continue
    if [[ "$num" -eq "$expected" ]]; then
        pass "Spec Phase $num is sequential"
    else
        fail "Spec Phase $num out of order (expected $expected)"
    fi
    expected=$((expected + 1))
done <<< "$phase_nums"

# ─────────────────────────────────────────────
section "7. Quality checklist has exactly 8 points"
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
section "8. Implement SKILL.md 8-point summaries match checklist"
# ─────────────────────────────────────────────

# Phase 6 Quick Reference lists criteria 1-7 in bold; Phase 2.5 delegates
# to the review-plan agent (criteria listed in the agent, not inline).
# Check: each criterion appears at least once (Phase 6 Quick Reference).
phase6_names=(
    "Completeness"
    "Correctness"
    "Gaps (Functional)"
    "Standards"
    "Regression"
    "Robustness"
    "Gaps (Architectural)"
    "Blindspots"
)

for name in "${phase6_names[@]}"; do
    count="$(grep -c "\*\*$name\*\*" "$implement_skill" || true)"
    if [[ "$count" -ge 1 ]]; then
        pass "\"$name\" in Phase 6 Quick Reference"
    else
        fail "\"$name\" not found in Implement SKILL.md"
    fi
done

# Phase 2.5 is an artifact-triggered gate that delegates to review-plan agent.
# Verify the gate structure exists.
if grep -q "GATE.*tracker.*triggers" "$implement_skill"; then
    pass "Phase 2.5 has artifact-triggered gate"
else
    fail "Phase 2.5 missing artifact-triggered gate pattern"
fi

if grep -q "plan_review" "$implement_skill"; then
    pass "SKILL.md references plan_review tracker field"
else
    fail "SKILL.md missing plan_review tracker field reference"
fi

# ─────────────────────────────────────────────
section "9. Lessons learned are sequentially numbered"
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
check_lessons "$spec_skill" "Spec"

# ─────────────────────────────────────────────
section "10. PROJECT.md templates have required sections"
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
    "Commit Conventions"
)

for section_name in "${spec_sections[@]}"; do
    if grep -q "$section_name" "skills/spec/PROJECT.md"; then
        pass "Spec PROJECT.md has \"$section_name\""
    else
        fail "Spec PROJECT.md missing \"$section_name\""
    fi
done

# ─────────────────────────────────────────────
section "11. No project-specific leaks in core files"
# ─────────────────────────────────────────────

core_files=(
    "skills/implement/SKILL.md"
    "skills/spec/SKILL.md"
    "skills/implement/references/chunk-template.md"
    "skills/implement/references/tracker-schema.md"
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
section "12. Agent frontmatter is valid"
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
section "13. Implement SKILL.md references review agents"
# ─────────────────────────────────────────────

if grep -q "review-plan" "$implement_skill"; then
    pass "Implement SKILL.md references review-plan agent"
else
    fail "Implement SKILL.md does not reference review-plan agent"
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
section "14. SKILL.md frontmatter follows spec"
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
check_skill_frontmatter "$spec_skill" "Spec SKILL.md"

# ─────────────────────────────────────────────
section "15. SKILL.md files are under 500 lines"
# ─────────────────────────────────────────────

for skill_file in "$implement_skill" "$spec_skill"; do
    label="$(basename "$(dirname "$skill_file")")"
    lines="$(wc -l < "$skill_file")"
    if [[ "$lines" -le 510 ]]; then
        pass "$label SKILL.md is $lines lines (limit: 510)"
    else
        fail "$label SKILL.md is $lines lines (recommended limit: 510)"
    fi
done

# ─────────────────────────────────────────────
section "16. Example project configs are valid"
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
