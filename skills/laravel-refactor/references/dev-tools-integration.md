# Development Tools Integration

## Checking Available Tools

```bash
# Check for development tools
composer show barryvdh/laravel-ide-helper 2>/dev/null && echo "IDE_HELPER=yes" || echo "IDE_HELPER=no"
composer show barryvdh/laravel-debugbar 2>/dev/null && echo "DEBUGBAR=yes" || echo "DEBUGBAR=no"
composer show nunomaduro/larastan 2>/dev/null && echo "LARASTAN=yes" || echo "LARASTAN=no"
composer show laravel/pint 2>/dev/null && echo "PINT=yes" || echo "PINT=no"
composer show laravel/telescope 2>/dev/null && echo "TELESCOPE=yes" || echo "TELESCOPE=no"
```

## Laravel IDE Helper

If `barryvdh/laravel-ide-helper` is installed, update helpers after refactoring:

```bash
# After modifying models
php artisan ide-helper:models -N

# After modifying facades or service providers
php artisan ide-helper:generate

# Update PhpStorm meta
php artisan ide-helper:meta
```

**Use for refactoring:**
- Check `_ide_helper_models.php` for model method/property references
- Use generated type hints to identify unused methods
- Leverage PHPDoc to understand relationships before refactoring

## Laravel DebugBar

If `barryvdh/laravel-debugbar` is installed, profile before and after refactoring:

```php
// Measure execution time
\Debugbar::startMeasure('before-refactor', 'Original Implementation');
$originalResult = $this->originalMethod();
\Debugbar::stopMeasure('before-refactor');

// Compare query counts
// Original: Check N+1 issues in Queries tab
// After: Verify query count reduction
```

**Performance metrics to check:**
- Query count and duration
- Memory usage
- View render time
- Cache hits/misses

## Larastan (Static Analysis)

If `nunomaduro/larastan` is installed, run static analysis:

```bash
# Run analysis
./vendor/bin/phpstan analyse --level=5

# Analyze specific paths
./vendor/bin/phpstan analyse app/Services app/Actions

# Generate baseline (ignore existing errors)
./vendor/bin/phpstan analyse --generate-baseline
```

**Common Larastan fixes:**
- Add proper type hints: `public function process(array $data): void`
- Add @property PHPDoc for dynamic properties
- Add @method PHPDoc for builder methods

## Laravel Pint (Code Formatting)

If `laravel/pint` is installed, always format after refactoring:

```bash
# Format all changed files
vendor/bin/pint

# Format specific file
vendor/bin/pint app/Services/OrderService.php

# Check only (no changes)
vendor/bin/pint --test
```

## Laravel Telescope

If `laravel/telescope` is installed, use it for deep debugging:

```bash
# Access Telescope dashboard
# Navigate to: /telescope (in browser)

# Commands
php artisan telescope:clear      # Clear all Telescope data
php artisan telescope:prune      # Prune old entries (default: 24 hours)
php artisan telescope:publish    # Publish assets
```

**Telescope watchers for refactoring:**

| Watcher | Use Case |
|---------|----------|
| Queries | Identify N+1 issues, slow queries |
| Models | Track model events, hydration counts |
| Requests | Profile request duration, memory |
| Commands | Debug artisan command execution |
| Jobs | Monitor queue job performance |
| Cache | Verify cache hit/miss ratios |

**Before/After profiling:**
```php
use Laravel\Telescope\Telescope;

Telescope::tag(fn () => ['refactor:before']);
// ... run original code ...
Telescope::tag(fn () => ['refactor:after']);
// ... run refactored code ...

// Filter in dashboard by tag to compare
```
