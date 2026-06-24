---
name: migrate-from-legacy
description: >
  Migrate a legacy app/database into Laravel — schema import, data migration, model generation.
  Handles both framework migrations (Symfony→Laravel) and version upgrades (Laravel 9→10→11). 
  Triggers: "migrate", "legacy", "upgrade", "import", "framework migration", "data migration".
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Bash(composer *) Read Grep Glob Write Edit
argument-hint: "<source> [target] [--dry-run]"
---

## Input

- **Source:** legacy system identifier or Laravel version (e.g., `laravel-10`, `symfony`, `php-8.1`)
- **Target:** (optional) target version (e.g., `laravel-11`, `php-8.3`)
- **Options:** `--dry-run` (show changes without applying)

Examples:
```
Source: laravel-10
Target: laravel-11

Source: php-8.1
Target: php-8.3

Source: symfony
```

## Supported migration types

1. **Laravel version upgrades** — 9→10, 10→11, 11→12 (supports multiple intermediate steps)
2. **PHP version upgrades** — 8.1→8.2, 8.2→8.3, 8.3→8.4
3. **Framework migrations** — Symfony, CodeIgniter, generic legacy app
4. **Database/schema import** — convert from MySQL to PostgreSQL, etc.

## Pre-migration checklist

- Git status is clean: `git status --porcelain`
- Current tests passing: `php artisan test`
- Database backup created (if migrating data)
- Composer lock up to date: `composer validate`
- All branches merged to main

## Migration process

1. **Analyze breaking changes** — consult `references/breaking-changes.md` for version-specific issues
2. **Backup current state** — create git branch and database snapshot
3. **Update dependencies** — composer.json version constraints
4. **Apply automated fixes** — Rector rules, deprecated method replacements
5. **Run test suite** — verify no regressions
6. **Manual review** — check custom code for migration-specific issues
7. **Deploy** — follow release checklist from `references/release-checklist.md`

## Data migration (schema import)

See `references/data-migration.md` for:
- Schema analysis and mapping
- Data transformation pipelines
- Foreign key and index preservation
- Post-migration validation

## Rollback procedure

If migration fails:

```bash
# Restore from git
git checkout pre-upgrade-backup

# Or restore database
php artisan backup:restore --source=local

# Clear caches
php artisan optimize:clear
```

## Common issues

- **PHP version mismatch** — upgrade PHP before Laravel
- **Incompatible packages** — check Packagist for compatible versions
- **Test failures** — update test base classes and assertions
- **Database issues** — verify connection and migration status
- **Custom code** — manually review services, providers, models

See `references/troubleshooting.md` for detailed solutions.

## Post-migration validation

- All tests pass
- Database migrations complete
- Queue workers restart
- Scheduled tasks functional
- Authentication flows work
- Critical user flows tested manually
