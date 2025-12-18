---
name: laravel-horizon
description: >
  Configure and manage Laravel Horizon for Redis queue monitoring. Use when the user needs
  queue dashboards, failed job management, metrics, or worker configuration.
  Triggers: "horizon", "queue dashboard", "failed jobs", "queue metrics", "worker status",
  "queue monitoring", "redis queue", "job status".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Horizon Skill

Monitor and manage Redis queues with Laravel Horizon.

## When to Use

- Setting up queue monitoring dashboard
- Configuring worker processes
- Managing failed jobs
- Monitoring queue metrics
- Balancing queue workers
- Configuring job tags and batches

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

## Notifications

```php
<?php

// app/Providers/HorizonServiceProvider.php
use Laravel\Horizon\Horizon;

public function boot(): void
{
    parent::boot();

    Horizon::routeSlackNotificationsTo(
        env('SLACK_WEBHOOK_URL'),
        '#horizon-alerts'
    );

    Horizon::routeMailNotificationsTo('admin@example.com');

    // Wait time alerts (seconds)
    Horizon::routeLongWaitTimeNotificationsTo(
        env('SLACK_WEBHOOK_URL'),
        60 // Alert if jobs wait > 60 seconds
    );
}
```

## Running Horizon

```bash
# Start Horizon
php artisan horizon

# Pause processing
php artisan horizon:pause

# Resume processing
php artisan horizon:continue

# Graceful terminate
php artisan horizon:terminate

# Check status
php artisan horizon:status

# Clear all jobs
php artisan horizon:clear

# View failed jobs
php artisan horizon:failed
```

## Supervisor Configuration

```ini
[program:horizon]
process_name=%(program_name)s
command=php /var/www/html/artisan horizon
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/horizon.log
stopwaitsecs=3600
```

## Deployment

```bash
# In deployment script
php artisan horizon:terminate

# Horizon will restart automatically via Supervisor
```

## Metrics & Monitoring

```php
// Check queue metrics programmatically
use Laravel\Horizon\Contracts\MetricsRepository;

$metrics = app(MetricsRepository::class);

// Get throughput
$throughput = $metrics->throughput();

// Get job runtime
$runtime = $metrics->runtimeForJob('App\Jobs\ProcessOrder');

// Get queue wait time
$waitTime = $metrics->queueWaitTime('default');
```

## Failed Jobs

```php
// Retry all failed jobs
php artisan horizon:forget-failed

// Retry specific job
php artisan queue:retry <job-id>

// Handle in code
use Laravel\Horizon\Contracts\JobRepository;

$jobs = app(JobRepository::class);
$failed = $jobs->getFailed();

foreach ($failed as $job) {
    $jobs->retry($job->id);
}
```

## Silencing Jobs

```php
// Don't show in Horizon dashboard
use Laravel\Horizon\Contracts\Silenced;

final class HeartbeatJob implements ShouldQueue, Silenced
{
    // Job won't appear in Horizon
}

// Or in config
'silenced' => [
    App\Jobs\HeartbeatJob::class,
],
```

## Common Pitfalls

1. **Not Running Horizon as Daemon**
   ```bash
   # Wrong - runs in foreground
   php artisan horizon

   # Right - use Supervisor
   [program:horizon]
   command=php /var/www/html/artisan horizon
   autostart=true
   autorestart=true
   ```

2. **Forgetting to Terminate on Deploy**
   ```bash
   # Add to deployment script
   php artisan horizon:terminate
   ```

3. **Wrong Redis Configuration**
   ```env
   # Ensure Redis is configured
   QUEUE_CONNECTION=redis
   REDIS_HOST=127.0.0.1
   REDIS_PORT=6379
   ```

4. **Not Setting Memory Limits**
   ```php
   'supervisor-1' => [
       'memory' => 128, // MB
   ],
   ```

5. **Missing Authorization**
   ```php
   // Horizon accessible by anyone without gate
   Gate::define('viewHorizon', function ($user) {
       return $user->isAdmin();
   });
   ```

6. **Not Monitoring Wait Times**
   ```php
   Horizon::routeLongWaitTimeNotificationsTo(
       env('SLACK_WEBHOOK_URL'),
       60
   );
   ```

## Best Practices

- Use Supervisor for process management
- Configure auto-scaling for production
- Set up Slack/email notifications
- Monitor queue wait times
- Tag jobs for filtering
- Terminate Horizon on deploy
- Set appropriate memory limits
- Use separate queues for priorities
- Silence frequent health check jobs
- Review failed jobs regularly

## Related Commands

- `/laravel-agent:job:make` - Create queued jobs

## Related Skills

- `laravel-queue` - Queue and job implementation
- `laravel-deploy` - Production deployment
