---
name: laravel-database
description: Laravel database conventions — safe migrations, Eloquent relationships, N+1 and Big-O query optimization, indexing. Use when writing migrations, models, queries, fixing slow queries, or reviewing database code.
---

# Laravel Database Skill

Apply Laravel database best practices when writing migrations, designing schemas, fixing slow queries, or reviewing Eloquent code.

## When to Use

- Creating or modifying migrations
- Fixing N+1 query problems
- Fixing Big O complexity issues (O(n²), nested loops)
- Optimizing slow queries
- Designing database schemas
- Adding indexes
- Setting up Eloquent relationships

## Quick Start

```bash
/laravel-agent:db:optimize
/laravel-agent:db:diagram
```

## Conventions Checklist

### Migrations
- [ ] Declare `strict_types=1` at the top
- [ ] Use `return new class extends Migration` (anonymous class syntax)
- [ ] Always define `down()` — drop or reverse exactly what `up()` creates
- [ ] Use `foreignId(...)->constrained()->cascadeOnDelete()` for FK columns
- [ ] Add composite indexes for columns that appear together in `WHERE` + `ORDER BY`
- [ ] Use `decimal(10, 2)` for monetary amounts (never `float`)
- [ ] Use `softDeletes()` on user-facing entities
- [ ] Never store nullable booleans — use `tinyInteger` with a default instead

### Eloquent Models
- [ ] Declare `$fillable` or `$guarded` explicitly — never leave both unset
- [ ] Type-hint relationship return types (`HasMany`, `BelongsTo`, etc.)
- [ ] Use `$casts` for dates, enums, and JSON columns
- [ ] Add `scopeActive()` / `scopeOrdered()` query scopes rather than inline where chains

### Queries
- [ ] Eager-load all relationships needed in a loop — no lazy loading in loops
- [ ] Select only the columns you need (`->select(['id', 'name'])`)
- [ ] Use `chunk()` / `chunkById()` for operations on large datasets
- [ ] Use `->count()` not `->get()->count()`
- [ ] Replace `contains()` in a loop with `->flip()->has()` or `groupBy()`
- [ ] Batch updates with `whereIn(...)->update(...)` instead of per-row queries

### Transactions
- [ ] Wrap multi-step write sequences in `DB::transaction()`
- [ ] Never mix reads and writes in a transaction unless the read is a lock check

### Indexes
- [ ] Index every foreign key column
- [ ] Add a composite index when two columns always appear together in `WHERE`
- [ ] Use `unique()` for columns that enforce business uniqueness

## Common Pitfalls

1. **N+1 Queries** — always eager load with `with()`
2. **Big O Issues** — avoid nested loops; use `keyBy()`/`groupBy()` for O(1) lookups
3. **Missing Indexes** — add indexes for `WHERE` and `ORDER BY` columns
4. **SELECT \*** — only select needed columns
5. **No Chunking** — use `chunk()` for large datasets
6. **In-Loop Queries** — batch queries outside loops
7. **`contains()` in Loops** — use `flip()->has()` for O(1) lookups
8. **No Foreign Keys** — always use constraints
9. **No Transactions** — wrap related write operations

## Package Integration

- **beyondcode/laravel-query-detector** — N+1 detection
- **barryvdh/laravel-debugbar** — query profiling
- **spatie/laravel-query-builder** — API query building

## Related Commands

- `/laravel-agent:db:optimize` — analyze and optimize database queries
- `/laravel-agent:db:diagram` — generate database schema diagram

## Related Skills

- `laravel-performance` — query optimization and caching

## Additional references

- Migrations & relationships → [references/migrations.md](references/migrations.md)
- N+1 & Big-O optimization, indexing → [references/performance.md](references/performance.md)
- Version upgrades & legacy import → [references/upgrades-and-legacy.md](references/upgrades-and-legacy.md)
