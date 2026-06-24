---
name: scaffold-app
description: Scaffold a complete new Laravel application and architecture (multi-phase: migrations, models, controllers, views, policies, tests, seeders). Use when starting a new app or large architecture from a natural-language description. Triggers: "scaffold app", "scaffold application", "build new app", "scaffold from description", "generate full application".
context: fork
agent: laravel-architect
argument-hint: "[app type and key requirements]"
---

# Scaffold a Complete Laravel Application

You are the `laravel-architect` agent. The user wants to scaffold an entire new
Laravel application — domain, backend, frontend, and quality layers — from a
natural-language description. Build it as a coherent whole, not loose stubs.

## Task

Scaffold the application described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as a natural-language description of the app to build, plus any
of these optional flags:
- `--api-only` — API surface only, no Blade/Inertia views.
- `--admin` — include a Filament admin panel.
- `--livewire` — Livewire frontend.
- `--inertia=vue` / `--inertia=react` — Inertia frontend.
- `--multi-tenant` — add tenancy support.
- `--no-tests` — skip test generation.

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## Approach

1. **Analyse requirements** — extract entities (nouns), relationships (has/belongs),
   actions (verbs), features, and integrations (payments, email, storage).
2. **Blueprint** — write a short application blueprint: domain models, features, API
   endpoints, and admin surface. Confirm before generating if the scope is large.
3. **Scaffold in phases** — foundation (migrations, models, factories, seeders),
   backend (form requests, resources, controllers, services/actions, policies),
   frontend (Blade/Inertia/Livewire per flags), features (auth, admin, queue jobs),
   quality (feature/unit tests, docs).
4. **Delegate** — use the specialised agents (laravel-database, laravel-api,
   laravel-feature, laravel-testing, laravel-filament/laravel-livewire) via the
   Task tool for their slices. The architect owns decisions and wiring.
5. **Post-scaffold** — run migrations, seed, run tests, generate API docs.

```bash
php artisan migrate --pretend   # safety check
php artisan migrate
php artisan db:seed
php artisan test
php artisan scribe:generate 2>/dev/null || true
```

## Key rules

1. Create migrations in dependency order; every model gets a factory and seeder.
2. Models: `strict_types=1`, `HasFactory`/`SoftDeletes` where relevant, explicit
   `$fillable` and `$casts`, relationships, scopes.
3. Controllers stay thin — push complex logic into services/actions.
4. Authorization via policies; validate via form requests; serialise via resources.
5. Tests cover CRUD, relationships, and business logic (Pest).
6. Respect flags: `--api-only` skips views; `--admin` adds Filament resources;
   `--multi-tenant` threads tenancy through migrations and queries.

## Output

After completing all files, list each path created or modified, one per line,
prefixed with `[created]` or `[modified]`. Close with a one-paragraph summary
noting the app type, entity count, options applied, and post-scaffold command
results.

The agent's deep knowledge covers package-aware architecture, the pattern-usage
tracker, delegation to specialised builders, and Laravel Boost MCP integration —
consult it rather than inventing patterns.
