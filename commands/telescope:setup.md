---
description: "Setup Laravel Telescope for debugging and monitoring"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /telescope:setup - Laravel Telescope Setup

Setup Laravel Telescope for elegant debugging, request inspection, exceptions, logs, database queries, jobs, mail, notifications, and cache operations.

## Usage

```bash
/laravel-agent:telescope:setup [--local-only] [--with-pruning]
```

## Input
$ARGUMENTS = Optional flags for configuration

## Examples

```bash
/laravel-agent:telescope:setup                    # Full setup
/laravel-agent:telescope:setup --local-only       # Only enable in local environment
/laravel-agent:telescope:setup --with-pruning     # Add scheduled pruning
```

## Installation Steps

### 1. Install Package

```bash
composer require laravel/telescope

# Publish assets and migrations
php artisan telescope:install
php artisan migrate
```

### 2. Configuration

```php
<?php

// config/telescope.php
return [
    'domain' => env('TELESCOPE_DOMAIN'),
    'path' => 'telescope',
    'driver' => 'database',

    'enabled' => env('TELESCOPE_ENABLED', true),

    'middleware' => [
        'web',
        Authorize::class,
    ],

    'only_paths' => [],
    'ignore_paths' => [
        'nova-api*',
        'horizon*',
    ],
    'ignore_commands' => [],

    'watchers' => [
        Watchers\BatchWatcher::class => true,
        Watchers\CacheWatcher::class => [
            'enabled' => true,
            'hidden' => [],
        ],
        Watchers\CommandWatcher::class => [
            'enabled' => true,
            'ignore' => [],
        ],
        Watchers\DumpWatcher::class => [
            'enabled' => env('TELESCOPE_DUMP_WATCHER', true),
            'always' => false,
        ],
        Watchers\EventWatcher::class => [
            'enabled' => true,
            'ignore' => [],
        ],
        Watchers\ExceptionWatcher::class => true,
        Watchers\GateWatcher::class => [
            'enabled' => true,
            'ignore_abilities' => [],
            'ignore_packages' => true,
            'ignore_paths' => [],
        ],
        Watchers\JobWatcher::class => true,
        Watchers\LogWatcher::class => [
            'enabled' => true,
            'level' => 'error',
        ],
        Watchers\MailWatcher::class => true,
        Watchers\ModelWatcher::class => [
            'enabled' => true,
            'events' => ['eloquent.*'],
            'hydrations' => false,
        ],
        Watchers\NotificationWatcher::class => true,
        Watchers\QueryWatcher::class => [
            'enabled' => true,
            'ignore_packages' => true,
            'ignore_paths' => [],
            'slow' => 100,
        ],
        Watchers\RedisWatcher::class => true,
        Watchers\RequestWatcher::class => [
            'enabled' => true,
            'size_limit' => 64,
            'ignore_http_methods' => [],
            'ignore_status_codes' => [],
        ],
        Watchers\ScheduleWatcher::class => true,
        Watchers\ViewWatcher::class => true,
    ],
];
```

### 3. Authorization (Production)

```php
<?php

// app/Providers/TelescopeServiceProvider.php

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Laravel\Telescope\IncomingEntry;
use Laravel\Telescope\Telescope;
use Laravel\Telescope\TelescopeApplicationServiceProvider;

class TelescopeServiceProvider extends TelescopeApplicationServiceProvider
{
    public function register(): void
    {
        Telescope::night();

        $this->hideSensitiveRequestDetails();

        // Only record in local or when specifically enabled
        Telescope::filter(function (IncomingEntry $entry) {
            if ($this->app->environment('local')) {
                return true;
            }

            return $entry->isReportableException() ||
                   $entry->isFailedRequest() ||
                   $entry->isFailedJob() ||
                   $entry->isScheduledTask() ||
                   $entry->hasMonitoredTag();
        });
    }

    protected function hideSensitiveRequestDetails(): void
    {
        if ($this->app->environment('local')) {
            return;
        }

        Telescope::hideRequestParameters(['_token', 'password', 'password_confirmation']);
        Telescope::hideRequestHeaders(['cookie', 'x-csrf-token', 'x-xsrf-token']);
    }

    protected function gate(): void
    {
        Gate::define('viewTelescope', function ($user) {
            return in_array($user->email, [
                'admin@example.com',
            ]) || $user->isAdmin();
        });
    }
}
```

