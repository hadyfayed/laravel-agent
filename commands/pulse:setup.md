---
description: "Setup Laravel Pulse for production monitoring and performance insights"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /pulse:setup - Laravel Pulse Setup

Setup Laravel Pulse for real-time production monitoring with application performance insights, slow queries, exceptions, cache usage, queue health, and server metrics.

## Usage

```bash
/laravel-agent:pulse:setup [--with-server-metrics] [--custom-recorders]
```

## Input
$ARGUMENTS = Optional flags for configuration

## Examples

```bash
/laravel-agent:pulse:setup                        # Full setup
/laravel-agent:pulse:setup --with-server-metrics  # Include server CPU/memory
/laravel-agent:pulse:setup --custom-recorders     # Add custom metric recorders
```

## Installation Steps

### 1. Install Package

```bash
composer require laravel/pulse

# Publish configuration and migrations
php artisan vendor:publish --provider="Laravel\Pulse\PulseServiceProvider"
php artisan migrate
```

### 2. Configuration

```php
<?php

// config/pulse.php
return [
    'domain' => env('PULSE_DOMAIN'),
    'path' => env('PULSE_PATH', 'pulse'),

    'enabled' => env('PULSE_ENABLED', true),

    'storage' => [
        'driver' => env('PULSE_STORAGE_DRIVER', 'database'),
        'database' => [
            'connection' => env('PULSE_DB_CONNECTION', null),
            'chunk' => 1000,
        ],
    ],

    'ingest' => [
        'driver' => env('PULSE_INGEST_DRIVER', 'storage'),
        'buffer' => env('PULSE_INGEST_BUFFER', 5000),
        'trim' => [
            'lottery' => [1, 1000],
            'keep' => '7 days',
        ],
        'redis' => [
            'connection' => env('PULSE_REDIS_CONNECTION'),
            'chunk' => 1000,
        ],
    ],

    'cache' => env('PULSE_CACHE_DRIVER'),

    'recorders' => [
        // Application metrics
        Recorders\CacheInteractions::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'ignore' => [
                '/^laravel:pulse:/',
                '/^telescope:/',
            ],
            'groups' => [
                '/^user:/' => 'user:*',
            ],
        ],

        Recorders\Exceptions::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'location' => true,
            'ignore' => [
                // Ignored exception classes
            ],
        ],

        Recorders\Queues::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'ignore' => [
                // Ignored job classes
            ],
        ],

        Recorders\Requests::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'ignore' => [
                '#^/pulse$#',
                '#^/telescope#',
                '#^/horizon#',
            ],
        ],

        Recorders\SlowJobs::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'threshold' => 1000, // milliseconds
            'ignore' => [],
        ],

        Recorders\SlowOutgoingRequests::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'threshold' => 1000,
            'ignore' => [],
        ],

        Recorders\SlowQueries::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'threshold' => 1000,
            'ignore' => [
                '/^select .* from `pulse_/i',
            ],
            'location' => true,
        ],

        Recorders\SlowRequests::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'threshold' => 1000,
            'ignore' => [],
        ],

        Recorders\UserJobs::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'ignore' => [],
        ],

        Recorders\UserRequests::class => [
            'enabled' => true,
            'sample_rate' => 1,
            'ignore' => [],
        ],

        // Server metrics (requires pulse:check command)
        Recorders\Servers::class => [
            'enabled' => true,
            'sample_rate' => 1,
        ],
    ],
];
```

### 3. Dashboard Authorization

```php
<?php

// app/Providers/AppServiceProvider.php

use Illuminate\Support\Facades\Gate;
use Laravel\Pulse\Facades\Pulse;

public function boot(): void
{
    Gate::define('viewPulse', function ($user) {
        return $user->isAdmin();
    });

    // Customize user resolution
    Pulse::user(fn ($user) => [
        'name' => $user->name,
        'email' => $user->email,
        'avatar' => $user->profile_photo_url,
    ]);
}
```

### 4. Dashboard Customization

```php
<?php

// resources/views/vendor/pulse/dashboard.blade.php
// Run: php artisan vendor:publish --tag=pulse-dashboard

<x-pulse>
    <livewire:pulse.servers cols="full" />

    <livewire:pulse.usage cols="4" rows="2" />

    <livewire:pulse.queues cols="4" />

    <livewire:pulse.cache cols="4" />

    <livewire:pulse.slow-queries cols="8" />

    <livewire:pulse.exceptions cols="6" />

    <livewire:pulse.slow-requests cols="6" />

    <livewire:pulse.slow-jobs cols="6" />

    <livewire:pulse.slow-outgoing-requests cols="6" />
</x-pulse>
```

### 5. Server Metrics (Optional)

```bash
# Add to scheduler for server metrics
# routes/console.php

