---
name: laravel-scout
description: Laravel Scout full-text search — Algolia, Meilisearch, Typesense, database driver; searchable models, indexes, filters, pagination; when adding search. Use when the user mentions Scout, full-text search, Algolia, Meilisearch, Typesense, search indexes, searchable models, facets, or typo-tolerant search.
---

# Laravel Scout Skill

Apply Laravel Scout conventions when adding full-text search to models. Driver choice (Meilisearch self-hosted, Algolia managed, Typesense, or database for simple cases) follows from dataset size and feature needs.

## When to Use

- Full-text search across models
- Instant/typo-tolerant search with Algolia or Meilisearch
- Faceted search and filtering
- Search-as-you-type or autocomplete
- Simple database-based search for smaller apps

## Quick Start

```bash
composer require laravel/scout
php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"
php artisan scout:import "App\Models\Post"
```

## Driver Selection

| Driver | Best For |
|--------|----------|
| Meilisearch | Self-hosted, typo-tolerant, fast setup |
| Algolia | Managed service, analytics, recommendations |
| Typesense | Self-hosted, fast, typo-tolerant |
| Database | Simple cases, no external dependency |

## Conventions Checklist

### Searchable Models
- [ ] Add `use Searchable;` and define `toSearchableArray()`
- [ ] Only include fields needed for search — never passwords, tokens, secrets
- [ ] Eager-load relations in `toSearchableArray()` or via `makeAllSearchableUsing()` (no N+1)
- [ ] Keep `shouldBeSearchable()` fast — it runs on every save
- [ ] Use `searchableAs()` only when overriding the default index name

### Indexes (Meilisearch/Algolia)
- [ ] Configure `filterableAttributes` before using `->where()` clauses
- [ ] Configure `sortableAttributes` before using `->orderBy()`
- [ ] Run `php artisan scout:sync-index-settings` after config changes

### Searching
- [ ] Search FIRST, then add constraints: `Post::search($q)->where(...)`
- [ ] Combine with Eloquent via `->query(fn ($b) => $b->with([...]))`
- [ ] Use `->paginate($n)` or `->get()`; handle empty `$q` gracefully

### Indexing
- [ ] Import existing records after setup: `php artisan scout:import`
- [ ] Use `chunk()` for large imports; never load a full table into memory
- [ ] Set `'queue' => true` for production indexing

## Common Pitfalls

1. **Never imported existing records** — run `scout:import` after setup
2. **Missing filterable attributes** — configure before `->where()`
3. **Indexing sensitive data** — never put passwords/tokens in `toSearchableArray()`
4. **Large datasets** — chunk imports; enable queueing
5. **Mixing search and DB queries** — search first, then add Eloquent constraints
6. **Heavy `shouldBeSearchable`** — keep it fast
7. **Not syncing settings** — run `scout:sync-index-settings` after config changes
8. **Empty queries** — fall back to `latest()->paginate()` when `$q` is empty

## Guardrails

- **ALWAYS** queue indexing operations in production
- **ALWAYS** configure filterable/sortable attributes before using them
- **NEVER** index sensitive personal data
- **NEVER** run sync operations during high traffic

## Related Commands

- `php artisan scout:import` — import models to search index
- `php artisan scout:flush` — flush models from index
- `php artisan scout:sync-index-settings` — sync Meilisearch settings
- `php artisan scout:delete-index` — delete search index

## Related Skills

- `laravel-api` — API development
- `laravel-queue` — queue configuration
- `laravel-testing` — testing strategies
- `laravel-performance` — performance optimization
- `laravel-database` — database queries

## Additional references

- Install, driver configs (Algolia/Meilisearch/Typesense/database), queue setup, indexing commands, soft-deletes → [references/drivers-and-setup.md](references/drivers-and-setup.md)
- Searchable trait, `toSearchableArray`, conditional indexing, custom index name, custom indexes → [references/searchable-models.md](references/searchable-models.md)
- Searching, filters, constraints, pagination, search controllers, Livewire component, testing, pitfalls, best practices → [references/filters-and-pagination.md](references/filters-and-pagination.md)
