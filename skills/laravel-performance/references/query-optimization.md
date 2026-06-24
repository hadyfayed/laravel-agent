# Laravel Query & Big-O Optimization Reference

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

## N+1 Query Detection

```bash
composer require beyondcode/laravel-query-detector --dev
```

```php
// Fix N+1
// Before
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // N+1!
}

// After
$posts = Post::with('author')->get();
foreach ($posts as $post) {
    echo $post->author->name; // Eager loaded
}

// Prevent N+1 in production
Model::preventLazyLoading(!app()->isProduction());
```

## Quick Win — Fix N+1 Queries
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

## Query Optimization

### Use Select Specific Columns
```php
// Bad - selects all columns
$users = User::all();

// Good - only needed columns
$users = User::select('id', 'name', 'email')->get();

// With relationships
$posts = Post::with('author:id,name')
    ->select('id', 'title', 'author_id')
    ->get();
```

### Use Chunking for Large Datasets
```php
// Bad - loads all into memory
User::all()->each(function ($user) {
    // Process
});

// Good - chunks of 1000
User::chunk(1000, function ($users) {
    foreach ($users as $user) {
        // Process
    }
});

// Better - lazy collection
User::lazy()->each(function ($user) {
    // Process
});

// Best for updates - cursor
User::cursor()->each(function ($user) {
    // Process (but can't eager load)
});
```

### Use Raw Queries for Complex Operations
```php
// Mass update without loading models
DB::table('orders')
    ->where('status', 'pending')
    ->where('created_at', '<', now()->subDays(30))
    ->update(['status' => 'expired']);

// Instead of
Order::where('status', 'pending')
    ->where('created_at', '<', now()->subDays(30))
    ->get()
    ->each->update(['status' => 'expired']);
```

### Use Query Builder Methods (Not Collection Methods)
```php
// Bad - fetches all columns
User::where('active', true)->get()->pluck('id');

// Good - only fetches id
User::where('active', true)->pluck('id');
```

## Index Optimization

```php
// Check existing indexes
Schema::getIndexes('orders');

// Add missing indexes
Schema::table('orders', function (Blueprint $table) {
    // Foreign keys
    $table->index('user_id');
    $table->index('status');

    // Composite index for common queries
    $table->index(['status', 'created_at']);

    // Unique constraint
    $table->unique('order_number');

    // Full-text search
    $table->fullText(['title', 'description']);
});
```

### Not Using Database Indexes — Slow queries
```php
// Add indexes for where/orderBy columns
Schema::table('orders', function (Blueprint $table) {
    $table->index(['user_id', 'created_at']);
    $table->index('status');
});
```

## Big O Complexity Detection

Detect and fix O(n²) patterns that cause exponential slowdowns as data grows.

```php
// BAD: O(n²) - Nested loops comparing all items
$users = User::all();
$orders = Order::all();
foreach ($users as $user) {
    foreach ($orders as $order) {
        if ($order->user_id === $user->id) {
            // Process - runs n×m times!
        }
    }
}

// GOOD: O(n) - Eager load relationships
$users = User::with('orders')->get();
foreach ($users as $user) {
    foreach ($user->orders as $order) {
        // Process - each order accessed once
    }
}

// GOOD: O(n) - Use groupBy for O(1) lookups
$ordersByUser = Order::all()->groupBy('user_id');
foreach ($users as $user) {
    $userOrders = $ordersByUser->get($user->id, collect());
}

// BAD: O(n²) - contains() is O(n), called n times
$existingEmails = User::pluck('email');
foreach ($newUsers as $userData) {
    if (!$existingEmails->contains($userData['email'])) {
        User::create($userData);
    }
}

// GOOD: O(n) - flip() for O(1) has() lookups
$existingEmails = User::pluck('email')->flip();
foreach ($newUsers as $userData) {
    if (!$existingEmails->has($userData['email'])) {
        User::create($userData);
    }
}

// BAD: O(n×m) - filter() in loop
$products = Product::all();
foreach ($categories as $category) {
    $categoryProducts = $products->filter(fn($p) =>
        $p->category_id === $category->id
    ); // O(n) filter × m categories
}

// GOOD: O(n+m) - Pre-group the data
$productsByCategory = Product::all()->groupBy('category_id');
foreach ($categories as $category) {
    $categoryProducts = $productsByCategory->get($category->id, collect());
}
```

### Big O Complexity Reference
| Pattern | Bad | Good | Improvement |
|---------|-----|------|-------------|
| Nested loops | O(n²) | Eager load/keyBy | O(n) |
| In-loop queries | O(n) queries | Batch query | O(1) queries |
| contains() in loop | O(n²) | flip()/has() | O(n) |
| filter() in loop | O(n×m) | groupBy() | O(n+m) |
| String concat loop | O(n²) | implode() | O(n) |

## contains() in Loops — Hidden O(n²)
```php
// Bad - contains() is O(n), called n times = O(n²)
foreach ($items as $item) {
    if ($collection->contains($item->id)) { /* ... */ }
}

// Good - flip() once, has() is O(1)
$lookup = $collection->pluck('id')->flip();
foreach ($items as $item) {
    if ($lookup->has($item->id)) { /* ... */ }
}
```

## Heavy Operations in Requests — Slow response
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
