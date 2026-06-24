---
name: pulse-setup
description: Set up Laravel Pulse performance monitoring — cards, recorders, custom metrics, dashboard auth; when adding app monitoring.
disable-model-invocation: true
allowed-tools: Bash(composer require) Bash(composer show *) Bash(php artisan *) Read Write Edit
argument-hint: "[--with-server-metrics] [--with-redis-ingest] [--custom-recorders]"
---

## Environment

Installed monitoring packages:
!`composer show laravel/pulse 2>/dev/null && echo "pulse=yes" || echo "pulse=no"`

## Task

Install and configure Laravel Pulse for real-time production monitoring of application performance, slow queries, exceptions, cache usage, queue health, and optionally server metrics.

## Steps

1. **Install package and publish config**:
   ```bash
   composer require laravel/pulse
   php artisan vendor:publish --provider="Laravel\Pulse\PulseServiceProvider"
   php artisan migrate
   ```

2. **Configure dashboard authorization** in `app/Providers/AppServiceProvider.php` (boot method):
   ```php
   Gate::define('viewPulse', function ($user) {
       return $user->isAdmin();
   });
   ```

3. **Configure recorders** in `config/pulse.php`:
   - Enable/disable recorders based on `$ARGUMENTS`: `CacheInteractions`, `Exceptions`, `Queues`, `Requests`, `SlowJobs`, `SlowOutgoingRequests`, `SlowQueries`, `SlowRequests`, `UserJobs`, `UserRequests`.
   - Set sample rates and ignore patterns (e.g., skip `/pulse`, `/telescope`, `/horizon` routes).
   - See `references/recorders-config.md` for full recorder list and threshold options.

4. **Configure storage and ingest**:
   - Default: database storage, sync ingest.
   - If `--with-redis-ingest`: switch to Redis ingest driver for high-traffic apps (add `pulse:work` to scheduler).
   - See `references/storage-ingest.md` for optimization.

5. **Customize dashboard** (optional):
   ```bash
   php artisan vendor:publish --tag=pulse-dashboard
   ```
   - Edit `resources/views/vendor/pulse/dashboard.blade.php` to add/remove cards.

6. **Schedule server metrics** (optional, if `--with-server-metrics`):
   ```bash
   $schedule->command('pulse:check')->everyFiveSeconds();
   ```

7. **Report**:
   - List installed packages, routes configured, recorders enabled, and commands available.

## Commands Available

```bash
php artisan pulse:check          # Run server metrics (high-frequency)
php artisan pulse:work           # Process Redis ingest queue
php artisan pulse:clear          # Clear old data
php artisan pulse:restart        # Restart recorders
```

## Reference

Detailed recorder configuration, custom recorders, custom cards, storage drivers, and high-traffic optimization: `references/recorders-config.md` and `references/storage-ingest.md`.
