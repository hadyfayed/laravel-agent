---
name: telescope-setup
description: Install and configure Laravel Telescope — debugging, request/exception/query inspection, watchers, auth gating, pruning, production guards. Triggers: "Telescope", "debugging", "when adding Telescope", "when adding debugging".
disable-model-invocation: true
allowed-tools: Bash(composer *) Bash(php artisan *) Read Write Edit
argument-hint: "[--local-only] [--with-pruning]"
---

## Task

Install and configure Laravel Telescope for debugging and monitoring. Optionally use `--local-only` to restrict to local environment only, or `--with-pruning` to add scheduled pruning. If omitted, run interactively.

## Steps

### 1. Install Package

```bash
composer require laravel/telescope
php artisan telescope:install
php artisan migrate
```

### 2. Configure Environment (config/telescope.php)

Key settings:

```php
'enabled' => env('TELESCOPE_ENABLED', true),

'watchers' => [
    // Request, Exception, Query, Model, Job, Mail, Notification, Cache, etc.
    Watchers\QueryWatcher::class => [
        'enabled' => true,
        'slow' => 100,  // slow query threshold (ms)
    ],
    // ... (published defaults are comprehensive)
],
```

### 3. Authorization (Production)

Configure `app/Providers/TelescopeServiceProvider.php` with filtering, sensitivity masking, and gate authorization. See `references/telescope-auth.md` for detailed examples and production setup.

### 4. Local-Only Setup (Optional)

In `app/Providers/AppServiceProvider.php`, conditionally register Telescope:

```php
public function register(): void
{
    if ($this->app->environment('local')) {
        $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
        $this->app->register(TelescopeServiceProvider::class);
    }
}
```

Update `composer.json`:

```json
{
    "extra": {
        "laravel": {
            "dont-discover": ["laravel/telescope"]
        }
    }
}
```

### 5. Pruning (Optional)

In `app/Console/Kernel.php` or `routes/console.php`:

```php
use Illuminate\Support\Facades\Schedule;

Schedule::command('telescope:prune --hours=48')->daily();
```

## Environment Variables

```env
TELESCOPE_ENABLED=true
TELESCOPE_DOMAIN=
TELESCOPE_PATH=telescope
```

## Watchers Overview

Telescope records: Requests, Exceptions, Queries, Models, Jobs, Events, Mail, Notifications, Cache, Logs, Commands, Schedule, Redis, Dumps, Gates, Batches.

See the **laravel-telescope** reference skill for detailed watcher configuration, custom tags, and production best practices.

## Output

Report installation status, watchers enabled, authorization gate configured, and next steps (pruning schedule, admin access, sensitivity masking).

## Commands

```bash
php artisan telescope:clear      # Clear all entries
php artisan telescope:prune --hours=48
php artisan telescope:publish    # After package updates
```

## Access

- **URL**: `/telescope`
- **Authorization**: Gate `viewTelescope`
