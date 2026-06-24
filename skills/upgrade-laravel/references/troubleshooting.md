# Upgrade Troubleshooting

## PHP Version Mismatch

### Error
```
Laravel 11 requires PHP 8.2+
Current PHP version: 8.1.0
```

### Solution

1. **Check current PHP:**
   ```bash
   php -v
   php -r "echo PHP_VERSION_ID;"
   ```

2. **Upgrade PHP:**
   ```bash
   # macOS
   brew upgrade php@8.3

   # Ubuntu
   apt-get install php8.3

   # Docker
   docker pull php:8.3-fpm
   ```

3. **Verify in CLI and web:**
   ```bash
   # CLI
   php -v

   # Web (PHP info)
   echo '<?php phpinfo();' > info.php
   curl http://localhost/info.php
   ```

4. **Update composer.json:**
   ```json
   {
     "require": {
       "php": "^8.3"
     }
   }
   ```

5. **Reinstall:**
   ```bash
   rm composer.lock
   composer install
   ```

## Incompatible Packages

### Error
```
Your requirements could not be resolved to an installable set of packages.
Problem 1
  - laravel/framework 11.0 requires php ^8.2
  - package/name ^2.0 requires laravel/framework ^10.0
  - Only laravel/framework 11.0 is installed
```

### Solution

1. **Identify incompatible packages:**
   ```bash
   composer why-not laravel/framework:^11.0
   ```

2. **Check for updates:**
   ```bash
   composer outdated --direct
   composer show package/name --all
   ```

3. **Update packages:**
   ```bash
   # Try updating with dependency resolution
   composer require package/name:^3.0 --with-all-dependencies
   ```

4. **Find alternatives:**
   - Search Packagist for Laravel-compatible versions
   - Check GitHub releases
   - Look at package changelogs

5. **Last resort:**
   ```bash
   # Fork and patch locally
   composer require --dev symfony/var-dumper
   ```

## Test Failures

### Common Issues

**1. Assertion changes**
```php
// Before (Laravel 10)
$this->assertEquals($expected, $actual);

// After (Laravel 11) — stricter comparison
$this->assertSame($expected, $actual);
```

**2. Mock syntax**
```php
// Old
$mock = $this->mock(Service::class);
$mock->shouldReceive('method')->once();

// New
$mock = Mockery::mock(Service::class);
$mock->shouldReceive('method')->once();
$this->instance(Service::class, $mock);
```

**3. Test base class**
```php
// Update
class TestCase extends \Illuminate\Foundation\Testing\TestCase {
    use CreatesApplication;
}
```

### Fix Tests

```bash
# Run with verbose output
php artisan test --verbose

# Run single test file
php artisan test tests/Unit/UserTest.php

# Run specific test
php artisan test tests/Unit/UserTest.php::testUserCreation

# Update test dependencies
composer require phpunit/phpunit:^11.0 --dev
```

### Update Mocking Library

```bash
# Update Mockery
composer require mockery/mockery:^1.6 --dev

# Or use PHPUnit mocks
$mock = $this->createMock(Service::class);
$mock->method('get')->willReturn('value');
```

## Database Migration Issues

### Error: "SQLSTATE[HY000]"

```bash
# Check database configuration
php artisan db:show

# Verify .env
cat .env | grep DB_

# Test connection
php artisan migrate:status
```

### Error: "SQLSTATE[42S01] Table already exists"

```bash
# Fresh start
php artisan migrate:refresh

# Or specific migration
php artisan migrate:reset
php artisan migrate
```

### Error: "SQLSTATE[42S02] Table doesn't exist"

```bash
# Run pending migrations
php artisan migrate

# List status
php artisan migrate:status
```

## Deployment Issues

### Error: "Whoops, looks like something went wrong"

1. **Check logs:**
   ```bash
   tail -100 storage/logs/laravel.log
   grep -i error storage/logs/laravel.log
   ```

2. **Enable debug mode (temporarily):**
   ```bash
   # .env
   APP_DEBUG=true
   ```

3. **Clear caches:**
   ```bash
   php artisan optimize:clear
   php artisan config:clear
   php artisan route:clear
   php artisan view:clear
   ```

4. **Regenerate cache:**
   ```bash
   php artisan config:cache
   php artisan route:cache
   ```

### Error: "Class not found"

```bash
# Regenerate autoloader
composer dump-autoload -o

# Check for use statement typos
grep -r "use App\\\\Old" app/ --include="*.php"

# Update namespace if changed
grep -r "namespace App" app/ --include="*.php"
```

### Error: "Undefined method"

```bash
# Check for breaking changes in your code
grep -r "->old_method()" app/ --include="*.php"

# Generate IDE helpers
php artisan ide-helper:generate
php artisan ide-helper:models -N
```

## Performance Issues

### Slow queries after upgrade

1. **Enable query logging:**
   ```php
   // config/app.php or .env
   APP_DEBUG=true
   ```

2. **Use Laravel Telescope:**
   ```bash
   php artisan telescope:publish
   # Visit /telescope
   ```

3. **Check for N+1 queries:**
   ```php
   // Before
   $users = User::all();
   $users->each(fn($u) => echo $u->orders);  // N+1

   // After
   $users = User::with('orders')->get();
   ```

4. **Profile with DebugBar:**
   ```bash
   composer require --dev barryvdh/laravel-debugbar
   php artisan serve
   # Visit app in browser, check debugbar
   ```

### Memory leaks in processes

```bash
# Check queue worker memory
ps aux | grep artisan

# Run with memory limits
php artisan queue:work --max-jobs=1000 --max-time=3600

# Restart workers periodically
supervisorctl restart laravel-worker:*
```

## Custom Code Issues

### Facade/Helper changes

```bash
# Find deprecated usage
grep -r "Route::" app/ --include="*.php"
grep -r "DB::" app/ --include="*.php"
grep -r "Cache::" app/ --include="*.php"

# Run static analysis
./vendor/bin/phpstan analyse --level=5
```

### Event listener changes

```php
// Old (string-based)
Event::listen('order.created', function ($event) {});

// New (class-based)
use App\Events\OrderCreated;
Event::listen(OrderCreated::class, function (OrderCreated $event) {});
```

## Rollback Safely

```bash
# Option 1: Git rollback
git log --oneline | head -5
git reset --hard <commit-sha>

# Option 2: Composer rollback
cp composer.lock.backup composer.lock
composer install

# Option 3: Database rollback
php artisan migrate:rollback --step=1

# Option 4: Full restore
php artisan backup:restore --source=local

# Clear everything
php artisan optimize:clear
```
