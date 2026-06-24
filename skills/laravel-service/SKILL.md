---
name: laravel-service
description: Scaffold a service or single-purpose action class; when extracting business logic into a service, orchestrating operations, or creating a testable action.
context: fork
agent: laravel-service
argument-hint: "[service/action name]"
---

# Scaffold a Laravel Service or Action

You are the `laravel-service` agent. The user wants to extract business logic into
a service (multi-step orchestration) or a single-purpose action. Scaffold a fully
working class — do not stop at stubs.

## Task

Scaffold the service or action described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **Type** — `service` (orchestrates multiple operations) or `action` (one public method)
- **Name** — e.g. `OrderProcessor` (service) or `ChargeOrder` (action, Verb+Noun)
- **Spec** — what the class does: the operations it orchestrates or the single
  operation it performs, dependencies, and any run context (controller, job, listener)

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## What to build

**Service** (`app/Services/`):

```
app/Services/
├── <Name>Service.php                 # final, constructor-injected dependencies
└── Contracts/<Name>ServiceInterface.php   # bind in a ServiceProvider if callers need it
```

**Action** — native or via `lorisleiva/laravel-actions` if installed:

```
app/Actions/<Domain>/<VerbNoun>Action.php   # single handle() method, runnable as controller/job/listener
```

## Key rules

1. **Stateless and injected** — services take dependencies via the constructor; the
   container resolves them.
2. **Program to interfaces** — emit a contract when callers should depend on the
   abstraction; bind it in a ServiceProvider.
3. **Actions are single-purpose** — one public method (`handle` for native,
   `asController`/`asJob`/`asListener` for laravel-actions when a run context is given).
4. **Code templates**: Before generating a service, action, or test, read `${CLAUDE_SKILL_DIR}/references/templates.md` for production-ready stubs with proper injection, validation, authorization, and Octane-safe patterns.
4. **strict_types=1**, explicit return types, **final** classes.
5. **Typed exceptions** — throw a domain-specific exception rather than generic ones.
6. **Return value objects / DTOs** for complex results; never leak Eloquent where a
   contract wouldn't allow it.
7. **Tests** — Pest unit tests for the service/action with mocked dependencies; no HTTP.

The agent's deep knowledge covers native actions vs. lorisleiva/laravel-actions,
dependency-injection patterns, controller/job/listener run contexts, and DTO
design — consult it rather than inventing patterns.

## Output

After completing all files, list each path created or modified, one per line,
prefixed with `[created]` or `[modified]`. Close with a one-paragraph summary
noting the type, name, action style (native vs. laravel-actions), and any
deviations from the spec.
