# .devloop/domain.md example - TypeScript / Node.js

Example configuration for a TypeScript backend service using
Node.js, with Express or Fastify.

---

## Domain Context

TypeScript backend service serving API consumers (web frontends,
mobile apps, third-party integrations). Data persists in PostgreSQL
with Redis for caching.

---

## Architecture Overview

Routes -> Controllers -> Services -> Repositories -> PostgreSQL

- Controllers handle HTTP (validation, serialization, status codes)
- Services contain business logic (no HTTP awareness)
- Repositories abstract data access (DB, external APIs)
- Zod schemas for runtime validation at API boundaries

---

## Domain-Specific Concerns (Clarification Taxonomy §9)

- [ ] CORS policy: cross-origin requests from frontend
- [ ] Rate limiting: abuse prevention on public endpoints
- [ ] Pagination: large result sets handled with cursor or offset
- [ ] Idempotency: POST/PUT operations safe to retry
- [ ] Timeouts: external API calls have deadlines
- [ ] Graceful shutdown: drain connections on SIGTERM
- [ ] Input encoding: UTF-8 handling, emoji in strings
- [ ] Memory: streaming for large payloads, no full buffering

---

## Existing Patterns

- Custom error classes extending BaseError (not bare throw)
- Constructor injection for all services (no service locators)
- Environment variables via config module (not process.env inline)
- SQL parameterized queries (no string concatenation)
- Proper HTTP status codes (201 create, 204 delete, 404 not found)
- Middleware chain: auth -> rate limit -> validate -> handler

---

## Quality Standards

- [ ] Every API endpoint story includes error response criteria
- [ ] List endpoints have pagination acceptance criteria
- [ ] Mutation endpoints have idempotency criteria
- [ ] Error scenarios specify HTTP status codes
- [ ] Features touching auth have permission acceptance criteria
- [ ] Performance targets include P95 latency for critical endpoints
