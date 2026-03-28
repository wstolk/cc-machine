# Claude Code – Machine-level Agent Configuration
#
# This file lives at ~/.claude/CLAUDE.md and is read by Claude Code every
# time it starts in any project on this machine.  Use it to set global
# preferences that should apply everywhere.
#
# Docs: https://docs.anthropic.com/en/docs/claude-code/memory

---

## Workflow: Plan Before You Code

**Always think and plan before writing any code.**

1. **Understand** – Read the requirements, existing code, and relevant context
   thoroughly before proposing anything.
2. **Plan** – Write an explicit, numbered plan (what you will change and why).
   Present this plan and wait for approval before starting implementation.
3. **Implement** – Execute the approved plan step by step, keeping changes
   surgical and minimal.
4. **Verify** – Confirm the implementation matches the plan and all tests pass.

> If the scope changes during implementation, stop, update the plan, and get
> approval again before continuing.

---

## Test-Driven Development (TDD)

Follow the Red → Green → Refactor cycle for all non-trivial code:

1. **Write the test first** – the test must fail initially.
2. **Write the minimum code** to make the test pass.
3. **Refactor** – clean up without breaking the tests.

### Test quality rules

- Tests must verify **real behaviour**, not trivial implementation details.
- Avoid tests that only check that a function exists or returns a non-null value.
- Each test should have a single, clearly named assertion that reads like a
  specification (e.g. `it("returns 404 when user is not found")`).
- Cover happy paths, edge cases, and error paths.
- Prefer integration tests over mocks where practical; mock only external I/O.
- Do **not** remove or disable existing tests; fix the code instead.

---

## Code Documentation

- Every public function, class, method, and module must have a doc comment.
- Document the **why**, not just the what – explain design decisions and
  non-obvious constraints.
- Include short usage examples for public APIs.
- Keep documentation in sync with code changes; outdated docs are worse than
  none.
- Use the documentation style native to the language
  (JSDoc for JS/TS, rustdoc for Rust, Javadoc for Java/Kotlin, etc.).

---

## Code Quality

- Prefer **simple, readable** solutions over clever ones.
- Follow the existing code style of each project (run the project's linter
  before proposing changes).
- Keep functions small and focused (single responsibility).
- Avoid deep nesting; extract helpers or use early returns.
- Delete dead code rather than commenting it out.

---

## Language-specific Preferences

| Language   | Preferred tooling                       |
|------------|-----------------------------------------|
| Python     | `uv` for project/package management     |
| Rust       | `cargo` (stable channel by default)     |
| Java       | SDKMan-managed JDK 21 LTS, Maven/Gradle |
| Kotlin     | SDKMan-managed Kotlin + Gradle          |
| Go         | standard `go` toolchain                 |
| TypeScript | `npm` / `npx`, strict mode enabled      |

---

## Security

- Never hardcode secrets, API keys, or credentials in source code.
- Use environment variables or secret managers for sensitive values.
- Always validate and sanitise external input.
