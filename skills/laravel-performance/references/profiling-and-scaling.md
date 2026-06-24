# Laravel Profiling, Scaling & Server Tuning Reference

## Quick Health Check
```bash
# Check cache status
php artisan cache:clear && php artisan config:cache && php artisan route:cache && php artisan view:cache

# Check optimization status
php artisan about
```

## Quick Analysis
```bash
# Check cache status
php artisan about

# Find N+1 queries
php artisan dev:db:n1  # if devtoolbox installed

# Check slow queries
php artisan telescope  # if telescope installed
```

## Environment Check

```bash
# Check performance-related packages
composer show laravel/octane 2>/dev/null && echo "OCTANE=yes" || echo "OCTANE=no"
composer show laravel/horizon 2>/dev/null && echo "HORIZON=yes" || echo "HORIZON=no"
composer show laravel/telescope 2>/dev/null && echo "TELESCOPE=yes" || echo "TELESCOPE=no"
composer show laravel/pulse 2>/dev/null && echo "PULSE=yes" || echo "PULSE=no"
composer show spatie/laravel-ray 2>/dev/null && echo "RAY=yes" || echo "RAY=no"
composer show beyondcode/laravel-query-detector 2>/dev/null && echo "QUERY_DETECTOR=yes" || echo "QUERY_DETECTOR=no"
composer show barryvdh/laravel-debugbar 2>/dev/null && echo "DEBUGBAR=yes" || echo "DEBUGBAR=no"

# Check caching
php artisan config:show cache.default 2>/dev/null || echo "cache=file"
php artisan config:show session.driver 2>/dev/null || echo "session=file"
php artisan config:show queue.default 2>/dev/null || echo "queue=sync"

# Check OPcache
php -m | grep -i opcache && echo "OPCACHE=yes" || echo "OPCACHE=no"

# Check database indexes
php artisan db:show 2>/dev/null || echo "DB info unavailable"
```

## Application Profiling

### Laravel Debugbar (Development)
```bash
composer require barryvdh/laravel-debugbar --dev
```

### Laravel Telescope
```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

### Laravel pulse (Production Monitoring)
```bash
composer require laravel/pulse
php artisan vendor:publish --provider="Laravel\Pulse\PulseServiceProvider"
php artisan migrate
```

## Laravel Pulse Setup

```bash
composer require laravel/pulse
php artisan vendor:publish --provider="Laravel\Pulse\PulseServiceProvider"
php artisan migrate
```

```php
// config/pulse.php
'ingest' => [
    'trim_lottery' => [1, 1000], // Run trim 1 in 1000 requests
],

'recorders' => [
    Recorders\SlowQueries::class => [
        'threshold' => 100, // Log queries > 100ms
    ],
    Recorders\SlowJobs::class => [
        'threshold' => 1000, // Log jobs > 1s
    ],
],
```

## Monitoring

- **Laravel Telescope** - Development profiling
- **Laravel pulse** - Production monitoring
- **Debugbar** - Request profiling

## Identify Slow Queries
```php
// Enable query logging
DB::enableQueryLog();

// ... your code ...

// Dump queries
dd(DB::getQueryLog());

// Or listen to queries
DB::listen(function ($query) {
    if ($query->time > 100) { // > 100ms
        Log::warning('Slow query', [
            'sql' => $query->sql,
            'bindings' => $query->bindings,
            'time' => $query->time,
        ]);
    }
});
```

## Laravel Octane

### Installation
```bash
composer require laravel/octane
php artisan octane:install
```

### Configuration
```php
// config/octane.php
return [
    'server' => env('OCTANE_SERVER', 'swoole'),

    'https' => false,

    'listeners' => [
        WorkerStarting::class => [
            EnsureUploadedFilesAreValid::class,
            EnsureUploadedFilesCanBeMoved::class,
        ],

        RequestReceived::class => [
            // Reset any static state
        ],

        RequestHandled::class => [
            // Cleanup after request
        ],

        RequestTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],
    ],

    'warm' => [
        // Services to pre-warm
        'router',
        'view',
        'cache',
    ],

    'flush' => [
        // Services to flush between requests
    ],

    'tables' => [
        // Swoole tables for shared memory
    ],

    'cache' => [
        'rows' => 1000,
        'bytes' => 10000,
    ],

    'max_execution_time' => 30,
];
```

### Octane-Safe Code

```php
// Avoid static state
class BadService
{
    private static array $cache = []; // BAD - persists between requests
}

// Use container instead
class GoodService
{
    public function __construct(
        private readonly CacheRepository $cache,
    ) {}
}

// Flush singletons
$this->app->forgetScopedInstances();
```

### Run Octane
```bash
composer require laravel/octane
php artisan octane:install
php artisan octane:start --workers=4
```

```bash
# Development
php artisan octane:start --watch

