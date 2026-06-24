# Migration Troubleshooting Guide

## PHP Version Mismatch

### Error
```
Laravel 11 requires PHP 8.2+
```

### Solution
Upgrade PHP before upgrading Laravel:
```bash
# macOS
brew upgrade php@8.3

# Ubuntu
apt-get install php8.3

# Then update composer.json
"php": "^8.3"
```

## Incompatible Packages

### Error
```
Package X requires laravel/framework 10.x
```

### Solution
1. Check for updated version:
   ```bash
   composer show package/name --all
   ```

2. Update package:
   ```bash
   composer require package/name:^2.0 --with-all-dependencies
   ```

3. Find alternative on Packagist:
   - Search for compatible package
   - Check GitHub issues for Laravel compatibility
   - Last resort: fork and patch

## Test Failures After Upgrade

### Common Issues

**1. Assertion changes**
```php
// Old
$this->assertEquals($expected, $actual);

// New (Laravel 11+)
$this->assertSame($expected, $actual);
```

**2. Mock updates**
```php
// Old
$mock = $this->mock(Service::class);

// New
$mock = Mockery::mock(Service::class);
$this->instance(Service::class, $mock);
```

**3. Test base classes**
```php
// Update test class
class TestCase extends \Illuminate\Foundation\Testing\TestCase {
    use CreatesApplication;
    // ...
}
```

### Fix Tests
```bash
# Run tests with verbose output
php artisan test --verbose

# Run specific test file
php artisan test tests/Unit/UserTest.php

# Update PHPUnit
composer require phpunit/phpunit:^11.0 --dev
```

## Database Migration Issues

### Error: "SQLSTATE[HY000]"

**Check database connection:**
```bash
php artisan db:show
```

**Verify config:**
```php
// config/database.php
'mysql' => [
    'driver' => 'mysql',
    'host' => env('DB_HOST', 'localhost'),
    'port' => env('DB_PORT', 3306),
    'database' => env('DB_DATABASE'),
    'username' => env('DB_USERNAME'),
    'password' => env('DB_PASSWORD'),
],
```

### Error: "SQLSTATE[42S01]"

**Table already exists — skip migration:**
```bash
php artisan migrate:refresh  # Start fresh

# Or mark migration as completed
php artisan migrate:reset
php artisan migrate
```

## Deployment Issues

### Error: "Whoops, looks like something went wrong"

**Check logs:**
```bash
tail -100 storage/logs/laravel.log
```

**Clear caches:**
```bash
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
```

### Error: "Class not found"

**Regenerate autoloader:**
```bash
composer dump-autoload -o
```

**Check for typos:**
```bash
grep -r "use App\\Old" app/
```

## Performance Issues After Migration

### Slow queries

**Enable query logging:**
```php
// config/app.php or local override
'debug' => true,
```

**Check N+1 queries:**
```bash
php artisan telescope  # Visit /telescope
```

**Add eager loading:**
```php
// Before
User::all()->each(fn($u) => $u->orders);

// After
User::with('orders')->get();
```

### Memory leaks in long-running processes

**Check queue worker memory:**
```bash
php artisan queue:work --max-jobs=1000 --max-time=3600
```

**Update process manager:**
- Supervisor
- PM2
- Docker restart policy

## Custom Code Issues

### Facade/Helper changes

**Check usage:**
```bash
grep -r "Route::" app/ --include="*.php"
grep -r "DB::" app/ --include="*.php"
```

**Update deprecated methods:**
- Run `./vendor/bin/phpstan analyse --level=5`
- Review Laravel upgrade guide
- Check package changelogs

### Event & Listener changes

**Update event handlers:**
```php
// Old
Event::listen('order.created', function ($event) {});

// New
use App\Events\OrderCreated;
Event::listen(OrderCreated::class, function (OrderCreated $event) {});
```

## Rollback Safely

```bash
# Option 1: Git branch
git checkout pre-upgrade-backup

# Option 2: Database restore
php artisan backup:restore --source=local

# Option 3: Composer rollback
composer require laravel/framework:^10.0
composer update
php artisan migrate:rollback

# Option 4: Full reset
git reset --hard HEAD~N  # Go back N commits
php artisan migrate:reset
php artisan migrate
```
