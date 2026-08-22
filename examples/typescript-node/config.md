# .devloop/config.md example - TypeScript / Node.js

Example configuration for a TypeScript project using Node.js,
with Jest or Vitest for testing.

---

## Build & Test Commands

```bash
# Run all unit tests
npm test
# or: npx vitest run

# Run a specific test file
npm test -- --testPathPattern="UserService"
# or: npx vitest run src/services/UserService.test.ts

# Build (compile without running)
npm run build
# or: npx tsc --noEmit

# Lint / static analysis
npm run lint
# or: npx eslint src/
```

---

## Architecture Patterns

- **Layered architecture:** Controller -> Service -> Repository
- **Controllers handle HTTP** - validation, serialization, status codes
- **Services contain business logic** - no HTTP awareness
- **Repositories abstract data access** - DB, API, file system
- **Dependency injection via constructor** - no service locators
- **Interfaces for test doubles** - in-memory fakes, not jest.mock()
- **Zod/io-ts for runtime validation** at system boundaries

---

## Standards to Verify (Quality Checklist §4)

- [ ] All business logic in service layer (not in controllers or routes)
- [ ] Input validation at API boundaries (Zod schemas, express-validator)
- [ ] Proper error handling (custom error classes, not bare throw)
- [ ] Async/await with proper error propagation (no unhandled promises)
- [ ] Environment variables via config module (not process.env inline)
- [ ] SQL parameterized queries (no string concatenation)
- [ ] Proper HTTP status codes (201 for create, 404 for not found)

---

## Blindspots to Check (Quality Checklist §8)

- [ ] CORS - cross-origin requests from frontend
- [ ] Rate limiting - abuse prevention on public endpoints
- [ ] Pagination - large result sets handled properly
- [ ] Idempotency - retry-safe for POST/PUT operations
- [ ] Timeouts - external API calls have deadlines
- [ ] Memory - streaming for large payloads, no full buffering
- [ ] Graceful shutdown - drain connections on SIGTERM
- [ ] Input encoding - UTF-8 handling, emoji in strings

---

## Commit Conventions

```text
# Message format: conventional commits
fix: description
feat: description
test: description
chore: description

# Include scope when relevant
fix(auth): handle expired refresh tokens
feat(api): add pagination to /users endpoint
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
