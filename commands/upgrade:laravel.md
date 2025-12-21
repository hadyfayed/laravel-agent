---
description: "Automated Laravel version upgrades"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /upgrade:laravel - Automated Laravel Version Upgrades

Safely upgrade your Laravel application to a newer version with automated compatibility checks, code migrations, and testing.

## Usage

```bash
/laravel-agent:upgrade:laravel [target-version]
```

## Input
$ARGUMENTS = Target Laravel version (e.g., `11`, `11.x`, `latest`)

## Examples

```bash
/laravel-agent:upgrade:laravel 11
/laravel-agent:upgrade:laravel 11.x
/laravel-agent:upgrade:laravel latest
/laravel-agent:upgrade:laravel --check-only  # Only check compatibility
/laravel-agent:upgrade:laravel --dry-run     # Show changes without applying
```

## Supported Upgrade Paths

| From | To | Complexity |
|------|----|------------|
| Laravel 10.x | Laravel 11.x | Medium |
| Laravel 9.x | Laravel 10.x | Medium |
| Laravel 8.x | Laravel 9.x | Medium |
| Laravel 7.x | Laravel 8.x | High |

## Process

### 1. Pre-Upgrade Assessment

```
┌─────────────────────────────────────────────────────────────┐
│                   PRE-UPGRADE ASSESSMENT                     │
├──────────────────┬──────────────────────────────────────────┤
│ Check            │ Status                                    │
├──────────────────┼──────────────────────────────────────────┤
│ Current Version  │ Laravel 10.48.4                          │
│ Target Version   │ Laravel 11.x                             │
│ PHP Version      │ 8.2.0 ✅ (requires 8.2+)                 │
│ Composer Version │ 2.7.0 ✅                                 │
│ Git Status       │ Clean ✅                                 │
│ Tests Passing    │ 156/156 ✅                               │
│ Dependencies     │ 45 packages to check                     │
└──────────────────┴──────────────────────────────────────────┘
```

**Checks performed:**
```bash
# Check current Laravel version
php artisan --version

# Check PHP version
php -v

# Verify git status is clean
git status --porcelain

# Run existing tests
php artisan test

# Check composer.lock
composer validate
```

### 2. Dependency Compatibility Analysis

```
┌─────────────────────────────────────────────────────────────┐
│                   DEPENDENCY ANALYSIS                        │
├─────────────────────┬───────────┬───────────┬───────────────┤
│ Package             │ Current   │ Required  │ Status        │
├─────────────────────┼───────────┼───────────┼───────────────┤
│ laravel/framework   │ 10.48     │ 11.0      │ 🔄 Upgrade    │
│ spatie/laravel-perm │ 5.11      │ 6.0       │ 🔄 Upgrade    │
│ livewire/livewire   │ 3.4       │ 3.4       │ ✅ Compatible │
│ inertiajs/inertia   │ 0.6       │ 1.0       │ 🔄 Upgrade    │
│ old/deprecated-pkg  │ 2.0       │ N/A       │ ❌ Replace    │
└─────────────────────┴───────────┴───────────┴───────────────┘
```

**Analysis steps:**
1. Parse `composer.json` dependencies
2. Check each package's Laravel 11 compatibility
3. Identify required upgrades
4. Flag incompatible/deprecated packages
5. Suggest replacements for dropped packages

### 3. Breaking Changes Detection

```
┌─────────────────────────────────────────────────────────────┐
│                   BREAKING CHANGES                           │
├─────────────────────┬───────────────────────────────────────┤
│ Change              │ Affected Files                         │
├─────────────────────┼───────────────────────────────────────┤
│ Kernel.php removed  │ app/Http/Kernel.php → bootstrap/app   │
│ Route changes       │ routes/web.php, routes/api.php        │
│ Config structure    │ config/app.php                        │
│ Middleware changes  │ 5 custom middleware files             │
│ Service providers   │ 3 providers need updates              │
│ Cast classes        │ 2 custom casts                        │
└─────────────────────┴───────────────────────────────────────┘
```

**Laravel 10 → 11 specific changes:**
- `app/Http/Kernel.php` → `bootstrap/app.php`
- `app/Console/Kernel.php` → `routes/console.php`
- `app/Exceptions/Handler.php` → `bootstrap/app.php`
- Middleware registration changes
- Service provider changes
- Config file merging

### 4. Backup Creation

```bash
# Create backup branch
git checkout -b pre-upgrade-backup
git checkout -

# Create database backup
php artisan backup:run --only-db

# Export current composer.lock
cp composer.lock composer.lock.backup
```

### 5. Upgrade Execution

```
Step 1: Update composer.json
├── laravel/framework: ^11.0
├── php: ^8.2
└── Updated package constraints

Step 2: Run composer update
└── composer update --with-all-dependencies

Step 3: Migrate configuration
├── Create bootstrap/app.php
├── Migrate Kernel middleware
├── Migrate exception handling
├── Update service providers
└── Migrate route configuration

Step 4: Update application code
├── Update deprecated method calls
├── Fix type hint changes
├── Update facade usages
└── Fix constructor changes

Step 5: Update tests
├── Update test base classes
├── Fix assertion changes
└── Update mocking patterns
```

