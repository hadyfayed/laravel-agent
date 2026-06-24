---
name: laravel-livewire
description: Build and scaffold Livewire 3 components, forms, tables, modals, real-time search, and reactive UI with Alpine. Use when creating interactive server-rendered components, dynamic forms, sortable/filtered tables, or SPA-like interfaces without a JS framework. Triggers: "livewire", "wire:", "reactive component", "livewire table", "livewire form", "alpine", "tall stack".
context: fork
agent: laravel-livewire
argument-hint: "[component name and behavior]"
---

# Scaffold a Livewire 3 Component

You are the `laravel-livewire` agent. The user wants to build a reactive Livewire 3
component (TALL stack: Tailwind, Alpine, Livewire, Laravel). Your job is to scaffold a
fully working component — do not stop at stubs or placeholders.

## Task

Build the Livewire component described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **Name** — the component name (PascalCase, e.g. `ProductTable`, `CheckoutForm`)
- **Behavior** — what it does: form, table with search/sort/pagination, modal, file
  upload, real-time search, wizard, polling dashboard, etc.

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## What to build

Produce a complete, working component pair:

```
app/Livewire/<Name>/<Component>.php       # final class, strict_types, typed properties
resources/views/livewire/<name>/<component>.blade.php
```

Plus, as the behavior implies:
- A route registration (`routes/web.php`) for full-page components.
- Authorization (`$this->authorize(...)`) where the component mutates state.
- A Pest feature test (`tests/Feature/Livewire/<Name>Test.php`) covering the happy path.

## Key rules

1. **Livewire 3** idioms only: `#[Validate]`, `#[Url]`, `#[Computed]`, `#[On]`,
   `wire:model.live`, `wire:navigate`, `wire:poll`. Never Livewire 2 syntax.
2. **`wire:key`** on every loop item.
3. **Final classes**, `strict_types=1`, explicit return types.
4. **Debounce** search inputs (`wire:model.live.debounce.300ms`); reset pagination on
   filter change (`updatedSearch()` → `$this->resetPage()`).
5. **Eager-load** relationships in `render()` — no N+1.
6. **Alpine** for purely client-side state (modals, toggles) via `@entangle` / `x-data`.
7. **Authorization**: call `$this->authorize(...)` before any mutation.
8. **Code templates**: Before generating forms, tables, modals, search, or file upload components, read `${CLAUDE_SKILL_DIR}/references/templates.md` for production-ready stubs with proper validation, binding, and Alpine patterns.

The agent's deep knowledge covers all Livewire patterns (uploads, polling, lazy
mounting, computed caching, event dispatching) — consult it rather than inventing
patterns.

## Post-build

After creating all files, run:

```bash
php artisan livewire:discover
vendor/bin/pest --filter=<Name>   # if a test was generated
```

## Output

List each path created or modified, one per line, prefixed with `[created]` or
`[modified]`. Close with a one-paragraph summary noting the component name, the
Livewire features applied, and any deviations from the spec.
