# .devloop/config.md example - Android / Kotlin / Compose

Example configuration for an Android project using Kotlin, Jetpack
Compose, Room, and Hilt.

---

## Build & Test Commands

```bash
# Run all unit tests
./gradlew testDebugUnitTest

# Run a specific test class
./gradlew testDebugUnitTest --tests "*EventRepositoryTest*"

# Build (compile without running)
./gradlew assembleDebug

# Lint / static analysis
./gradlew lint
```

---

## Architecture Patterns

- **MVVM with domain layer:** ViewModel -> UseCase/Coordinator -> Repository -> DAO
- **Never access DAOs from ViewModels** - always go through domain layer
- **Repository interface + Fake test doubles** - use MutableStateFlow in fakes, not Mockito
- **Dependency injection via Hilt** - new dependencies require @Module binding
- **Sealed interfaces for type-safe state** - compiler-enforced branching
- **Flow for observable data** - Room returns Flow, ViewModel collects
- **@Transaction for multi-step DB operations**

---

## Standards to Verify (Quality Checklist §4)

- [ ] All data operations go through domain layer (not DAO from ViewModel)
- [ ] @Transaction for multi-step database operations
- [ ] Flow for observable data sources (not one-shot queries)
- [ ] Explicit PendingIntents (no implicit - CWE-927)
- [ ] Sensitive data masked in log output
- [ ] coerceIn() for bounded numeric input
- [ ] Material 3 component usage (correct theme tokens)

---

## Blindspots to Check (Quality Checklist §8)

- [ ] Dark theme - colors, contrast, disabled states
- [ ] Accessibility - contentDescription, screen reader semantics
- [ ] Localization - hardcoded strings (use strings.xml)
- [ ] Long text - calendar names, event titles overflow
- [ ] RTL layout - right-to-left text direction
- [ ] OEM variance - Samsung, Xiaomi content provider differences
- [ ] Config change - state survives rotation (ViewModel StateFlow)
- [ ] Large datasets - RecyclerView/LazyColumn performance

---

## Commit Conventions

```text
# Author
--author="name <email>"

# Message format: conventional commits
fix: description
feat: description
test: description

# No Co-Authored-By trailer
```

---

## Documentation Location

```text
docs/
```
