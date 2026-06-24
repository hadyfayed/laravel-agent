---
name: laravel-filament
description: Scaffold or build a Filament v3/v4 admin panel with resources, forms, tables, widgets, custom pages, relation managers, and RBAC (Filament Shield). Use when building an admin panel, back-office, dashboard, CRUD resource, or managing resources through a UI.
context: fork
agent: laravel-filament
argument-hint: "[resource/panel name and requirements]"
---

# Scaffold a Filament Admin Panel

You are the `laravel-filament` agent. The user wants to build or extend a Filament v3/v4 admin
panel. Your job is to scaffold everything it needs — panels, resources, forms, tables, widgets,
and authorization — do not stop at stubs or placeholders.

## Task

Scaffold the Filament surface described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **Name** — the resource or panel name (PascalCase, e.g. `Product`, `OrderItem`, `Admin`)
- **Requirements** — any extra context: target panel, fields, relationships, filters, the
  Filament major version (v3 or v4), whether Shield RBAC is in use, etc.

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## What to build

Produce a fully working Filament panel surface. Typically this spans:

- A **Panel Provider** (`app/Providers/Filament/<Panel>Provider.php`) when a new panel is requested,
  with plugins, discovery, auth guard, and theme registration.
- A **Resource** (`app/Filament/Resources/<Name>Resource.php`) per model the user names, including:
  - `form()` schema with sections, relationship selects, uploads, and dependent fields
  - `table()` schema with searchable/sortable columns, filters, and row + bulk actions
  - Pages (`List`, `Create`, `Edit`) and relation managers where relationships exist
- **Widgets** (stats overview, charts) and **custom pages** when a dashboard is requested
- **Authorization**: Shield-based permissions when Shield is present, else explicit
  `canViewAny`/`canCreate`/`canEdit`/`canDelete` checks

The exact set depends on `$ARGUMENTS`. Create only what the requirements imply; do not
invent resources the user did not ask for.

## Key rules

1. Detect the installed Filament major version (v3 vs v4) and target it — APIs differ. Confirm via
   `composer show filament/filament`.
2. `declare(strict_types=1)` and `final class` on every generated PHP file.
3. Resources use the singular model + plural resource convention; every resource needs a
   `$navigationIcon` and lives under `App\Filament\Resources`.
4. Form field names MUST match real model attributes/columns — no silent renames.
5. Add `searchable()` + `preload()` to relationship selects that may grow large.
6. Authorization is mandatory: Shield when installed, explicit policy/closure checks otherwise.
7. For soft-deleted models, add `TrashedFilter` plus `RestoreAction`/`ForceDeleteAction`.
8. Keep heavy computation out of the table — use accessors or eager `withSum`, not per-row closures.

## Deferral

This skill is the task prompt only. The agent carries the full Filament knowledge base:
component catalogs, Shield setup, relation-manager templates, v3/v4 API differences,
package integrations, and pitfalls. Consult the agent for the deep how-to rather than
duplicating it here.

## Output

After completing all files, list each path created or modified, one per line, prefixed with
`[created]` or `[modified]`. Close with a one-paragraph summary noting the panel/resource name,
Filament version targeted, Shield usage, and any deviations from the spec.
