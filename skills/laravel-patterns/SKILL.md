---
name: laravel-patterns
description: Laravel architecture and design patterns — SOLID, DRY, Repository, Action, Service, DTO, Strategy, Factory, Pipeline, Observer, and refactoring guidance. Use when structuring or reviewing code, choosing a pattern, refactoring fat controllers, or auditing codebase architecture.
---

# Laravel Patterns Skill

Apply proven architecture and design patterns when structuring Laravel code, refactoring, or reviewing for SOLID/DRY compliance.

## When to Use

- Structuring a new module or feature and deciding where logic belongs
- Refactoring a fat controller, God class, or duplicated logic
- Reviewing code for SOLID/DRY violations
- Choosing between Action, Service, Repository, DTO, or Strategy
- Auditing which patterns are in use across the codebase

## Conventions Checklist

### SOLID
- [ ] **SRP** — each class has one reason to change; extract when a class does two unrelated jobs
- [ ] **OCP** — extend via new Strategy/Decorator classes, not by editing switch statements
- [ ] **LSP** — subclasses are substitutable for their parents; never weaken preconditions
- [ ] **ISP** — split fat interfaces; clients depend only on methods they call
- [ ] **DIP** — depend on interfaces (contracts), bind implementations in a provider

### DRY
- [ ] Extract repeated query/scoping logic into a scope, method, or query object
- [ ] Share validation rules via Form Requests, not duplicated arrays
- [ ] Centralize transformations in Accessors/Mutators or cast classes
- [ ] Duplication across controllers → move to an Action or Service
- [ ] Three strikes — third occurrence of logic warrants extraction

## Pattern Library

| Pattern | When to reach for it | Home |
|---------|----------------------|------|
| **Action** | Single, procedural use-case (e.g. `CreateOrderAction`) | `app/Actions` |
| **Service** | Stateful or multi-method domain logic reused across features | `app/Services` |
| **Repository** | Complex querying that needs a testable seam away from Eloquent | `app/Repositories` |
| **DTO / Data** | Type-safe transport between layers (Spatie Laravel-Data, native readonly) | `app/Data` |
| **Strategy** | Swap behavior by variant (payment gateways, pricing rules) | `app/Strategies` |
| **Factory** | Build test or seed fixtures; encapsulate object creation | `database/factories` |
| **Pipeline** | Ordered, composable stages (HTTP middleware, request processing) | `app/Pipelines` |
| **Observer** | React to Eloquent lifecycle events without bloating the model | `app/Observers` |
| **Query Object** | Encapsulate a complex, composable filter set | `app/Query` |
| **Presenter** | Format model output for a view without leaking into Blade | `app/Presenters` |
| **Builder** | Stepwise construction of a complex object (object builders, not Eloquent query builders) | `app/Builders` |

## Anti-Patterns to Avoid

1. **Fat Controller** — business logic in the controller → move to Action/Service
2. **God Model** — model doing formatting, persistence, and notifications → extract
3. **Static-everything** — `Helper::doX()` proliferation → inject a Service
4. **Premature Repository** — wrapping Eloquent for CRUD adds indirection with no gain
5. **Pattern-for-pattern's-sake** — adopt a pattern only when it removes real complexity

## Refactoring Heuristics

- Controller method over ~20 lines → extract an Action
- Logic reused by 2+ controllers → Service
- Repeated query chains → Repository or query scope
- Switch on type → Strategy
- Long method with feature flags → Pipeline or Decorator
- Model with side effects on save → Observer

## Auditing Current Usage

Run the pattern-detection scan to see what's in use:

```bash
echo -n "Repositories: "; find app -name "*Repository.php" | wc -l | tr -d ' '
echo -n "Actions: "; find app/Actions -name "*Action.php" 2>/dev/null | wc -l | tr -d ' '
echo -n "Services: "; find app/Services -name "*Service.php" 2>/dev/null | wc -l | tr -d ' '
echo -n "DTOs: "; grep -rl "readonly class.*Data" app/ --include="*.php" 2>/dev/null | wc -l | tr -d ' '
echo -n "Strategies: "; grep -rl "implements.*Strategy" app/ --include="*.php" 2>/dev/null | wc -l | tr -d ' '
echo -n "Events: "; find app/Events -name "*.php" 2>/dev/null | wc -l | tr -d ' '
```

The registry cap (`limit`) in `.ai/patterns/registry.json` is advisory — the registry itself is optional. Treat the scan output as a snapshot of architectural posture, not a quota to fill.

## Related Skills

- `laravel-refactor` — applying these patterns during a refactor
- `laravel-database` — Repository and query-object patterns intersect query optimization

## Related Commands

- `/laravel-agent:refactor` — invoke a refactoring pass
- `/laravel-agent:review:audit` — codebase-wide architecture audit