### 4. Local-Only Setup

```php
<?php

// app/Providers/AppServiceProvider.php

public function register(): void
{
    if ($this->app->environment('local')) {
        $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
        $this->app->register(TelescopeServiceProvider::class);
    }
}
```

```json
// composer.json
{
    "extra": {
        "laravel": {
            "dont-discover": [
                "laravel/telescope"
            ]
        }
    }
}
```

### 5. Pruning Old Entries

```php
<?php

// routes/console.php or app/Console/Kernel.php

use Illuminate\Support\Facades\Schedule;

Schedule::command('telescope:prune --hours=48')->daily();

// Or prune specific types
Schedule::command('telescope:prune --hours=24')->hourly();
```

### 6. Tagging for Filtering

```php
<?php

// In TelescopeServiceProvider

Telescope::tag(function (IncomingEntry $entry) {
    if ($entry->type === 'request') {
        return [
            'route:'.$entry->content['uri'],
            'user:'.auth()->id(),
        ];
    }

    if ($entry->type === 'job') {
        return [
            'job:'.$entry->content['name'],
        ];
    }

    return [];
});
```

## Watchers Overview

| Watcher | Records |
|---------|---------|
| Request | HTTP requests with headers, payload, response |
| Exception | All exceptions with stack traces |
| Query | Database queries with bindings and time |
| Model | Eloquent model events (created, updated, deleted) |
| Job | Queued job execution and failures |
| Event | Event dispatching |
| Mail | Sent emails with preview |
| Notification | All notifications |
| Cache | Cache hits, misses, and operations |
| Log | Log entries |
| Command | Artisan command execution |
| Schedule | Scheduled task runs |
| Redis | Redis operations |
| Dump | dump() and dd() output |
| Gate | Authorization checks |

## Environment Variables

```env
TELESCOPE_ENABLED=true
TELESCOPE_DOMAIN=
TELESCOPE_PATH=telescope
TELESCOPE_DUMP_WATCHER=true
```

## Security Best Practices

1. **Always authorize in production** - Use gate definition
2. **Hide sensitive data** - Mask passwords, tokens
3. **Prune regularly** - Don't let data grow unbounded
4. **Local-only if possible** - Disable in production
5. **Use dark mode** - `Telescope::night()` reduces eye strain

## Output

```markdown
## telescope:setup Complete

### Summary
- **Environment**: Local only|All environments
- **Pruning**: Every 48 hours
- **Authorization**: Admin users only

### Files Created/Modified
- `config/telescope.php` - Configuration
- `app/Providers/TelescopeServiceProvider.php` - Authorization & filtering
- `database/migrations/*_create_telescope_entries_table.php`

### Watchers Enabled
- Requests, Exceptions, Queries, Jobs, Mail
- Notifications, Cache, Logs, Commands
- Slow query threshold: 100ms

### Access
- URL: /telescope
- Authorization: Admin gate

### Commands
```bash
# Clear all entries
php artisan telescope:clear

# Prune old entries
php artisan telescope:prune --hours=48

# Publish assets (after updates)
php artisan telescope:publish
```

### Next Steps
1. Configure authorization gate
2. Set up pruning schedule
3. Customize watchers as needed
4. Review sensitive data filtering
```

## Related Commands

- [/laravel-agent:pulse:setup](/commands/pulse-setup.md) - Production monitoring
- [/laravel-agent:db:optimize](/commands/db-optimize.md) - Query optimization
- [/laravel-agent:review:audit](/commands/review-audit.md) - Code audit