### 6. Code Migrations

**Automatic migrations performed:**

```php
// Before (Laravel 10)
// app/Http/Kernel.php
protected $middleware = [
    \App\Http\Middleware\TrustProxies::class,
    // ...
];

// After (Laravel 11)
// bootstrap/app.php
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->append(TrustProxies::class);
        // ...
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // ...
    })
    ->create();
```

### 7. Post-Upgrade Verification

```bash
# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Regenerate optimizations
php artisan config:cache
php artisan route:cache

# Run migrations
php artisan migrate

# Run test suite
php artisan test

# Start application
php artisan serve
```

### 8. Upgrade Report

```markdown
# Laravel Upgrade Report

**From:** Laravel 10.48.4
**To:** Laravel 11.0.0
**Date:** [Timestamp]
**Duration:** 15 minutes

## Summary

| Metric | Count |
|--------|-------|
| Files Modified | 23 |
| Files Created | 2 |
| Files Deleted | 3 |
| Dependencies Updated | 12 |
| Tests Updated | 5 |

## Changes Made

### Configuration
- ✅ Created `bootstrap/app.php`
- ✅ Migrated middleware from Kernel.php
- ✅ Migrated exception handling
- ✅ Updated `config/app.php`

### Dependencies
- ✅ `laravel/framework` 10.x → 11.0
- ✅ `spatie/laravel-permission` 5.x → 6.0
- ✅ `inertiajs/inertia-laravel` 0.6 → 1.0

### Code Changes
- ✅ Updated 5 controller methods
- ✅ Fixed 3 deprecated calls
- ✅ Updated 2 middleware classes

### Tests
- ✅ All 156 tests passing
- ✅ Updated 5 test files

## Manual Actions Required

1. **Review** `bootstrap/app.php` for custom configurations
2. **Update** any custom Artisan commands
3. **Check** third-party package documentation
4. **Test** all critical user flows manually

## Rollback Instructions

If issues occur:

```bash
# Restore composer.lock
cp composer.lock.backup composer.lock
composer install

# Or revert to backup branch
git checkout pre-upgrade-backup
```
```

## Upgrade Options

| Option | Description |
|--------|-------------|
| `--check-only` | Only check compatibility, don't upgrade |
| `--dry-run` | Show changes without applying |
| `--no-backup` | Skip backup creation |
| `--force` | Proceed even with warnings |
| `--step` | Upgrade one minor version at a time |

## Common Issues and Solutions

### PHP Version Mismatch

```bash
# Error: Laravel 11 requires PHP 8.2+
# Solution: Upgrade PHP first

brew upgrade php@8.3
# or
apt-get install php8.3
```

### Incompatible Packages

```bash
# Error: Package X requires laravel/framework 10.x

# Solution 1: Check for updated version
composer show package/name --all

# Solution 2: Find alternative
# Use packagist.org to find Laravel 11 compatible alternative

# Solution 3: Fork and update (last resort)
```

### Failed Tests

```bash
# Many tests failing after upgrade

# Common fixes:
# 1. Update PHPUnit version
composer require phpunit/phpunit:^11.0 --dev

# 2. Update test traits
# Replace deprecated assertions

# 3. Update mocking
# Check for Mockery/PHPUnit changes
```

### Database Issues

```bash
# Migration errors

# Check for deprecated database methods
grep -r "Schema::connection" database/migrations/

# Verify database connection
php artisan migrate:status
```

## Best Practices

1. **Always backup** before upgrading
2. **Upgrade in staging** before production
3. **Run full test suite** before and after
4. **Review upgrade guide** on laravel.com
5. **Upgrade dependencies first** if possible
6. **Keep git history clean** with atomic commits
7. **Document custom changes** for team reference

## Rollback Procedure

```bash
# If upgrade fails:

# 1. Restore composer.lock
cp composer.lock.backup composer.lock
composer install

# 2. Or use git
git checkout pre-upgrade-backup
git branch -D main
git checkout -b main

# 3. Restore database if needed
php artisan backup:restore --source=local

# 4. Clear caches
php artisan optimize:clear
```

## Related Commands

- [/laravel-agent:migrate:from-legacy](/commands/migrate-from-legacy.md) - Major version migrations
- [/laravel-agent:analyze:codebase](/commands/analyze-codebase.md) - Pre-upgrade health check
- [/laravel-agent:test:coverage](/commands/test-coverage.md) - Verify test coverage

## Related Agents

- `laravel-migration` - Database migration specialist
- `laravel-refactor` - Code refactoring
- `laravel-testing` - Test updates

## Resources

- [Laravel Upgrade Guide](https://laravel.com/docs/11.x/upgrade)
- [Laravel Shift](https://laravelshift.com/) - Automated upgrades
- [Laravel News](https://laravel-news.com/) - Version announcements
