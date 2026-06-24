# Laravel Octane Memory Safety & Config Reference

Memory management, service container state, testing, benchmarks, best practices, pitfalls, and guardrails for long-running Octane workers.

## Memory Management (Avoiding Memory Leaks)

Critical for long-running workers:

### 1. Avoid Static Properties with Changing Data

```php
// BAD - Memory leak!
class OrderProcessor
{
    private static array $processedOrders = [];

    public function process(Order $order): void
    {
        // This grows forever!
        self::$processedOrders[] = $order;
    }
}

// GOOD - Use instance properties or cache
class OrderProcessor
{
    private array $processedOrders = [];

    public function process(Order $order): void
    {
        // Cleared on each request
        $this->processedOrders[] = $order;
    }
}
```

### 2. Clear Query Logs

```php
use Illuminate\Support\Facades\DB;

// In long-running processes
DB::connection()->disableQueryLog();

// Or periodically flush
Octane::tick('cleanup', function () {
    DB::connection()->flushQueryLog();
})->seconds(10);
```

### 3. Unset Large Variables

```php
public function processLargeDataset(): void
{
    $data = $this->fetchHugeDataset();

    $this->process($data);

    // Free memory immediately
    unset($data);
}
```

### 4. Use Lazy Collections

```php
// BAD - Loads everything into memory
$users = User::all();

// GOOD - Streams data
User::lazy()->each(function (User $user) {
    $this->processUser($user);
});
```

### 5. Restart Workers Periodically

```php
// config/octane.php
'swoole' => [
    'options' => [
        'max_request' => 1000, // Restart after 1000 requests
    ],
],
```

### 6. Monitor Memory Usage

```php
Octane::tick('memory-monitor', function () {
    $memory = memory_get_usage(true);
    $limit = 128 * 1024 * 1024; // 128MB

    if ($memory > $limit) {
        Log::warning('High memory usage', ['memory' => $memory]);
    }
})->seconds(30);
```

### Avoiding Memory Leaks (agent)

```php
<?php

// ❌ BAD: Static properties persist between requests
class BadService
{
    public static array $cache = [];

    public function add(string $key, $value): void
    {
        self::$cache[$key] = $value; // Grows forever!
    }
}

// ✅ GOOD: Use request-scoped instances
class GoodService
{
    private array $requestCache = [];

    public function add(string $key, $value): void
    {
        $this->requestCache[$key] = $value;
    }
}

// ✅ GOOD: Flush in service provider
class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // Reset singleton state between requests
        $this->app->resolving(SomeService::class, function ($service) {
            $service->reset();
        });
    }
}
```

## Service Container Considerations

### Understanding Container State

Octane keeps the application in memory between requests. Be careful with:

```php
// app/Providers/AppServiceProvider.php

public function register(): void
{
    // SAFE - Singleton for stateless services
    $this->app->singleton(PaymentGateway::class);

    // DANGEROUS - User state persists across requests!
    // BAD!
    $this->app->singleton(CurrentUser::class);

    // GOOD - Request scoped
    $this->app->scoped(CurrentUser::class);
}

public function boot(): void
{
    // SAFE - Runs once at worker startup
    $this->loadViewsFrom(...);

    // DANGEROUS - Don't store request-specific data!
    // BAD!
    View::share('user', auth()->user());

    // GOOD - Use view composers with request data
    View::composer('*', function ($view) {
        $view->with('user', auth()->user());
    });
}
```

### Warming Services

Pre-load services at worker startup:

```php
// config/octane.php
'warm' => [
    ...Octane::defaultServicesToWarm(),
    'view',
    'db',
    'queue',
    App\Services\CatalogService::class,
],
```

### Request Scoped Bindings

```php
// app/Providers/AppServiceProvider.php
public function register(): void
{
    // Cleared after each request
    $this->app->scoped(ShoppingCart::class, function () {
        return new ShoppingCart(session()->getId());
    });

    $this->app->scoped(CurrentTenant::class, function () {
        return CurrentTenant::fromRequest(request());
    });
}
```

## Testing Octane Applications

```php
<?php

use Laravel\Octane\Facades\Octane;

describe('Octane Features', function () {
    it('executes concurrent tasks', function () {
        [$result1, $result2] = Octane::concurrently([
            fn () => 'first',
            fn () => 'second',
        ]);

        expect($result1)->toBe('first')
            ->and($result2)->toBe('second');
    });

    it('uses octane cache', function () {
        Octane::cache()->put('test_key', 'test_value', 60);

        expect(Octane::cache()->get('test_key'))->toBe('test_value');

        Octane::cache()->forget('test_key');
    });

    it('handles memory correctly', function () {
        $initialMemory = memory_get_usage();

        // Process large dataset
        $data = range(1, 10000);
        unset($data);

        $finalMemory = memory_get_usage();

        expect($finalMemory)->toBeLessThanOrEqual($initialMemory * 1.1);
    });
});

// Test concurrent HTTP requests
it('handles concurrent API calls', function () {
    [$users, $posts] = Octane::concurrently([
        fn () => $this->get('/api/users')->json(),
        fn () => $this->get('/api/posts')->json(),
    ]);

    expect($users)->toHaveCount(10)
        ->and($posts)->toHaveCount(10);
});
```

