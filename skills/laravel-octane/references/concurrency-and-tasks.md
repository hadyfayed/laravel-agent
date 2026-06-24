# Laravel Octane Concurrency & Tasks Reference

Concurrent tasks, ticks/intervals, the Octane cache, Swoole tables, and Octane events for parallel and background work.

## Concurrent Tasks

Execute multiple tasks concurrently using Swoole coroutines:

```php
<?php

use Laravel\Octane\Facades\Octane;

// Execute tasks concurrently
[$users, $posts, $stats] = Octane::concurrently([
    fn () => User::with('profile')->get(),
    fn () => Post::latest()->limit(10)->get(),
    fn () => DB::table('analytics')->count(),
]);

// With timeout (5 seconds)
[$data1, $data2] = Octane::concurrently([
    fn () => Http::get('https://api1.example.com/data'),
    fn () => Http::get('https://api2.example.com/data'),
], 5000); // 5 seconds

// Real-world example: Aggregating API data
public function dashboard()
{
    [$orders, $revenue, $customers] = Octane::concurrently([
        fn () => Order::where('status', 'completed')
            ->whereDate('created_at', today())
            ->count(),
        fn () => Order::where('status', 'completed')
            ->whereDate('created_at', today())
            ->sum('total'),
        fn () => Customer::whereDate('created_at', today())->count(),
    ]);

    return view('dashboard', compact('orders', 'revenue', 'customers'));
}
```

### Concurrent Dashboard Controller (agent)

```php
<?php

namespace App\Http\Controllers;

use Laravel\Octane\Facades\Octane;

final class DashboardController extends Controller
{
    public function index()
    {
        // Run tasks concurrently
        [$users, $orders, $revenue, $notifications] = Octane::concurrently([
            fn () => User::count(),
            fn () => Order::whereDate('created_at', today())->count(),
            fn () => Order::whereMonth('created_at', now()->month)->sum('total'),
            fn () => auth()->user()->unreadNotifications()->count(),
        ]);

        return view('dashboard', compact('users', 'orders', 'revenue', 'notifications'));
    }

    public function fetchExternalData()
    {
        // With timeout
        [$apiData, $cacheData] = Octane::concurrently([
            fn () => Http::timeout(5)->get('https://api.example.com/data')->json(),
            fn () => Cache::get('fallback_data', []),
        ], 10000); // 10 second timeout

        return $apiData ?: $cacheData;
    }
}
```

## Ticks and Intervals

Execute periodic tasks in the background:

```php
// app/Providers/AppServiceProvider.php
<?php

use Laravel\Octane\Facades\Octane;
use Illuminate\Support\Facades\Cache;

public function boot(): void
{
    // Execute every 1 second
    Octane::tick('cleanup', fn () => Cache::cleanup())
        ->seconds(1);

    // Execute every 5 seconds
    Octane::tick('stats', fn () => $this->updateStats())
        ->seconds(5);

    // Execute immediately and then every 10 seconds
    Octane::tick('warmup', fn () => $this->warmCache())
        ->immediate()
        ->seconds(10);

    // Complex tick example
    Octane::tick('monitoring', function () {
        $metrics = [
            'memory' => memory_get_usage(true),
            'time' => now()->timestamp,
        ];

        Cache::put('metrics', $metrics, 60);
    })->seconds(30);
}
```

### Ticker (agent)

```php
<?php

// config/octane.php
'tick' => true,
'tick_interval' => 10000, // milliseconds

// In a service provider
Octane::on(TickReceived::class, function () {
    // Runs every 10 seconds
    $this->cleanupExpiredTokens();
    $this->processQueuedMetrics();
});
```

## Octane Cache and Swoole Tables

### Octane Cache

Ultra-fast in-memory cache (faster than Redis for small values):

```php
use Laravel\Octane\Facades\Octane;

// Store in Octane cache
Octane::cache()->put('key', 'value', 3600);

// Get from cache
$value = Octane::cache()->get('key');

// Remember pattern
$users = Octane::cache()->remember('active_users', 300, function () {
    return User::where('active', true)->get();
});

// Delete
Octane::cache()->forget('key');
```

### Swoole Tables

Shared memory tables for ultra-fast data access across workers:

```php
// config/octane.php
'tables' => [
    'sessions:10000' => [
        'user_id' => ['type' => 'int', 'size' => 8],
        'ip' => ['type' => 'string', 'size' => 45],
        'last_activity' => ['type' => 'int', 'size' => 8],
    ],

    'rate_limits:1000' => [
        'key' => ['type' => 'string', 'size' => 255],
        'count' => ['type' => 'int', 'size' => 4],
        'reset_at' => ['type' => 'int', 'size' => 8],
    ],
],

// Usage
use Laravel\Octane\Tables\TableFactory;

$tables = app(TableFactory::class);

// Set data
$tables->get('sessions')->set('session_123', [
    'user_id' => 1,
    'ip' => '127.0.0.1',
    'last_activity' => time(),
]);

// Get data
$session = $tables->get('sessions')->get('session_123');

// Update
$tables->get('sessions')->set('session_123', [
    'user_id' => $session['user_id'],
    'ip' => $session['ip'],
    'last_activity' => time(),
]);

// Delete
$tables->get('sessions')->delete('session_123');

// Real-world: Rate limiting
public function checkRateLimit(Request $request): bool
{
    $tables = app(TableFactory::class);
    $key = 'rate_limit:' . $request->ip();

    $limit = $tables->get('rate_limits')->get($key);

    if (!$limit || $limit['reset_at'] < time()) {
        $tables->get('rate_limits')->set($key, [
            'key' => $key,
            'count' => 1,
            'reset_at' => time() + 60,
        ]);
        return true;
    }

    if ($limit['count'] >= 60) {
        return false;
    }

    $tables->get('rate_limits')->set($key, [
        'key' => $key,
        'count' => $limit['count'] + 1,
        'reset_at' => $limit['reset_at'],
    ]);

    return true;
}
```

### Swoole Tables (FastCacheService, agent)

```php
<?php

namespace App\Services;

use Laravel\Octane\Facades\Octane;

final class FastCacheService
{
    public function set(string $key, string $value, int $ttl = 3600): void
    {
        Octane::table('cache')->set($key, [
            'value' => $value,
            'expires_at' => time() + $ttl,
        ]);
    }

    public function get(string $key): ?string
    {
        $row = Octane::table('cache')->get($key);

        if (!$row) {
            return null;
        }

        if ($row['expires_at'] < time()) {
            Octane::table('cache')->delete($key);
            return null;
        }

        return $row['value'];
    }

    public function delete(string $key): void
    {
        Octane::table('cache')->delete($key);
    }
}
```

## Octane Events

```php
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Laravel\Octane\Events\RequestHandled;
use Laravel\Octane\Events\RequestReceived;
use Laravel\Octane\Events\TaskReceived;
use Laravel\Octane\Events\TickReceived;
use Laravel\Octane\Events\WorkerStarting;
use Laravel\Octane\Events\WorkerStopping;
use Laravel\Octane\Facades\Octane;

class OctaneServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Octane::on(WorkerStarting::class, function () {
            // Initialize per-worker resources
            \Log::info('Worker starting: ' . getmypid());
        });

        Octane::on(RequestReceived::class, function ($event) {
            // Before each request
            // Clear any request-specific state
        });

        Octane::on(RequestHandled::class, function ($event) {
            // After each request
            // Clean up resources
        });

        Octane::on(WorkerStopping::class, function () {
            // Cleanup before worker dies
            \Log::info('Worker stopping: ' . getmypid());
        });
    }
}
```
