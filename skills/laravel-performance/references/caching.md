# Laravel Caching Strategies Reference

## Config Caching (Production)
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

## Application Caching

### Cache Database Queries
```php
// Cache expensive queries
$products = Cache::remember('products:featured', 3600, function () {
    return Product::featured()
        ->with(['category', 'images'])
        ->take(10)
        ->get();
});

// Cache tags for granular invalidation
$products = Cache::tags(['products', 'homepage'])
    ->remember('homepage:products', 3600, fn () => Product::featured()->get());

// Invalidate by tag
Cache::tags('products')->flush();
```

### Model Caching
```php
final class Product extends Model
{
    protected static function booted(): void
    {
        static::saved(fn ($product) => Cache::forget("product:{$product->id}"));
        static::deleted(fn ($product) => Cache::forget("product:{$product->id}"));
    }

    public static function findCached(int $id): ?self
    {
        return Cache::remember("product:{$id}", 3600, fn () => static::find($id));
    }
}
```

### Response Caching
```php
// Simple response cache
return Cache::remember("page:{$request->url()}", 600, function () use ($request) {
    return view('page', ['data' => $this->getData()]);
});

// HTTP cache headers
return response($content)
    ->header('Cache-Control', 'public, max-age=3600')
    ->header('ETag', md5($content));
```

## Redis Optimization

### Use Redis for Sessions & Cache
```env
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

### Redis Connection Pooling
```php
// config/database.php
'redis' => [
    'client' => env('REDIS_CLIENT', 'phpredis'), // Faster than predis

    'default' => [
        'url' => env('REDIS_URL'),
        'host' => env('REDIS_HOST', '127.0.0.1'),
        'password' => env('REDIS_PASSWORD'),
        'port' => env('REDIS_PORT', '6379'),
        'database' => env('REDIS_DB', '0'),
        'read_timeout' => 60,
        'persistent' => true, // Connection pooling
    ],

    'cache' => [
        'url' => env('REDIS_URL'),
        'host' => env('REDIS_HOST', '127.0.0.1'),
        'password' => env('REDIS_PASSWORD'),
        'port' => env('REDIS_PORT', '6379'),
        'database' => env('REDIS_CACHE_DB', '1'),
    ],
],
```

## View / Fragment Caching

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

## Use Fragments for Expensive Parts
```php
// Cache expensive view fragments
{!! Cache::remember("user:{$user->id}:stats", 300, function () use ($user) {
    return view('partials.user-stats', compact('user'))->render();
}) !!}
```

## Caching Pitfalls

### 1. Caching Without Invalidation — Stale data issues
```php
// Bad - no way to invalidate
Cache::forever('products', $products);

// Good - use tags or short TTL
Cache::tags(['products'])->put('all', $products, 3600);
Cache::tags(['products'])->flush(); // Invalidate
```

### 2. Eager Loading Too Much — Loading unused relations
```php
// Bad - loading everything
Post::with('author', 'comments', 'tags', 'category')->get();

// Good - load only what's needed
Post::with('author')->get();
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
