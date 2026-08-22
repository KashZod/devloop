# .devloop/domain.md example - Android / Kotlin / Compose

Example configuration for an Android project using Kotlin, Jetpack
Compose, Room, and Hilt.

---

## Domain Context

Android mobile application with offline-first architecture. Users
interact via touch UI. Data persists locally with optional cloud sync.

---

## Architecture Overview

UI (Jetpack Compose) -> ViewModel -> Domain Layer (Coordinators, Readers) -> Room Database

- ViewModels collect Flow from domain layer
- Domain layer orchestrates writes and reads
- Room provides reactive queries via Flow
- Background work via WorkManager

---

## Domain-Specific Concerns (Clarification Taxonomy §9)

- [ ] Offline behavior: local operations work without network
- [ ] Timezone handling: UTC storage, local display, DST transitions
- [ ] Configuration changes: state survives rotation (ViewModel StateFlow)
- [ ] Permission model: runtime permission requests and denial handling
- [ ] Deep links: navigation to correct screen from external intents
- [ ] Notifications: channel setup, permission (API 33+), tap action
- [ ] Background work: WorkManager constraints and retry behavior
- [ ] ProGuard/R8: keep rules for reflection-based libraries

---

## Existing Patterns

- MVVM with domain layer: ViewModel -> Coordinator (writes) / Reader (reads) -> DAO
- Sealed interfaces for type-safe state (compiler-enforced branching)
- Flow for observable data (Room returns Flow, ViewModel collects)
- Fakes with MutableStateFlow for test doubles (not Mockito)
- @Transaction for multi-step database operations
- Hilt for dependency injection (new deps require @Module binding)

---

## Quality Standards

- [ ] Every P1 story addresses offline behavior
- [ ] Acceptance criteria account for configuration changes (rotation)
- [ ] Time-sensitive features have timezone edge cases
- [ ] Features modifying data have undo/confirmation criteria
- [ ] Features with user input have validation acceptance criteria
- [ ] Accessibility: contentDescription specified for interactive elements
