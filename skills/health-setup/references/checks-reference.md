# Health Checks Reference

## Available Checks

| Check | Purpose | Threshold |
|-------|---------|-----------|
| `DatabaseCheck` | Database connection | Ping test |
| `CacheCheck` | Cache read/write | Read/write test |
| `RedisCheck` | Redis connection | Ping test |
| `QueueCheck` | Queue processing | Job dispatch test |
| `UsedDiskSpaceCheck` | Disk usage | Warn >70%, Fail >90% |
| `ScheduleCheck` | Scheduler running | Max age 2 minutes |
| `DebugModeCheck` | Debug mode status | Fail in production |
| `OptimizedAppCheck` | App optimized (config/routes cached) | Must be optimized |
| `EnvironmentCheck` | Environment matches expected | Verify production |
| `DatabaseConnectionCountCheck` | Active connections | Warn >50, Fail >100 |
| `DatabaseSizeCheck` | Database size | Fail >5GB |
| `BackupsCheck` | Recent backups exist | Min 1, max age 1 day |
| `HorizonCheck` | Horizon queue worker | Must be running |

## Configuration Example

```php
<?php

use Spatie\Health\Facades\Health;
use Spatie\Health\Checks\Checks\DatabaseCheck;
use Spatie\Health\Checks\Checks\CacheCheck;
use Spatie\Health\Checks\Checks\RedisCheck;
use Spatie\Health\Checks\Checks\QueueCheck;
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

## Custom Health Check

```php
<?php

namespace App\Health\Checks;

use Spatie\Health\Checks\Check;
use Spatie\Health\Checks\Result;
use Illuminate\Support\Facades\Http;

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

## Notifications Configuration

Edit `config/health.php`:

```php
'notifications' => [
    'enabled' => true,
    'notifications' => [
        Spatie\Health\Notifications\CheckFailedNotification::class => ['mail'],
        // Add Slack/Discord channels as needed
    ],
    'notifiable' => Spatie\Health\Notifications\Notifiable::class,
    'throttle_notifications_for_minutes' => 60,
    'throttle_notifications_key' => 'health:notifications:throttle',
],
```

## Result Storage

Configure in `config/health.php`:

```php
'result_stores' => [
    Spatie\Health\ResultStores\EloquentHealthResultStore::class => [
        'model' => Spatie\Health\Models\HealthCheckResultHistoryItem::class,
        'keep_history_for_days' => 7,
    ],
],
```

## Routes and Access

```php
// routes/web.php
use Spatie\Health\Http\Controllers\HealthCheckResultsController;
use Spatie\Health\Http\Controllers\HealthCheckJsonResultsController;

// HTML dashboard (protect with auth)
Route::middleware(['auth', 'can:viewHealth'])->group(function () {
    Route::get('/health', HealthCheckResultsController::class);
});

// JSON API endpoint (for monitoring services)
Route::get('/api/health', HealthCheckJsonResultsController::class);

// Simple ping endpoint
Route::get('/api/ping', fn () => response()->json(['status' => 'ok']));
```

## Scheduling

In `app/Console/Kernel.php`:

```php
$schedule->command('health:check')->everyMinute();

// Or run specific checks less frequently
$schedule->command('health:check --only=DatabaseSizeCheck,UsedDiskSpaceCheck')
    ->hourly();
```
