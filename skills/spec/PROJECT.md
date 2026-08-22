# devloop domain config

Create this as `.devloop/domain.md` in your project root and fill in the
sections. The `/spec` skill reads it for domain knowledge, architecture
context, and project-specific validation criteria. If devloop is copied
into your project instead of installed as a plugin, a `PROJECT.md` beside
the skill still works as the fallback.

---

## Domain Context

Describe your project in 2-3 sentences. What does it do? Who uses it?
What are the key business rules?

```text
# Examples:
#   Calendar app with offline-first architecture and cloud sync.
#   E-commerce API serving a React storefront and mobile apps.
#   CLI tool for managing Kubernetes deployments.
#   SaaS analytics dashboard for marketing teams.
YOUR_DOMAIN_CONTEXT_HERE
```

---

## Architecture Overview

Describe the key layers and how data flows through them. The spec
skill uses this to identify affected components and understand
integration points during Phase 1 (Explore).

```text
# Examples:
#   UI (Compose) -> ViewModel -> Domain (Coordinator/Reader) -> Room DB
#   Routes -> Controllers -> Services -> Repositories -> PostgreSQL
#   CLI Parser -> Commands -> Core Library -> File System
#   React Components -> Hooks -> API Client -> REST Endpoints
YOUR_ARCHITECTURE_OVERVIEW_HERE
```

---

## Domain-Specific Concerns (Validation Checklist §9)

List concerns that apply to MOST features in your project. These
are checked during Phase 2 (edge case identification) and Phase 4
(project-specific validation). Use checklist format.

- [ ] Example: All calendar operations handle timezone conversion
- [ ] Example: Multi-tenant data isolation verified in acceptance criteria
- [ ] Example: Offline behavior specified for network-dependent features
- [ ] Example: Currency and locale handling for financial calculations
- [ ] Example: Rate limiting considered for public-facing endpoints

```text
YOUR_DOMAIN_CONCERNS_HERE
```

---

## Existing Patterns

List features or patterns that new specs should reference instead
of re-describing. The spec skill checks new features against these
for consistency during Phase 1 (Explore).

"Follow the same pattern as X" is more accurate than re-specifying
what X already does.

```text
# Examples:
#   Domain CRUD goes through the central Coordinator/Service layer
#   All API endpoints use the shared error response format in errors.md
#   New CLI commands follow the 'verb-noun' naming convention
#   UI forms use the shared validation component with error display
YOUR_EXISTING_PATTERNS_HERE
```

---

## Quality Standards

Project-specific quality bars beyond the generic 8-point
validation checklist. The spec skill verifies these during
Phase 4 (Validate).

- [ ] Example: Every P1 story has at least 3 acceptance criteria
- [ ] Example: Performance requirements include P99 latency target
- [ ] Example: API changes include backward compatibility criteria
- [ ] Example: UI features include accessibility acceptance criteria
- [ ] Example: Features touching sync have conflict resolution criteria
