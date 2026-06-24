---
name: laravel-nova
description: Build Laravel Nova admin panels — resources, fields, actions, lenses, metrics, filters, and custom tools. Use when building a Nova admin, creating Nova resources/actions/filters/lenses/metrics, or comparing Nova vs Filament.
---

# Laravel Nova Skill

Build powerful, beautiful admin panels with Laravel Nova - Laravel's premium administration panel.

## When to Use

- Creating premium admin panels with advanced features
- Need for professional UI/UX out of the box
- Complex data relationships and visualization
- Enterprise-level admin requirements
- When budget allows for commercial license
- Official Laravel package with guaranteed support

### Nova vs Filament Comparison

**Choose Nova when:**
- Budget allows ($99/site)
- Need official Laravel package
- Want guaranteed long-term support
- Prefer traditional admin panel approach
- Need proven enterprise stability

**Choose Filament when:**
- Budget is limited (free/open-source)
- Need rapid development
- Want modern TALL stack approach
- Community packages are acceptable
- Prefer more customization flexibility

## Quick Start

```bash
# Note: Requires valid Nova license
composer require laravel/nova
php artisan nova:install
php artisan nova:user
```

## Conventions Checklist

### Resources
- [ ] Extend `Laravel\Nova\Resource`, declare `static string $model`
- [ ] Set `$title` (display attribute) and `$search` (searchable columns)
- [ ] Group related resources with `public static $group`
- [ ] Add `creationRules('unique:...')` / `updateRules('unique:...,{{resourceId}}')`
- [ ] Eager-load relations via `public static $with` to avoid N+1 in fields
- [ ] Use `final` classes; declare `strict_types=1`

### Fields
- [ ] Use `->sortable()` on index columns; `->hideFromIndex()` liberally
- [ ] Transform with `Computed` instead of raw model accessors for currency/dates
- [ ] Conditional logic via `->dependsOn(...)` (show/hide/rules)
- [ ] Gate sensitive fields with `->canSee(fn (...) => ...)`

### Actions
- [ ] Return `Action::message(...)` / `danger()` / `redirect()` / `download()`
- [ ] Add `$confirmText` / `$confirmButtonText` for destructive actions
- [ ] Use `$onQueue` + `$connection` for heavy (queued) actions
- [ ] Implement `authorizedToRun()` and `authorizedToSee()`

### Metrics
- [ ] Implement `ranges()` and `uriKey()`
- [ ] Always implement `cacheFor()` for performance
- [ ] Use `Value` / `Trend` / `Partition` base classes

### Authorization
- [ ] Define a `viewNova` Gate in `NovaServiceProvider::gate()`
- [ ] Implement model Policies (Nova auto-uses them)
- [ ] Set `public static function authorizable(): bool`

## Common Pitfalls

1. **Missing license/composer repository** — configure `repositories.nova` before `composer require`
2. **Assets not published** — run `php artisan nova:publish` after Nova updates
3. **Resource not registered** — place in `app/Nova/` (auto-discovered) or register in `NovaServiceProvider::resources()`
4. **N+1 in fields** — eager-load via `static $with`; careful with `resolveUsing` counts
5. **No metric caching** — implement `cacheFor()` on every metric
6. **Missing unique rules** — `creationRules`/`updateRules` with `{{resourceId}}`
7. **Action returns nothing** — always return an `Action::` response

## Related Commands

```bash
php artisan nova:resource Product
php artisan nova:action ApproveOrder --queued
php artisan nova:filter OrderStatus
php artisan nova:lens MostValuableUsers
php artisan nova:metric TotalRevenue --value  # --trend / --partition
php artisan nova:card SalesChart
php artisan nova:tool Analytics
```

## Related Skills

- `laravel-filament` — free/open-source admin alternative
- `laravel-feature` — feature-based organization
- `laravel-testing` — testing Nova functionality
- `laravel-auth` — user authentication for Nova
- `laravel-database` — database optimization for Nova queries

## Additional references

- License, install, resources, fields, relationships, authorization, customization → [references/resources-and-fields.md](references/resources-and-fields.md)
- Actions, lenses, metrics, custom dashboards → [references/actions-lenses-metrics.md](references/actions-lenses-metrics.md)
- Filters, custom tools, testing, pitfalls, package integration, best practices, commands → [references/filters-and-custom-tools.md](references/filters-and-custom-tools.md)
