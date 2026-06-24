---
name: health-setup
description: Set up application health checks and uptime monitoring with spatie/laravel-health — checks, scheduling, dashboard, notifications; when adding health monitoring.
disable-model-invocation: true
allowed-tools: Bash(composer require) Bash(composer show *) Bash(php artisan *) Read Write Edit
argument-hint: "[--checks=db,cache,redis,queue,storage,schedule]"
---

## Environment

Installed health packages:
!`composer show spatie/laravel-health 2>/dev/null && echo "laravel-health=yes" || echo "laravel-health=no"`

## Task

Install and configure comprehensive health checks using spatie/laravel-health.

## Steps

1. **Install package**:
   ```bash
   composer require spatie/laravel-health
   ```

2. **Publish config and migrations**:
   ```bash
   php artisan vendor:publish --tag="health-config"
   php artisan vendor:publish --tag="health-migrations"
   php artisan migrate
   ```

3. **Register health checks** in `app/Providers/AppServiceProvider.php` (boot method):
   - Use `Health::checks([...])` to register checks from `$ARGUMENTS` or defaults (database, cache, redis, queue, disk, schedule).
   - See `references/checks-reference.md` for full check list and configuration options.

4. **Add routes** in `routes/web.php`:
   ```php
   Route::middleware(['auth', 'can:viewHealth'])->group(function () {
       Route::get('/health', HealthCheckResultsController::class);
   });
   Route::get('/api/health', HealthCheckJsonResultsController::class);
   ```

5. **Schedule health checks** in `app/Console/Kernel.php`:
   ```bash
   $schedule->command('health:check')->everyMinute();
   ```

6. **Configure notifications** (optional):
   - Edit `config/health.php` to enable mail/Slack/Discord notifications on check failure.
   - Set throttle window to avoid alert fatigue (default: 60 min).

7. **Report**:
   - List installed packages, routes added, checks registered, and commands available.

## Commands Available

```bash
php artisan health:check            # Run all checks
php artisan health:list             # List configured checks
php artisan health:check --fresh    # Clear cache and re-run
```

## Reference

Detailed check types, threshold configuration, custom checks, and notification setup: `references/checks-reference.md`.
