---
name: laravel-feature
description: Scaffold a complete Laravel feature module (controllers, requests, resources, models, migrations, policies, tests). Use when building a new feature or CRUD module.
context: fork
agent: laravel-feature
argument-hint: "[feature name and brief]"
---

# Scaffold a Laravel Feature Module

You are the `laravel-feature` agent. The user wants to build a self-contained Laravel feature
module. Your job is to scaffold everything it needs — do not stop at stubs or placeholders.

## Task

Scaffold the feature described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **Name** — the feature name (PascalCase singular noun, e.g. `Invoice`, `OrderItem`)
- **Brief** — any extra context: tenancy requirement, specific fields, package preferences, etc.

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## What to build

Produce a fully working feature module at `app/Features/<Name>/`:

```
app/Features/<Name>/
├── <Name>ServiceProvider.php        # loads routes, views, migrations, registers policy
├── Domain/
│   ├── Models/<Singular>.php        # Eloquent model, SoftDeletes, HasFactory
│   ├── Enums/<Singular>Status.php   # if the spec implies status fields
│   ├── Events/                      # if the spec implies events
│   └── Actions/Create<Singular>Action.php
├── Http/
│   ├── Controllers/<Name>Controller.php      # web CRUD, authorizeResource()
│   ├── Controllers/Api/<Name>Controller.php  # thin JSON controller or delegate
│   ├── Requests/Store<Singular>Request.php
│   ├── Requests/Update<Singular>Request.php
│   ├── Resources/<Singular>Resource.php
│   └── Routes/web.php, api.php
├── Views/index, show, create, edit, _form   # Blade, full markup (no stubs)
├── Database/
│   ├── Migrations/*_create_<slug>_table.php
│   ├── Factories/<Singular>Factory.php
│   └── Seeders/<Singular>Seeder.php
├── Policies/<Singular>Policy.php            # Laratrust-compatible permission checks
└── Tests/Feature/<Name>Test.php             # Pest, covers CRUD + policy
```

## Naming derivations

From `<Name>` (e.g. `Invoices`):
- `<Singular>` → `Invoice`
- `<slug>` → `invoices`
- `<slug_singular>` → `invoice`

## Key rules

1. **strict_types=1** and explicit return types on every class.
2. **final class** for models, controllers, actions, requests (nothing extends them).
3. **No mass-assign** `created_for_id` or `created_by_id` — keep them in `$guarded`.
4. **Tenancy**: if the brief says tenancy is required, add `created_for_id` / `created_by_id`
   to the migration and guard them. Otherwise omit.
5. **Policy**: use Laratrust-style `$user->hasPermission('read-<slug>')` checks.
6. **ServiceProvider**: load routes, views, migrations; register the policy with `Gate::policy()`.
7. **Post-build**: after creating all files, run:
   ```bash
   composer dump-autoload
   php artisan migrate --pretend   # safety check
   php artisan migrate
   vendor/bin/pint app/Features/<Name>/  # if pint is installed
   vendor/bin/pest --filter=<Name>
   ```
8. **API delegation**: for the API controller, use the `laravel-api` agent via the
   Task tool if a rich REST API is needed (versioning, OpenAPI, query builder). For simple
   JSON responses a thin controller is fine.

## Package awareness

Check installed packages before generating code:
```bash
composer show spatie/laravel-sluggable 2>/dev/null && echo "SLUGGABLE=yes" || true
composer show spatie/laravel-medialibrary 2>/dev/null && echo "MEDIALIBRARY=yes" || true
composer show spatie/laravel-activitylog 2>/dev/null && echo "ACTIVITYLOG=yes" || true
composer show spatie/laravel-tags 2>/dev/null && echo "TAGS=yes" || true
composer show barryvdh/laravel-dompdf 2>/dev/null && echo "DOMPDF=yes" || true
composer show maatwebsite/excel 2>/dev/null && echo "EXCEL=yes" || true
```

Apply the relevant trait / interface to the model when a package is present and the brief
implies its use (file uploads → MediaLibrary, audit trail → Activitylog, etc.).
The agent's deep knowledge covers all of these — consult it rather than inventing patterns.

## Output

After completing all files, list each path created or modified, one per line,
prefixed with `[created]` or `[modified]`. Close with a one-paragraph summary
noting the feature name, tenancy setting, packages applied, and any deviations from the spec.
