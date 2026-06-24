---
name: laravel-refactor
description: Refactor Laravel code for SOLID/DRY compliance — extract god classes, improve structure without changing behavior; when refactoring for better code quality.
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Read Grep Glob Edit Write
argument-hint: "<target> [--focus=<concern>]"
---

## Input

- **Target:** file path, class name, or directory to refactor
- **Focus:** (optional) specific concern (`general`, `solid`, `dry`, `performance`)

Examples:
```
Target: app/Http/Controllers/OrderController.php
Focus: general

Target: app/Services/OrderService
Focus: solid
```

## Process

1. **Analyze the target** for code smells using the detection guide in `${CLAUDE_SKILL_DIR}/references/smells-and-fixes.md`
2. **Check dev tools** — run IDE helpers and profiling if available (see `references/dev-tools-integration.md`)
3. **Refactor incrementally** — one change at a time, tests pass after each
4. **Verify** — ensure no functionality changed; all tests passing

## Code smell detection

Refer to `${CLAUDE_SKILL_DIR}/references/smells-and-fixes.md` for:
- **SOLID violations** (SRP, OCP, LSP, ISP, DIP)
- **DRY violations** (duplicated code, similar queries)
- **Thresholds** (god class >300 lines, long method >20 lines, deep nesting >3 levels)

## Refactoring patterns

Use these proven strategies (see `${CLAUDE_SKILL_DIR}/references/solid-extraction.md`):
- **Extract Service** — move business logic from controller to action/service
- **Extract Method** — break long methods into smaller, named pieces
- **Replace Conditional** — use strategy pattern instead of switch/if chains
- **Type Declaration** — add proper type hints to improve clarity

## Pre-refactoring checklist

- Git status is clean (if not, commit or stash first)
- Test suite passes (`php artisan test`)
- If available, run static analysis: `./vendor/bin/phpstan analyse`
- If available, run formatter check: `vendor/bin/pint --test`

## Post-refactoring checklist

- All tests pass: `php artisan test`
- Code formatted: `vendor/bin/pint` (if installed)
- Git diff shows only code structure changes, no logic changes
- Commit with message: `refactor(scope): extract <target>` (no functional changes)

## When NOT to refactor

- Tests are failing (fix tests first)
- Code is in active development (wait for feature freeze)
- You don't fully understand the code (read more first)
