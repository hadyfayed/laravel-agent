---
name: upgrade-laravel
description: >
  Upgrade Laravel/PHP versions (9→10→11→12, PHP 8.1→8.4) — breaking changes, automated fixes,
  dependency bumps. Perform version-by-version migration with validation. Triggers: "upgrade", "upgrade Laravel", "version bump", "breaking changes".
disable-model-invocation: true
allowed-tools: Bash(composer *) Bash(php artisan *) Read Grep Glob Edit
argument-hint: "<target-version> [--check-only|--dry-run]"
---

## Input

- **Target version:** `11`, `11.x`, `latest` (for Laravel); or `8.3`, `8.4` (for PHP)
- **Options:** `--check-only` (only check compatibility), `--dry-run` (show changes without applying)

Examples:
```
Target: 11
Options: --check-only

Target: 11.x
Target: latest
Target: 8.3
```

## Supported upgrade paths

| From | To | Status |
|------|----|--------|
| Laravel 8.x | Laravel 9.x | ✅ Supported |
| Laravel 9.x | Laravel 10.x | ✅ Supported |
| Laravel 10.x | Laravel 11.x | ✅ Supported |
| Laravel 11.x | Laravel 12.x | ✅ Supported |
| PHP 8.1 | PHP 8.2 | ✅ Supported |
| PHP 8.2 | PHP 8.3 | ✅ Supported |
| PHP 8.3 | PHP 8.4 | ✅ Supported |

## Upgrade process

1. **Pre-upgrade assessment** — check versions, tests, dependencies
2. **Identify breaking changes** — see `references/version-breaking-changes.md`
3. **Backup & branch** — git backup and database snapshot
4. **Update dependencies** — composer.json version constraints
5. **Run migrations** — database schema updates
6. **Fix code** — apply deprecated method fixes, type hints
7. **Verify tests** — ensure all tests pass
8. **Deploy** — follow `references/deployment-guide.md`

## Pre-upgrade checklist

- Git status clean: `git status --porcelain`
- Tests passing: `php artisan test`
- Composer valid: `composer validate`
- Database backed up
- All PRs merged
- Documentation reviewed

## Post-upgrade checklist

- Tests passing: `php artisan test`
- Code formatted: `vendor/bin/pint` (if installed)
- Static analysis clean: `./vendor/bin/phpstan` (if installed)
- Database migrations run: `php artisan migrate --force`
- Caches warmed: `php artisan config:cache route:cache`
- Queue workers restarted
- Scheduled tasks verified

## Skip checks with options

```bash
# Dry run (no changes)
/laravel-agent:upgrade-laravel 11 --dry-run

# Check only (analyze, no upgrade)
/laravel-agent:upgrade-laravel 11 --check-only

# Force (skip warnings)
/laravel-agent:upgrade-laravel 11 --force
```

## Rollback procedure

If upgrade fails:

```bash
# Restore composer.lock
cp composer.lock.backup composer.lock
composer install

# Restore database
php artisan backup:restore --source=local

# Or revert commits
git reset --hard pre-upgrade-backup
```

## Common issues & solutions

See `references/troubleshooting.md` for:
- PHP version mismatch
- Incompatible packages
- Test failures
- Database issues
- Custom code compatibility

## Related migration topics

- **Legacy migrations** — use `/laravel-agent:migrate-from-legacy` for framework swaps
- **Code refactoring** — use `/laravel-agent:laravel-refactor` after upgrade
- **Dependency updates** — `composer outdated` to find compatible versions