### State Isolation Testing (agent)

```php
<?php

// Octane doesn't affect tests directly
// But test for state isolation

describe('State Isolation', function () {
    it('does not leak state between requests', function () {
        // First request sets something
        $this->get('/set-session?value=first');

        // Simulate new request (new app instance in tests)
        $this->refreshApplication();

        // Second request should not see first request's state
        $response = $this->get('/get-session');
        $response->assertSee('null');
    });
});
```

## Performance Benchmarks

Typical performance improvements with Octane:

| Metric | PHP-FPM | Octane (RoadRunner) | Octane (Swoole) |
|--------|---------|---------------------|-----------------|
| Requests/sec | 100-200 | 400-800 | 800-1500 |
| Response time | 50-100ms | 15-30ms | 10-20ms |
| Memory usage | 20-40MB/req | 50-100MB/worker | 80-150MB/worker |
| Concurrent requests | Limited | High | Very High |

## Common Pitfalls

### 1. Static Properties with Mutable State

**Problem:** Static properties persist across requests, causing data leakage.

```php
// BAD - Memory leak and data contamination!
class UserService
{
    private static array $cache = [];

    public function getUser(int $id): User
    {
        if (!isset(self::$cache[$id])) {
            self::$cache[$id] = User::find($id);
        }
        return self::$cache[$id];
    }
}

// User A makes request -> cache['1'] = User 1
// User B makes request -> gets User A's cached data!

// GOOD - Use proper caching
class UserService
{
    public function getUser(int $id): User
    {
        return Cache::remember("user:{$id}", 300, fn () => User::find($id));
    }
}

// Or use instance properties (cleared per request)
class UserService
{
    private array $cache = [];

    public function getUser(int $id): User
    {
        if (!isset($this->cache[$id])) {
            $this->cache[$id] = User::find($id);
        }
        return $this->cache[$id];
    }
}
```

### 2. Singleton Services with Request State

**Problem:** Singleton services keep state between requests.

```php
// BAD - Singleton with user state!
class ShoppingCart
{
    private array $items = [];

    public function add(Product $product): void
    {
        $this->items[] = $product;
    }
}

// In ServiceProvider
$this->app->singleton(ShoppingCart::class); // WRONG!

// User A adds item -> cart has 1 item
// User B makes request -> sees User A's items!

// GOOD - Use scoped binding
$this->app->scoped(ShoppingCart::class, function () {
    return new ShoppingCart(session()->getId());
});
```

### 3. Not Clearing Auth State

**Problem:** Auth user bleeds between requests.

```php
// BAD - Auth state persists!
class DashboardController
{
    private User $user;

    public function __construct()
    {
        $this->user = auth()->user(); // Set at worker startup!
    }
}

// GOOD - Get user from request
class DashboardController
{
    public function index(Request $request)
    {
        $user = $request->user(); // Fresh each request
        return view('dashboard', compact('user'));
    }
}
```

### 4. File Upload Issues

**Problem:** Uploaded files are deleted before processing.

```php
// BAD - File might be deleted!
public function upload(Request $request)
{
    $path = $request->file('avatar')->store('avatars');

    // Processing here might fail - file already deleted
    ProcessAvatar::dispatch($path);
}

// GOOD - Store file immediately
public function upload(Request $request)
{
    $file = $request->file('avatar');
    $path = Storage::putFile('avatars', $file);

    ProcessAvatar::dispatch($path);

    return response()->json(['path' => $path]);
}
```

### 5. Database Connection Leaks

**Problem:** Too many connections pile up.

```php
// BAD - Opening connections without closing
foreach ($databases as $db) {
    DB::connection($db)->select(...);
    // Connection stays open!
}

// GOOD - Explicitly disconnect
foreach ($databases as $db) {
    DB::connection($db)->select(...);
    DB::disconnect($db);
}

// Or use connection pooling
// config/octane.php
'swoole' => [
    'options' => [
        'max_request' => 500, // Restart worker to close connections
    ],
],
```

### 6. Forgetting to Warm Services

**Problem:** First requests are slow.

```php
// config/octane.php - Warm frequently used services
'warm' => [
    ...Octane::defaultServicesToWarm(),
    'view',
    'blade.compiler',
    'db',
    'queue',
    App\Services\CatalogService::class,
],
```

### 7. View Composers with Static Data

**Problem:** View shared data is set once and never updates.

```php
// BAD - Set once at boot!
public function boot(): void
{
    View::share('siteName', config('app.name'));
    View::share('user', auth()->user()); // WRONG! Old user data
}

// GOOD - Use view composers
public function boot(): void
{
    View::share('siteName', config('app.name')); // Static data is fine

    View::composer('*', function ($view) {
        $view->with('user', auth()->user()); // Fresh each request
    });
}
```

### 8. Not Monitoring Memory

**Problem:** Workers crash from memory exhaustion.

