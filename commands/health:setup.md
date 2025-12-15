---
description: "Setup application health monitoring using spatie/laravel-health"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /health:setup - Setup Health Monitoring

Configure comprehensive health checks using spatie/laravel-health.

## Input
$ARGUMENTS = `[--checks=<db,cache,redis,queue,storage,schedule>]`

Examples:
- `/health:setup` - Interactive setup with all checks
- `/health:setup --checks=db,cache,redis`

## Process

1. **Install Package**
   ```bash
   composer require spatie/laravel-health
   ```

2. **Publish Config & Migrations**
   ```bash
   php artisan vendor:publish --tag="health-config"
   php artisan vendor:publish --tag="health-migrations"
   php artisan migrate
   ```

3. **Configure Health Checks**
   - Database connection
   - Cache availability
   - Redis connection
   - Queue processing
   - Disk space
   - Schedule running
   - Custom checks

4. **Setup Routes & Dashboard**

## Configuration

### config/health.php
```php
<?php

use Spatie\Health\Checks\Checks\BackupsCheck;
use Spatie\Health\Checks\Checks\CacheCheck;
use Spatie\Health\Checks\Checks\DatabaseCheck;
use Spatie\Health\Checks\Checks\DatabaseConnectionCountCheck;
use Spatie\Health\Checks\Checks\DatabaseSizeCheck;
use Spatie\Health\Checks\Checks\DebugModeCheck;
use Spatie\Health\Checks\Checks\EnvironmentCheck;
use Spatie\Health\Checks\Checks\HorizonCheck;
use Spatie\Health\Checks\Checks\OptimizedAppCheck;
use Spatie\Health\Checks\Checks\QueueCheck;
use Spatie\Health\Checks\Checks\RedisCheck;
use Spatie\Health\Checks\Checks\ScheduleCheck;
use Spatie\Health\Checks\Checks\UsedDiskSpaceCheck;

return [
    'result_stores' => [
        Spatie\Health\ResultStores\EloquentHealthResultStore::class => [
            'model' => Spatie\Health\Models\HealthCheckResultHistoryItem::class,
            'keep_history_for_days' => 7,
        ],
        // Spatie\Health\ResultStores\JsonFileHealthResultStore::class => [
        //     'disk' => 'local',
        //     'path' => 'health.json',
        // ],
    ],

    'notifications' => [
        'enabled' => true,

        'notifications' => [
            Spatie\Health\Notifications\CheckFailedNotification::class => ['mail'],
        ],

        'notifiable' => Spatie\Health\Notifications\Notifiable::class,

        'throttle_notifications_for_minutes' => 60,
        'throttle_notifications_key' => 'health:notifications:throttle',
    ],

    'oh_dear_endpoint' => [
        'enabled' => false,
        'secret' => env('OH_DEAR_HEALTH_CHECK_SECRET'),
        'url' => '/oh-dear-health-check-results',
    ],

    'silence_health_queue_job' => true,
];
```

### Register Health Checks
```php
// app/Providers/AppServiceProvider.php
use Spatie\Health\Facades\Health;
use Spatie\Health\Checks\Checks\BackupsCheck;
use Spatie\Health\Checks\Checks\CacheCheck;
use Spatie\Health\Checks\Checks\DatabaseCheck;
use Spatie\Health\Checks\Checks\DatabaseConnectionCountCheck;
use Spatie\Health\Checks\Checks\DatabaseSizeCheck;
use Spatie\Health\Checks\Checks\DebugModeCheck;
use Spatie\Health\Checks\Checks\EnvironmentCheck;
use Spatie\Health\Checks\Checks\HorizonCheck;
use Spatie\Health\Checks\Checks\OptimizedAppCheck;
use Spatie\Health\Checks\Checks\QueueCheck;
use Spatie\Health\Checks\Checks\RedisCheck;
use Spatie\Health\Checks\Checks\ScheduleCheck;
use Spatie\Health\Checks\Checks\UsedDiskSpaceCheck;

public function boot(): void
{
    Health::checks([
        // Environment checks
        EnvironmentCheck::new()->expectEnvironment('production'),
        DebugModeCheck::new(),
        OptimizedAppCheck::new(),

        // Database checks
        DatabaseCheck::new(),
        DatabaseConnectionCountCheck::new()
            ->warnWhenMoreConnectionsThan(50)
            ->failWhenMoreConnectionsThan(100),
        DatabaseSizeCheck::new()
            ->failWhenSizeAboveGb(errorThresholdGb: 5.0),

        // Cache & Redis
        CacheCheck::new(),
        RedisCheck::new(),

        // Queue & Jobs
        QueueCheck::new(),
        HorizonCheck::new(), // If using Horizon

        // Scheduler
        ScheduleCheck::new()
            ->heartbeatMaxAgeInMinutes(2),

        // Storage
        UsedDiskSpaceCheck::new()
            ->warnWhenUsedSpaceIsAbovePercentage(70)
            ->failWhenUsedSpaceIsAbovePercentage(90),

        // Backups (if using spatie/laravel-backup)
        BackupsCheck::new()
            ->locatedAt(storage_path('app/backups'))
            ->youngestBackShouldHaveBeenMadeInDays(1)
            ->numberOfBackupsGreaterThan(1),
    ]);
}
```

