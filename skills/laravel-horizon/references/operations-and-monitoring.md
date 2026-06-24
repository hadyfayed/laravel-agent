# Laravel Horizon Operations and Monitoring Reference

Notifications, running Horizon, Supervisor config, deployment, metrics, failed jobs, and silencing for Laravel Horizon.

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