```php
// GOOD - Add memory monitoring
Octane::tick('memory-check', function () {
    $usage = memory_get_usage(true) / 1024 / 1024; // MB

    if ($usage > 120) { // 120MB threshold
        Log::warning("High memory usage: {$usage}MB");
    }
})->seconds(30);

// Set max_request to restart workers
'swoole' => [
    'options' => [
        'max_request' => 1000,
    ],
],
```

### 9. Response Caching Issues

**Problem:** Headers or status codes from previous requests.

```php
// BAD - Might use old response
return response($content); // Could have old headers

// GOOD - Always create fresh response
return response()
    ->json($data, 200)
    ->header('Cache-Control', 'no-cache');
```

### 10. Not Testing Concurrent Scenarios

**Problem:** Race conditions in production.

```php
// Test concurrent access
it('handles concurrent requests safely', function () {
    $results = [];

    Octane::concurrently([
        fn () => $results[] = $this->post('/api/orders', $data1),
        fn () => $results[] = $this->post('/api/orders', $data2),
        fn () => $results[] = $this->post('/api/orders', $data3),
    ]);

    expect($results)->toHaveCount(3)
        ->each->toBeSuccessful();
});
```

### Additional Pitfalls (from agent)

- **Static properties** - Persist between requests, causing memory leaks
- **Singleton bindings** - May hold stale request data
- **Global state** - Avoid $_GLOBALS, static arrays
- **File handles** - Close after use, don't leave open
- **Database connections** - Use connection pooling with Swoole
- **Request object reuse** - Always inject fresh request instance

## Best Practices

### 1. Use Scoped Bindings for Request-Specific Services

```php
$this->app->scoped(ShoppingCart::class);
$this->app->scoped(CurrentTenant::class);
$this->app->scoped(UserContext::class);
```

### 2. Leverage Concurrent Tasks

```php
// Fetch related data concurrently
[$orders, $revenue, $customers, $products] = Octane::concurrently([
    fn () => Order::today()->count(),
    fn () => Order::today()->sum('total'),
    fn () => Customer::today()->count(),
    fn () => Product::lowStock()->get(),
]);
```

### 3. Use Octane Cache for Hot Data

```php
// Ultra-fast in-memory cache
$config = Octane::cache()->remember('app_config', 3600, function () {
    return DB::table('settings')->pluck('value', 'key');
});
```

### 4. Monitor Performance

```php
// Add custom metrics
Octane::tick('metrics', function () {
    $metrics = [
        'memory' => memory_get_usage(true),
        'peak' => memory_get_peak_usage(true),
        'requests' => Cache::increment('total_requests'),
    ];

    Cache::put('octane_metrics', $metrics, 60);
})->seconds(30);
```

### 5. Configure Workers Correctly

```bash
# Production (4 CPU cores)
php artisan octane:start --workers=4 --task-workers=6 --max-requests=1000

# Development
php artisan octane:start --watch
```

### 6. Implement Health Checks

```php
Route::get('/health', function () {
    return response()->json([
        'status' => 'healthy',
        'memory' => memory_get_usage(true),
        'uptime' => Cache::get('worker_started_at')?->diffForHumans(),
    ]);
});
```

### 7. Use Graceful Shutdowns

```php
// Handle SIGTERM gracefully
Octane::stopping(function () {
    // Clean up resources
    DB::disconnect();
    Redis::disconnect();

    Log::info('Worker shutting down gracefully');
});
```

### 8. Optimize Database Connections

```php
// config/database.php
'mysql' => [
    'driver' => 'mysql',
    'host' => env('DB_HOST', '127.0.0.1'),
    'port' => env('DB_PORT', '3306'),
    'database' => env('DB_DATABASE', 'forge'),
    'username' => env('DB_USERNAME', 'forge'),
    'password' => env('DB_PASSWORD', ''),
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
    'prefix' => '',
    'prefix_indexes' => true,
    'strict' => true,
    'engine' => null,
    'options' => extension_loaded('pdo_mysql') ? array_filter([
        PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
        PDO::ATTR_PERSISTENT => true, // Connection pooling
    ]) : [],
],
```

### 9. Prevent Memory Leaks

```php
// Disable query log in production
if (app()->environment('production')) {
    DB::connection()->disableQueryLog();
}

// Clear event listeners if needed
Event::clearResolvedInstances();

// Use lazy collections for large datasets
User::lazy()->chunk(100)->each(function ($users) {
    $users->each->process();
});
```

### 10. Document Octane-Specific Code

```php
/**
 * WARNING: This service is scoped per request.
 * Do NOT inject into singletons or store in static properties.
 */
class CurrentUser
{
    public function __construct(
        private readonly Request $request
    ) {}
}
```

## Guardrails

- NEVER store request-specific data in static properties
- NEVER use singleton bindings for services with user state
- ALWAYS use scoped bindings for request-dependent services
- ALWAYS monitor memory usage in production
- ALWAYS set max_request to prevent memory leaks
- ALWAYS test concurrent scenarios
- NEVER share mutable state between requests
- ALWAYS warm critical services in config
- NEVER forget to disconnect database connections in loops
- ALWAYS use Octane::concurrently() for parallel operations when possible
