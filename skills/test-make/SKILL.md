---
name: test-make
description: Generate comprehensive Pest/PHPUnit tests (unit, feature, API, or Dusk browser) for a target class, controller, or feature. Use when writing tests, adding coverage for existing code, or doing TDD. Triggers: "write tests", "generate tests", "test coverage", "pest test", "add tests for", "TDD", "test this class".
context: fork
agent: laravel-testing
argument-hint: "[target class or feature to test]"
---

# Generate Tests for a Target

You are the `laravel-testing` agent. The user wants comprehensive tests for a target.
Your job is to analyze the existing code and write tests that cover happy paths, edge
cases, validation, authorization, and database interactions — no stubs.

## Task

Generate tests for the target described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as `<Target> [type] [coverage]`:
- **Target** — the class, controller, feature, or route to test (e.g. `OrderService`,
  `ProductController`, `api/v1/products`, `Checkout`).
- **Type** *(optional)* — `unit` | `feature` | `api` | `browser` (Dusk) | `all`
  (default `feature`, or inferred from the target).
- **Coverage** *(optional)* — `basic` (happy path) | `comprehensive` (default: happy
  path + edge cases + errors) | `exhaustive`.

If the target or type is ambiguous, state your assumption and proceed.

## Test placement

| Type | Location |
|------|----------|
| Feature | `tests/Feature/` (HTTP, controllers, routes) |
| Unit | `tests/Unit/` (services, actions, DTOs) |
| API | `tests/Feature/Api/` (JSON endpoints) |
| Browser | `tests/Browser/` (Dusk) |

## Key rules

1. **Pest** idioms: `describe()`, `it()`, `beforeEach()`, `uses(RefreshDatabase::class)`,
   `expect()`, datasets for parameterised cases. Fall back to PHPUnit syntax only if the
   project is PHPUnit-only.
2. Cover **happy paths, validation errors, authorization (policy/gate), database state,
   relationships, and edge cases** (empty input, boundaries, nulls).
3. Use **model factories** for test data; mock external dependencies where requested.
4. **Isolation**: `RefreshDatabase`; never rely on leaked state between tests.
5. Match the project's existing test style — read a sibling test before generating.

The agent's deep knowledge covers unit/feature/API/Dusk templates, datasets, custom
expectations, and tenancy test traits — consult it rather than inventing patterns.

## Post-build

```bash
vendor/bin/pest --filter=<Target>
vendor/bin/pest --coverage --min=80   # if coverage was requested
```

## Output

List each test file created, one per line, prefixed with `[created]`. Include a small
table of file → type → test count. Close with a one-paragraph summary noting the target,
test types generated, coverage level, and any deviations from the spec.
