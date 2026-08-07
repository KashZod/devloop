# PROJECT.md - Project-Specific Configuration

Copy this file into your skill directory and fill in the sections
for your project. The TDD skill references this file for commands,
patterns, and conventions that vary between projects.

---

## Build & Test Commands

```bash
# Run all unit tests
# Examples:
#   ./gradlew testDebugUnitTest
#   npm test
#   pytest
#   cargo test
YOUR_TEST_COMMAND_HERE

# Run a specific test file or class
# Examples:
#   ./gradlew testDebugUnitTest --tests "*ClassName*"
#   npm test -- --grep "test name"
#   pytest tests/test_specific.py
#   cargo test test_name
YOUR_SPECIFIC_TEST_COMMAND_HERE

# Build (compile without running)
# Examples:
#   ./gradlew assembleDebug
#   npm run build
#   cargo build
YOUR_BUILD_COMMAND_HERE

# Lint / static analysis
# Examples:
#   ./gradlew lint
#   npm run lint
#   cargo clippy
YOUR_LINT_COMMAND_HERE
```

---

## Architecture Patterns

Describe your project's architecture rules that the TDD process
should verify. Examples:

- **Layer boundaries:** "ViewModels only depend on domain layer.
  Never import DAOs or repositories directly from UI."
- **Test doubles:** "Use fakes with in-memory state, not mocks."
- **Dependency injection:** "All services are constructor-injected.
  New dependencies require a DI binding."
- **Type safety:** "Use sealed interfaces for state, not strings."
- **Data flow:** "All writes go through Coordinator. Reads go
  through Reader."

```text
YOUR_ARCHITECTURE_RULES_HERE
```

---

## Standards to Verify (Quality Checklist §4)

List project-specific standards that the 8-point quality
checklist should verify:

- [ ] Example: All data operations go through domain layer
- [ ] Example: @Transaction for multi-step database operations
- [ ] Example: Flow for observable data (not one-shot queries)
- [ ] Example: Explicit intents for security-sensitive operations
- [ ] Example: Sensitive data masked in log output

---

## Blindspots to Check (Quality Checklist §8)

List project-specific edge cases to check:

- [ ] Example: Dark theme - colors, contrast, disabled states
- [ ] Example: Accessibility - screen reader semantics
- [ ] Example: Localization - hardcoded strings
- [ ] Example: Long text - overflow, truncation
- [ ] Example: Concurrent operations - rapid clicks, parallel syncs
- [ ] Example: Platform variance - browser/OS differences

---

## Commit Conventions

```text
# Author (if overriding default git config)
# Example: --author="name <email>"

# Message format
# Examples:
#   Conventional Commits: fix: description
#   Imperative: Fix the thing
#   Ticket prefix: [PROJ-123] Fix the thing

# Trailers to include or exclude
# Example: No Co-Authored-By trailer

# Other rules
# Example: Separate commits per feature, not one giant commit
```

---

## Documentation Location

Where should post-implementation docs be created?

```text
# Examples:
#   docs/
#   wiki/
#   .github/
#   Same directory as changed code
YOUR_DOCS_DIRECTORY_HERE
```
