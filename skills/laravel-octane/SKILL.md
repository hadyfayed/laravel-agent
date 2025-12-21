---
name: laravel-octane
description: >
  Build high-performance Laravel applications with Octane. Use when the user needs performance,
  Swoole, RoadRunner, FrankenPHP, concurrent tasks, or application server optimization.
  Triggers: "octane", "swoole", "roadrunner", "frankenphp", "high performance",
  "concurrent", "application server", "worker", "persistent application", "long-running".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Octane Skill

Supercharge your Laravel application with Octane - a persistent application server for high-performance workloads.

## When to Use

- Need extreme performance (2-4x faster than PHP-FPM)
- High-traffic applications
- Concurrent task execution required
- Microservices with heavy request loads
- API servers with low latency requirements
- WebSocket or real-time features

## Quick Start

```bash
composer require laravel/octane
php artisan octane:install
php artisan octane:start
```

## Server Choice: Swoole vs RoadRunner vs FrankenPHP

### Swoole (Recommended for Maximum Performance)

**Best for:** Maximum concurrency, WebSockets, coroutines

**Pros:**
- Fastest performance
- Built-in coroutine support
- WebSocket server included
- HTTP/2 support
- Table and cache features

**Cons:**
- Requires PHP extension (not pure PHP)
- Harder to debug
- More memory usage

**Installation:**
```bash
pecl install swoole
# Or via Docker
FROM php:8.3-cli
RUN pecl install swoole && docker-php-ext-enable swoole

# Install Octane with Swoole
php artisan octane:install --server=swoole
```

### RoadRunner (Pure Go Server)

**Best for:** Easier deployment, no PHP extensions, moderate performance

**Pros:**
- No PHP extension needed (pure Go binary)
- Easy deployment
- Good performance
- HTTP/2 and gRPC support
- Simpler debugging

**Cons:**
- Slightly slower than Swoole
- No coroutines
- Larger binary size

**Installation:**
```bash
# RoadRunner downloads automatically
php artisan octane:install --server=roadrunner

# Manual install
./rr get-binary
```

### FrankenPHP (Modern Alternative)

**Best for:** Modern PHP features, Laravel + Caddy integration

**Pros:**
- Built on Caddy web server
- Automatic HTTPS
- HTTP/2, HTTP/3 support
- Easy deployment
- Worker mode support

**Cons:**
- Newer, less battle-tested
- Still evolving

**Installation:**
```bash
php artisan octane:install --server=frankenphp
```

## Configuration

```php
// config/octane.php

return [
    'server' => env('OCTANE_SERVER', 'swoole'),

    'https' => env('OCTANE_HTTPS', false),

    'listeners' => [
        WorkerStarting::class => [
            EnsureUploadedFilesAreValid::class,
            EnsureUploadedFilesCanBeMoved::class,
        ],

        RequestReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
            ...Octane::prepareApplicationForNextRequest(),
        ],

        RequestHandled::class => [],

        RequestTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],

        TaskReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
        ],

        TaskTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],

        TickReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
        ],

        TickTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],

        OperationTerminated::class => [
            FlushSessionState::class,
        ],

        WorkerErrorOccurred::class => [
            ReportException::class,
            StopWorkerIfNecessary::class,
        ],

        WorkerStopping::class => [],
    ],

    'warm' => [
        ...Octane::defaultServicesToWarm(),
    ],

    'cache' => [
        'driver' => env('OCTANE_CACHE_DRIVER', 'octane'),
        'table' => env('OCTANE_CACHE_TABLE', 'octane_cache'),
        'rows' => env('OCTANE_CACHE_ROWS', 1000),
        'bytes' => env('OCTANE_CACHE_BYTES', 10000),
    ],

    'tables' => [
        'example:1000' => [
            'name' => ['type' => 'string', 'size' => 1000],
            'votes' => ['type' => 'int'],
        ],
    ],

    'swoole' => [
        'options' => [
            'log_file' => storage_path('logs/swoole_http.log'),
            'package_max_length' => 10 * 1024 * 1024, // 10MB
            'max_request' => 1000, // Restart worker after 1000 requests
            'dispatch_mode' => 2,
            'open_tcp_nodelay' => true,
            'tcp_fastopen' => true,
            'enable_coroutine' => true,
            'task_worker_num' => env('OCTANE_TASK_WORKERS', 4),
        ],
    ],

    'roadrunner' => [
        'rpc_port' => env('OCTANE_RPC_PORT', 6001),
        'rpc_host' => env('OCTANE_RPC_HOST', '127.0.0.1'),
    ],

    'max_execution_time' => 30,
    'garbage_collection' => [
        'interval' => 1000,
    ],
];
```

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

## Deployment with Octane

### Supervisor Configuration

```ini
# /etc/supervisor/conf.d/octane.conf
[program:octane]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --workers=4 --task-workers=6
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/octane.log
stopwaitsecs=3600
```

### Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/app.conf
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM php:8.3-cli

# Install Swoole
RUN pecl install swoole && docker-php-ext-enable swoole

# Install dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader

# Optimize Laravel
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

EXPOSE 8000

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OCTANE_SERVER=swoole
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    restart: unless-stopped

  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: laravel
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine

volumes:
  mysql_data:
```

### Hot Reload for Development

```bash
# Install file watcher
npm install --save-dev chokidar

# Watch and reload
php artisan octane:start --watch

# Or manually reload
php artisan octane:reload
```

### Graceful Reload (Zero Downtime)

```bash
# Reload workers without downtime
php artisan octane:reload

# Via Supervisor
supervisorctl restart octane:*
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

## Performance Benchmarks

Typical performance improvements with Octane:

| Metric | PHP-FPM | Octane (RoadRunner) | Octane (Swoole) |
|--------|---------|---------------------|-----------------|
| Requests/sec | 100-200 | 400-800 | 800-1500 |
| Response time | 50-100ms | 15-30ms | 10-20ms |
| Memory usage | 20-40MB/req | 50-100MB/worker | 80-150MB/worker |
| Concurrent requests | Limited | High | Very High |

## Related Commands

```bash
# Start Octane server
php artisan octane:start

# Start with options
php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --workers=4

# Start with auto-reload on file changes
php artisan octane:start --watch

# Reload workers
php artisan octane:reload

# Stop server
php artisan octane:stop

# Get server status
php artisan octane:status

# Install Octane with server choice
php artisan octane:install --server=swoole
```

## Related Skills

- `laravel-performance` - General optimization strategies
- `laravel-queue` - Background job processing
- `laravel-websocket` - Real-time communication
- `laravel-database` - Database optimization for high concurrency

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
