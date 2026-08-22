# .devloop/config.md example - Rust

Example configuration for a Rust project using cargo test.

---

## Build & Test Commands

```bash
# Run all unit tests
cargo test

# Run a specific test
cargo test test_name

# Run tests in a specific module
cargo test --lib module_name

# Build (compile without running)
cargo build

# Lint / static analysis
cargo clippy -- -W clippy::all
```

---

## Architecture Patterns

- **Trait-based abstractions** - all service boundaries are traits
- **Dependency injection via generics** - `fn new(repo: impl Repository)`
- **Error handling via Result<T, E>** - custom error enums, no unwrap() in production
- **Builder pattern for complex construction** - validated at build time
- **Module visibility** - pub(crate) for internal APIs, pub for external
- **Test doubles as struct implementations** - no mocking frameworks

---

## Standards to Verify (Quality Checklist §4)

- [ ] No unwrap() or expect() in production code (use ? operator)
- [ ] Custom error types implement std::error::Error
- [ ] All public APIs have doc comments (/// style)
- [ ] Trait bounds are minimal (don't require Clone when & suffices)
- [ ] No unsafe blocks unless justified with SAFETY comment
- [ ] Proper lifetime annotations (no unnecessary 'static)
- [ ] Clippy warnings resolved (not suppressed without reason)

---

## Blindspots to Check (Quality Checklist §8)

- [ ] Panic paths - any remaining unwrap/expect in prod code
- [ ] Integer overflow - checked_add/checked_mul for user input
- [ ] String encoding - valid UTF-8 at boundaries (from_utf8)
- [ ] Concurrency - Arc<Mutex<T>> vs channels, deadlock potential
- [ ] Memory - large allocations, Vec growth, streaming for files
- [ ] Signal handling - graceful shutdown on SIGTERM/SIGINT
- [ ] Cross-platform - cfg(target_os) for OS-specific code
- [ ] Dependency audit - cargo audit for known vulnerabilities

---

## Commit Conventions

```text
# Message format: conventional commits
fix: description
feat: description
test: description
refactor: description
```

---

## Documentation Location

```text
docs/
```