use Illuminate\Support\Facades\Schedule;

Schedule::command('pulse:check')->everyFiveSeconds();

# Or run as daemon
php artisan pulse:check
```

### 6. Custom Recorder

```php
<?php

namespace App\Pulse\Recorders;

use Illuminate\Config\Repository;
use Laravel\Pulse\Pulse;
use Laravel\Pulse\Recorders\Concerns\Sampling;

class ApiCalls
{
    use Sampling;

    public function __construct(
        protected Pulse $pulse,
        protected Repository $config,
    ) {}

    public function register($callback, $app): void
    {
        $app['events']->listen(ApiCallMade::class, function ($event) {
            if (!$this->shouldSample()) {
                return;
            }

            $this->pulse->record(
                type: 'api_call',
                key: $event->endpoint,
                value: $event->duration,
            )->count()->max();
        });
    }
}
```

### 7. Custom Card

```php
<?php

namespace App\Livewire\Pulse;

use Laravel\Pulse\Livewire\Card;
use Livewire\Attributes\Lazy;

#[Lazy]
class ApiCalls extends Card
{
    public function render()
    {
        $apiCalls = $this->aggregate('api_call', ['count', 'max']);

        return view('livewire.pulse.api-calls', [
            'apiCalls' => $apiCalls,
        ]);
    }
}
```

## Recorders Overview

| Recorder | Metrics |
|----------|---------|
| Servers | CPU, memory usage per server |
| Requests | Request count, slow requests |
| Queues | Queue depth, jobs processed |
| Cache | Hit rate, misses, size |
| SlowQueries | Queries over threshold |
| Exceptions | Exception count by type |
| SlowJobs | Jobs over threshold |
| SlowOutgoingRequests | HTTP client slowness |
| UserRequests | Requests per user |
| UserJobs | Jobs dispatched per user |

## Environment Variables

```env
PULSE_ENABLED=true
PULSE_DOMAIN=
PULSE_PATH=pulse
PULSE_STORAGE_DRIVER=database
PULSE_DB_CONNECTION=mysql
PULSE_INGEST_DRIVER=storage
PULSE_CACHE_DRIVER=redis
```

## High-Traffic Optimization

```php
<?php

// Use Redis ingest for high traffic
// config/pulse.php
'ingest' => [
    'driver' => 'redis',
    'redis' => [
        'connection' => 'pulse',
        'chunk' => 1000,
    ],
],

// Add Redis connection
// config/database.php
'redis' => [
    'pulse' => [
        'url' => env('PULSE_REDIS_URL'),
        'host' => env('PULSE_REDIS_HOST', '127.0.0.1'),
        'port' => env('PULSE_REDIS_PORT', '6379'),
        'database' => env('PULSE_REDIS_DB', '3'),
    ],
],

// Run worker to process Redis entries
// In scheduler:
Schedule::command('pulse:work')->everyFiveSeconds();
```

## Output

```markdown
## pulse:setup Complete

### Summary
- **Storage**: Database
- **Ingest**: Storage (sync)
- **Retention**: 7 days
- **Server Metrics**: Enabled

### Files Created/Modified
- `config/pulse.php` - Configuration
- `database/migrations/*_create_pulse_tables.php`
- `resources/views/vendor/pulse/dashboard.blade.php`

### Recorders Enabled
- Servers (CPU, Memory)
- Requests, SlowRequests
- Queues, SlowJobs
- SlowQueries (>1000ms)
- Exceptions
- Cache, UserRequests

### Commands
```bash
# Server metrics (add to scheduler)
php artisan pulse:check

# Process Redis queue (high traffic)
php artisan pulse:work

# Clear old data
php artisan pulse:clear

# Restart recorders
php artisan pulse:restart
```

### Access
- URL: /pulse
- Authorization: Admin gate

### Next Steps
1. Configure gate authorization
2. Add pulse:check to scheduler
3. Customize dashboard layout
4. Set up alerts for thresholds
```

## Telescope vs Pulse

| Feature | Telescope | Pulse |
|---------|-----------|-------|
| Purpose | Debugging | Monitoring |
| Environment | Development | Production |
| Detail Level | Very detailed | Aggregated |
| Performance | Heavier | Lightweight |
| Retention | Hours/Days | Days/Weeks |

**Use Telescope** for development debugging.
**Use Pulse** for production monitoring.

## Related Commands

- [/laravel-agent:telescope:setup](/commands/telescope-setup.md) - Development debugging
- [/laravel-agent:horizon:setup](/commands/horizon-setup.md) - Queue monitoring
- [/laravel-agent:db:optimize](/commands/db-optimize.md) - Query optimization
