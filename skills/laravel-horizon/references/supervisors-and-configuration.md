# Laravel Horizon Configuration and Supervisors Reference

Installation, configuration, authorization, worker/supervisor setup, multi-queue layouts, auto-scaling, and job tags for Laravel Horizon.

## Quick Start

```bash
composer require laravel/horizon
php artisan horizon:install
php artisan migrate
```

## Installation

```bash
# Install Horizon
composer require laravel/horizon

# Publish config and assets
php artisan horizon:install

# Run migrations for failed jobs table
php artisan migrate

# Access dashboard at /horizon
```

## Configuration

```php
<?php

// config/horizon.php
return [
    'domain' => env('HORIZON_DOMAIN'),
    'path' => 'horizon',

    'use' => 'default',

    'prefix' => env('HORIZON_PREFIX', 'horizon:'),

    'middleware' => ['web'],

    'waits' => [
        'redis:default' => 60,
    ],

    'trim' => [
        'recent' => 60,
        'pending' => 60,
        'completed' => 60,
        'recent_failed' => 10080,
        'failed' => 10080,
        'monitored' => 10080,
    ],

    'silenced' => [
        // App\Jobs\ExampleJob::class,
    ],

    'metrics' => [
        'trim_snapshots' => [
            'job' => 24,
            'queue' => 24,
        ],
    ],

    'fast_termination' => false,

    'memory_limit' => 64,

    'defaults' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default'],
            'balance' => 'auto',
            'autoScalingStrategy' => 'time',
            'maxProcesses' => 1,
            'maxTime' => 0,
            'maxJobs' => 0,
            'memory' => 128,
            'tries' => 1,
            'timeout' => 60,
            'nice' => 0,
        ],
    ],

    'environments' => [
        'production' => [
            'supervisor-1' => [
                'maxProcesses' => 10,
                'balanceMaxShift' => 1,
                'balanceCooldown' => 3,
            ],
        ],

        'local' => [
            'supervisor-1' => [
                'maxProcesses' => 3,
            ],
        ],
    ],
];
```

## Authorization

```php
<?php

// app/Providers/HorizonServiceProvider.php
namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Laravel\Horizon\Horizon;
use Laravel\Horizon\HorizonApplicationServiceProvider;

class HorizonServiceProvider extends HorizonApplicationServiceProvider
{
    protected function gate(): void
    {
        Gate::define('viewHorizon', function ($user) {
            return in_array($user->email, [
                'admin@example.com',
            ]);
        });
    }

    public function boot(): void
    {
        parent::boot();

        // Horizon::night(); // Dark mode
    }
}
```

## Worker Configuration

### Multi-Queue Setup

```php
'environments' => [
    'production' => [
        'supervisor-high' => [
            'connection' => 'redis',
            'queue' => ['high'],
            'balance' => 'simple',
            'maxProcesses' => 5,
            'tries' => 3,
        ],
        'supervisor-default' => [
            'connection' => 'redis',
            'queue' => ['default'],
            'balance' => 'auto',
            'maxProcesses' => 10,
        ],
        'supervisor-low' => [
            'connection' => 'redis',
            'queue' => ['low'],
            'balance' => 'simple',
            'maxProcesses' => 3,
        ],
    ],
],
```

### Auto-Scaling

```php
'supervisor-1' => [
    'balance' => 'auto',
    'autoScalingStrategy' => 'time', // or 'size'
    'minProcesses' => 1,
    'maxProcesses' => 10,
    'balanceMaxShift' => 1,
    'balanceCooldown' => 3,
],
```

## Job Tags

```php
<?php

namespace App\Jobs;

use Laravel\Horizon\Contracts\Silenced;

final class ProcessOrder implements ShouldQueue
{
    public function tags(): array
    {
        return [
            'order',
            'order:'.$this->order->id,
            'user:'.$this->order->user_id,
        ];
    }
}
```
