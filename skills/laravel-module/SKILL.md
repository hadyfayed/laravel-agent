---
name: laravel-module
description: Scaffold a reusable domain module under app/Modules with contracts, services, DTOs, events, strategies; when building a shared module or domain logic without UI/routes (NOT for feature scaffolding; use laravel-feature).
context: fork
agent: laravel-module
argument-hint: "[module name and domain]"
---

# Scaffold a Laravel Domain Module

You are the `laravel-module` agent. The user wants to build a reusable domain
module — pure business logic shared across features, with no routes or views.
Scaffold everything it needs — do not stop at stubs.

## Task

Scaffold the module described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **Name** — the module name (e.g. `Billing`, `Inventory`, `Pricing`)
- **Domain** — what the module owns: the business logic, any patterns (Strategy),
  data shapes (DTOs), events it raises, and integrations

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## What to build

Produce a fully working module at `app/Modules/<Name>/`:

```
app/Modules/<Name>/
├── <Name>ServiceProvider.php          # bindings, event subscribers, publishes config
├── Contracts/<Name>ServiceInterface.php
├── Services/<Name>Service.php         # final, dependency-injected
├── DTOs/<Name>Data.php                # if the domain implies structured data
├── Strategies/                        # if a Strategy/Policy pattern is requested
│   ├── <Strategy>Interface.php
│   └── Concrete<Strategy>.php
├── Events/<Name>Event.php             # domain events it emits
├── Exceptions/<Name>Exception.php     # typed domain exceptions
└── Tests/<Name>ModuleTest.php         # Pest, covers service + strategies
```

## Key rules

1. **No routes, no views, no controllers** — modules are pure domain logic.
2. **Program to interfaces** — bind `<Name>ServiceInterface` to the implementation
   in the ServiceProvider so callers depend on the contract.
3. **strict_types=1**, explicit return types, **final** services/DTOs.
4. **DTOs** are readonly value objects (typed, immutable).
5. **Strategy pattern** — interface + concrete strategies, resolved via the container.
6. **Domain events** — dispatched from the service; listeners registered by features.
7. **Distributable package** — if `spatie/laravel-package-tools` is installed and the
   brief wants a publishable package, emit `packages/<vendor>/<package>/` instead.
8. **Tests** — Pest unit tests for the service and each strategy; no HTTP layer.

The agent's deep knowledge covers module structure, package-tools integration,
the Strategy and Policy patterns, DTO design, and domain events — consult it
rather than inventing patterns.

## Output

After completing all files, list each path created or modified, one per line,
prefixed with `[created]` or `[modified]`. Close with a one-paragraph summary
noting the module name, patterns applied, and any deviations from the spec.
