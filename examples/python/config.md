# .devloop/config.md example - Python

Example configuration for a Python project using pytest,
with optional Django or FastAPI framework.

---

## Build & Test Commands

```bash
# Run all unit tests
pytest

# Run a specific test file
pytest tests/test_user_service.py

# Run a specific test by name
pytest -k "test_create_user_with_duplicate_email"

# Type checking (compile-equivalent)
mypy src/

# Lint / static analysis
ruff check src/
# or: flake8 src/
```

---

## Architecture Patterns

- **Layered architecture:** View/Route -> Service -> Repository
- **Views handle HTTP** - serialization, status codes, auth checks
- **Services contain business logic** - framework-agnostic
- **Repositories abstract data access** - ORM, raw SQL, external APIs
- **Dependency injection via constructor** - or FastAPI's Depends()
- **Protocol classes for interfaces** - test doubles implement Protocol
- **Pydantic models for validation** at system boundaries

---

## Standards to Verify (Quality Checklist §4)

- [ ] All business logic in service layer (not in views/routes)
- [ ] Input validation with Pydantic models at API boundaries
- [ ] Custom exception classes (not bare Exception)
- [ ] Async functions properly awaited (no fire-and-forget)
- [ ] Database queries use ORM or parameterized SQL (no f-strings)
- [ ] Type hints on all public functions
- [ ] Context managers for resource cleanup (with statements)
- [ ] Proper HTTP status codes in responses

---

## Blindspots to Check (Quality Checklist §8)

- [ ] SQL injection - parameterized queries everywhere
- [ ] N+1 queries - use select_related/joinedload for relations
- [ ] Pagination - large querysets use limit/offset or cursor
- [ ] Timezone handling - all datetimes timezone-aware (no naive)
- [ ] File uploads - size limits, type validation, path traversal
- [ ] Concurrency - race conditions in shared state
- [ ] Memory - generators for large datasets, streaming responses
- [ ] Graceful shutdown - cleanup on SIGTERM

---

## Commit Conventions

```text
# Message format: conventional commits
fix: description
feat: description
test: description

# Include scope when relevant
fix(auth): handle expired JWT tokens
feat(api): add user search endpoint
```

---

## Documentation Location

```text
docs/                # design docs, post-implementation notes
```

The spec and tracker directories are configured here too. Both have
defaults, so this block is optional; set it to override where the loop
reads and writes:

```text
spec-directory:    docs/specs/          # where /spec writes and /plan reads (default)
tracker-directory: .devloop/trackers/   # where /plan writes impl-tracker-<feature>.json (default)
```