# Production (Swoole)
php artisan octane:start --server=swoole --workers=4 --task-workers=6

# Production (RoadRunner)
php artisan octane:start --server=roadrunner --workers=4
```

## View Optimization

### Avoid N+1 in Views
```blade
{{-- Bad --}}
@foreach($posts as $post)
    {{ $post->author->name }} {{-- N+1! --}}
@endforeach

{{-- Good - eager load in controller --}}
$posts = Post::with('author')->get();

@foreach($posts as $post)
    {{ $post->author->name }}
@endforeach
```

### Precompile Views
```bash
php artisan view:cache
```

## Forgetting Route Caching — Slow route resolution
```bash
# Always run in production
php artisan route:cache
```

## Queue Optimization

### Horizon Configuration
```php
// config/horizon.php
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
```

### Job Optimization
```php
// Batch large operations
Bus::batch([
    new ProcessPodcast($podcast1),
    new ProcessPodcast($podcast2),
    new ProcessPodcast($podcast3),
])
->allowFailures()
->dispatch();

// Use job middleware for rate limiting
class ProcessPodcast implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function middleware(): array
    {
        return [
            new RateLimited('podcasts'),
            new WithoutOverlapping($this->podcast->id),
        ];
    }

    public function retryUntil(): DateTime
    {
        return now()->addMinutes(5);
    }
}
```

## PHP & Server Optimization

### OPcache Configuration
```ini
; php.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=64
opcache.max_accelerated_files=32531
opcache.validate_timestamps=0  ; Production only
opcache.save_comments=1
opcache.fast_shutdown=1
opcache.jit=1255
opcache.jit_buffer_size=256M
```

### PHP-FPM Tuning
```ini
; php-fpm.conf
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

### Nginx Optimization
```nginx
# Enable gzip
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml;

# Enable HTTP/2
listen 443 ssl http2;

# Static file caching
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# FastCGI caching
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=LARAVEL:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";

location ~ \.php$ {
    fastcgi_cache LARAVEL;
    fastcgi_cache_valid 200 60m;
    fastcgi_cache_use_stale error timeout http_500;
}
```

## Benchmarking

### Route Benchmarking
```php
$start = microtime(true);

// Code to benchmark

$elapsed = microtime(true) - $start;
Log::info("Elapsed: {$elapsed}s");
```

### Load Testing
```bash
# Apache Bench
ab -n 1000 -c 100 https://yoursite.com/api/endpoint

# wrk
wrk -t12 -c400 -d30s https://yoursite.com/api/endpoint

# k6
k6 run loadtest.js
```

## Optimization Targets

| Metric | Target |
|--------|--------|
| Response time | < 200ms |
| Database queries | < 10 per request |
| Memory usage | < 128MB |
| Cache hit ratio | > 90% |

## Performance Checklist

| Area | Action |
|------|--------|
| Queries | Add indexes, eager load, select specific columns |
| Big O | Avoid nested loops, use keyBy/groupBy for O(1) lookups |
| Caching | Redis for cache/sessions, cache expensive queries |
| Assets | CDN, minification, compression |
| PHP | OPcache, JIT (PHP 8.1+) |
| Server | Nginx tuning, HTTP/2, gzip |

## Performance Analysis Output Format

```markdown
## Performance Analysis: <Target>

### Summary
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Response Time | 450ms | 120ms | 73% |
| Memory Usage | 85MB | 45MB | 47% |
| Database Queries | 45 | 8 | 82% |

### Issues Found
| Priority | Issue | Location | Impact |
|----------|-------|----------|--------|
| Critical | N+1 Query | OrderController:index | 50+ queries |
| High | Missing index | orders.user_id | Slow WHERE |
| Medium | No caching | ProductService | Redundant DB calls |

### Optimizations Applied
| Optimization | File | Description |
|--------------|------|-------------|
| Eager loading | OrderController.php | Added ->with('user', 'items') |
| Index | migrations/xxx | Added index on user_id |
| Cache | ProductService.php | Cache frequently accessed products |

### Recommendations
1. Enable Redis for cache/sessions
2. Install Laravel Octane
3. Configure OPcache preloading
4. Add CDN for static assets

### Commands
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```
```

## Guardrails

- **ALWAYS** measure before and after optimization
- **ALWAYS** test in staging before production
- **NEVER** cache user-specific data without proper keys
- **NEVER** disable security for performance
- **PREFER** fixing root cause over adding cache layers
- **PROFILE** before optimizing - avoid premature optimization
- **DETECT** Big O complexity issues (nested loops, contains() in loops)
- **FIX** O(n²) patterns with keyBy(), groupBy(), flip() for O(1) lookups
- **PREFER** batch operations over in-loop queries
