---
name: laravel-testing
description: Laravel testing conventions — Pest/PHPUnit patterns, feature/unit/API tests, factories, assertions, TDD practices; when writing or structuring tests. Use when the user mentions testing, tests, Pest, PHPUnit, coverage, TDD, unit tests, feature tests, integration tests, or factories.
---

# Laravel Testing Skill

Apply Laravel testing conventions when writing or structuring tests with Pest (the default test framework). Tests cover behavior, not implementation: arrange data with factories, act through HTTP or the class under test, and assert outcomes via HTTP/database/expectation idioms.

## When to Use

- Writing unit, feature, or API tests
- Implementing a TDD workflow
- Improving test coverage
- Testing events, jobs, notifications, exceptions
- Browser testing with Dusk

## Quick Start

```bash
/laravel-agent:test:make <ClassName>
/laravel-agent:test:coverage
```

## Conventions Checklist

### Setup
- [ ] Use `RefreshDatabase` for any test touching the DB
- [ ] Seed per-test data in `beforeEach()` — no shared mutable state
- [ ] Group related tests with `describe()`; one assertion concept per `it()`

### Data
- [ ] Use model factories, not hand-written arrays
- [ ] Add named factory states (`pending()`, `delivered()`) for scenarios
- [ ] Use `$this->faker` for randomized, non-flaky values

### Assertions
- [ ] HTTP: `assertCreated`, `assertUnauthorized`, `assertUnprocessable`, `assertJsonValidationErrors`
- [ ] DB: `assertDatabaseHas` after mutations
- [ ] Side effects: `Event::fake()` / `Queue::fake()` / `Notification::fake()` then `assert*`
- [ ] Exceptions: `expect(fn () => ...)->toThrow(...)`

### What to test
- [ ] Happy path for each public action/endpoint
- [ ] Authorization (unauthenticated + unauthorized rejected)
- [ ] Validation (required fields, types, boundaries)
- [ ] Side effects (events, jobs, notifications)
- [ ] Edge cases and error states
- [ ] Behavior, not implementation

## Code templates and stubs

Before generating unit, feature, API, or browser tests, read `${CLAUDE_SKILL_DIR}/references/templates.md` for production-ready test stubs with proper describe/it structure, assertions, factories, and authorization checks.

## Common Pitfalls

1. **No RefreshDatabase** — always reset DB state between tests
2. **Testing implementation** — test behavior so refactors don't break tests
3. **Slow tests** — mock external services
4. **Missing edge cases** — test boundaries and errors
5. **No assertions** — every test needs clear assertions
6. **Shared state** — use `beforeEach` for isolation

## Best Practices

- One assertion concept per test
- Descriptive test names
- Test edge cases and errors
- Keep tests fast (mock slow operations)
- Use factories for test data
- Follow Arrange-Act-Assert

## Package Integration

- **pestphp/pest** — testing framework
- **pestphp/pest-plugin-laravel** — Laravel helpers
- **mockery/mockery** — mocking library
- **laravel/dusk** — browser testing

## Related Commands

- `/laravel-agent:test:make` — generate comprehensive tests
- `/laravel-agent:test:coverage` — run tests with coverage report

## Related Agents

- `laravel-testing` — testing specialist (test-generation worker)

## Additional references

- Feature/unit/API tests, testing events/jobs/notifications/exceptions, pitfalls, best practices → [references/pest-patterns.md](references/pest-patterns.md)
- Factories (definition, states), assertion idioms, what-to-test guidance → [references/factories-and-assertions.md](references/factories-and-assertions.md)