### Health Check Routes
```php
// routes/web.php
use Spatie\Health\Http\Controllers\HealthCheckResultsController;
use Spatie\Health\Http\Controllers\HealthCheckJsonResultsController;

// HTML dashboard (protect with auth in production)
Route::middleware(['auth', 'can:viewHealth'])->group(function () {
    Route::get('/health', HealthCheckResultsController::class);
});

// JSON API endpoint (for monitoring services)
Route::get('/api/health', HealthCheckJsonResultsController::class);

// Simple ping endpoint
Route::get('/api/ping', fn () => response()->json(['status' => 'ok']));
```

### Schedule Health Checks
```php
// app/Console/Kernel.php
$schedule->command('health:check')->everyMinute();

// Or run specific checks less frequently
$schedule->command('health:check --only=DatabaseSizeCheck,UsedDiskSpaceCheck')
    ->hourly();
```

## Custom Health Check

```php
<?php

declare(strict_types=1);

namespace App\Health\Checks;

use Spatie\Health\Checks\Check;
use Spatie\Health\Checks\Result;

final class ApiConnectionCheck extends Check
{
    protected string $apiUrl;

    public function apiUrl(string $url): self
    {
        $this->apiUrl = $url;
        return $this;
    }

    public function run(): Result
    {
        $result = Result::make();

        try {
            $response = Http::timeout(5)->get($this->apiUrl . '/health');

            if ($response->successful()) {
                return $result->ok('API is reachable');
            }

            return $result->failed("API returned status {$response->status()}");
        } catch (\Exception $e) {
            return $result->failed("API unreachable: {$e->getMessage()}");
        }
    }
}

// Register in AppServiceProvider
Health::checks([
    ApiConnectionCheck::new()
        ->name('External API')
        ->apiUrl('https://api.example.com'),
]);
```

## Interactive Prompts

When run without arguments, prompt user for:

1. **Which health checks to enable?** (multi-select)
   - [x] Database connection
   - [x] Cache availability
   - [x] Redis connection
   - [x] Queue processing
   - [x] Disk space
   - [x] Schedule running
   - [ ] Debug mode (production only)
   - [ ] Environment check
   - [ ] Database size
   - [ ] Horizon status
   - [ ] Backup status

2. **How often to run checks?**
   - Every minute (recommended)
   - Every 5 minutes
   - Every 15 minutes

3. **Notification on failure?**
   - Email
   - Slack
   - Discord
   - None

4. **Enable health dashboard?**
   - Yes (with auth protection)
   - JSON API only
   - No dashboard

## Output

```markdown
## Health Monitoring Setup Complete

### Package Installed
- spatie/laravel-health

### Health Checks Configured
| Check | Status | Threshold |
|-------|--------|-----------|
| Database | Enabled | Connection test |
| Cache | Enabled | Read/write test |
| Redis | Enabled | Ping test |
| Queue | Enabled | Job processing |
| Disk Space | Enabled | Warn >70%, Fail >90% |
| Schedule | Enabled | Max age 2 minutes |

### Routes Added
- GET `/health` - HTML dashboard (auth protected)
- GET `/api/health` - JSON endpoint

### Schedule
- `health:check` runs every minute

### Commands Available
```bash
php artisan health:check         # Run all checks
php artisan health:list          # List configured checks
php artisan health:check --fresh # Clear cache and run
```

### Next Steps
1. Run `php artisan migrate` for result storage
2. Visit `/health` to view dashboard
3. Configure monitoring service to ping `/api/health`
4. Test alert notifications
```
