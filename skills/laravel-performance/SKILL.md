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

## Database Optimization

```php
// Prevent lazy loading in development
Model::preventLazyLoading(!app()->isProduction());

// Use cursor for memory efficiency
User::cursor()->each(function (User $user) {
    // Process one at a time, low memory
});

// Use lazy collections
User::lazy()->each(function (User $user) {
    // Memory efficient iteration
});

// Batch operations
User::where('active', false)
    ->chunkById(1000, function ($users) {
        $users->each->delete();
    });
```

## Memory Optimization

```php
// Clear query log in long processes
DB::disableQueryLog();

// Unset large variables
unset($largeDataset);

// Use generators for large data
function processLargeFile($path): Generator
{
    $handle = fopen($path, 'r');
    while (($line = fgets($handle)) !== false) {
        yield $line;
    }
    fclose($handle);
}
```

## View Optimization

```php
// Fragment caching
@cache('sidebar-' . auth()->id(), 3600)
    <div class="sidebar">
        {{ $heavyComputation }}
    </div>
@endcache

// Or use blade cache
@cache('key')
    Expensive content
@endcache
```

## API Response Optimization

```php
// Use API Resources with conditional attributes
final class ProductResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            // Only include when needed
            'reviews' => $this->when(
                $request->include === 'reviews',
                ReviewResource::collection($this->reviews)
            ),
        ];
    }
}
```

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

## Common Pitfalls

1. **Caching Without Invalidation** - Stale data issues
   ```php
   // Bad - no way to invalidate
   Cache::forever('products', $products);

   // Good - use tags or short TTL
   Cache::tags(['products'])->put('all', $products, 3600);
   Cache::tags(['products'])->flush(); // Invalidate
   ```

2. **Eager Loading Too Much** - Loading unused relations
   ```php
   // Bad - loading everything
   Post::with('author', 'comments', 'tags', 'category')->get();

   // Good - load only what's needed
   Post::with('author')->get();
   ```

3. **Not Using Database Indexes** - Slow queries
   ```php
   // Add indexes for where/orderBy columns
   Schema::table('orders', function (Blueprint $table) {
       $table->index(['user_id', 'created_at']);
       $table->index('status');
   });
   ```

4. **Heavy Operations in Requests** - Slow response
   ```php
   // Bad - sync in request
   foreach ($users as $user) {
       Mail::send(new WelcomeEmail($user));
   }

   // Good - queue it
   foreach ($users as $user) {
       Mail::queue(new WelcomeEmail($user));
   }
   ```

5. **Not Using Query Builder Methods**
   ```php
   // Bad - fetches all columns
   User::where('active', true)->get()->pluck('id');

   // Good - only fetches id
   User::where('active', true)->pluck('id');
   ```

6. **Forgetting Route Caching** - Slow route resolution
   ```bash
   # Always run in production
   php artisan route:cache
   ```

## Best Practices

- Profile before optimizing
- Fix root causes, not symptoms
- Cache at appropriate levels
- Use queues for slow operations
- Monitor production performance
- Use database indexes strategically
- Prevent lazy loading in development
- Use Pulse for production insights

## Related Commands

- `/laravel-agent:db:optimize` - Database optimization

## Related Skills

- `laravel-database` - Query patterns and N+1 fixes
- `laravel-queue` - Offload work to background jobs
