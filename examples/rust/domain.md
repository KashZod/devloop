# .devloop/domain.md example - Rust

Example configuration for a Rust command-line tool.

---

## Domain Context

Rust CLI tool for terminal users and scripting/pipeline consumers.
Designed for composition with other Unix tools via stdin/stdout.

---

## Architecture Overview

CLI arg parsing (clap) -> Command handlers -> Core library -> File system / network

- CLI layer parses args and handles I/O formatting
- Command handlers orchestrate core library calls
- Core library contains all business logic (no I/O awareness)
- Errors propagate via Result<T, E> (no unwrap in production)

---

## Domain-Specific Concerns (Clarification Taxonomy §9)

- [ ] Exit codes: 0 success, 1 general error, 2 usage error
- [ ] Signal handling: SIGTERM/SIGINT for graceful shutdown
- [ ] Stdin/stdout encoding: UTF-8, handle BOM, binary detection
- [ ] Pipe-friendly output: no progress bars when stdout is not a TTY
- [ ] Cross-platform paths: Windows backslash, Unix forward slash
- [ ] Large input: streaming instead of loading everything into memory
- [ ] No unwrap/expect in production code paths

---

## Existing Patterns

- clap derive macros for argument parsing
- Result<T, E> propagation with thiserror for error types
- Builder pattern for complex configuration
- pub(crate) visibility by default (pub only for library API)
- Trait-based abstractions for testable I/O
- Integration tests via assert_cmd and predicates

---

## Quality Standards

- [ ] Every command story includes exit code criteria
- [ ] Output format specified (human-readable vs JSON vs both)
- [ ] Error messages include actionable remediation hints
- [ ] Pipe-compatible: no interactive prompts unless --interactive
- [ ] Help text acceptance criteria for new commands/flags
- [ ] Performance: large input benchmark expectations
