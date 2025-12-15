---
name: laravel-performance
description: >
  Optimize Laravel application performance including caching, query optimization,
  and scaling. Use when the user mentions slow performance, needs optimization,
  or wants to improve speed. Triggers: "performance", "slow", "optimize", "speed",
  "cache", "fast", "scaling", "bottleneck", "memory", "N+1".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Performance Skill

Optimize Laravel applications for speed and scalability.

## When to Use

- Application is slow
- Need to improve response times
- Scaling for high traffic
- Memory issues
- Database bottlenecks

## Quick Analysis

```bash
# Check cache status
php artisan about

# Find N+1 queries
php artisan dev:db:n1  # if devtoolbox installed

# Check slow queries
php artisan telescope  # if telescope installed
```

## Quick Wins

### 1. Enable Caching
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

### 2. Fix N+1 Queries
```php
// Before (N+1)
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // N+1!
}

// After (Eager loading)
$posts = Post::with('author')->get();

// Prevent in development
Model::preventLazyLoading(!app()->isProduction());
```

### 3. Query Optimization
```php
// Select only needed columns
User::select('id', 'name', 'email')->get();

// Use chunking for large datasets
User::chunk(1000, function ($users) {
    // Process
});

// Add missing indexes
Schema::table('orders', function ($table) {
    $table->index(['user_id', 'status']);
});
```

### 4. Cache Expensive Queries
```php
$products = Cache::remember('products:featured', 3600, function () {
    return Product::featured()->with('category')->get();
});
```

## Redis Configuration

```env
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

## Laravel Octane

```bash
composer require laravel/octane
php artisan octane:install
php artisan octane:start --workers=4
```

## Performance Checklist

| Area | Action |
|------|--------|
| Queries | Add indexes, eager load, select specific columns |
| Caching | Redis for cache/sessions, cache expensive queries |
| Assets | CDN, minification, compression |
| PHP | OPcache, JIT (PHP 8.1+) |
| Server | Nginx tuning, HTTP/2, gzip |

## Monitoring

- **Laravel Telescope** - Development profiling
- **Laravel Pulse** - Production monitoring
- **Debugbar** - Request profiling

## Optimization Targets

| Metric | Target |
|--------|--------|
| Response time | < 200ms |
| Database queries | < 10 per request |
| Memory usage | < 128MB |
| Cache hit ratio | > 90% |

## Best Practices

- Profile before optimizing
- Fix root causes, not symptoms
- Cache at appropriate levels
- Use queues for slow operations
- Monitor production performance
