---
name: laravel-database
description: >
  Optimize database operations, create migrations, fix N+1 queries, Big O complexity issues, and design schemas.
  Use when the user mentions database issues, needs migrations, or wants query optimization.
  Triggers: "migration", "database", "query", "N+1", "Big O", "O(n)", "complexity", "index", "schema", "relationship",
  "eloquent", "slow query", "optimize database", "nested loop", "quadratic".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Database Skill

Optimize database operations, design schemas, and fix performance issues.

## When to Use

- Creating or modifying migrations
- Fixing N+1 query problems
- Fixing Big O complexity issues (O(n²), nested loops)
- Optimizing slow queries
- Designing database schemas
- Adding indexes
- Setting up relationships

## Quick Start

```bash
/laravel-agent:db:optimize
/laravel-agent:db:diagram
```

## Complete Migration Example

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('shipping_address_id')->nullable()->constrained('addresses');
            $table->string('order_number', 32)->unique();
            $table->enum('status', ['pending', 'processing', 'shipped', 'delivered', 'cancelled'])
                  ->default('pending');
            $table->decimal('subtotal', 10, 2);
            $table->decimal('tax', 10, 2)->default(0);
            $table->decimal('total', 10, 2);
            $table->text('notes')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Composite indexes for common queries
            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

## Fixing N+1 Queries

### The Problem
```php
// BAD: N+1 query (1 + N queries)
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // New query each time!
}
```

### The Solution
```php
// GOOD: Eager loading (2 queries total)
$posts = Post::with('author')->get();

// Multiple relationships
$posts = Post::with(['author', 'comments', 'tags'])->get();

// Nested relationships
$posts = Post::with(['author.profile', 'comments.user'])->get();

// Conditional eager loading
$posts = Post::with(['comments' => function ($query) {
    $query->where('approved', true)->latest();
}])->get();
```

### Prevent N+1 in Development
```php
// app/Providers/AppServiceProvider.php
use Illuminate\Database\Eloquent\Model;

public function boot(): void
{
    Model::preventLazyLoading(!app()->isProduction());
}
```

## Fixing Big O Complexity Issues

Big O complexity issues cause exponential slowdowns as data grows. Common patterns that introduce O(n²) or worse complexity.

### Problem: Nested Collection Loops (O(n²))
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
```

### Solution: Use Relationships or Indexing
```php
// GOOD: O(n) - Eager load relationships
$users = User::with('orders')->get();

foreach ($users as $user) {
    foreach ($user->orders as $order) {
        // Process - each order accessed once
    }
}

// GOOD: O(n) - Use keyBy for O(1) lookups
$orders = Order::all()->groupBy('user_id');

foreach ($users as $user) {
    $userOrders = $orders->get($user->id, collect());
    // O(1) lookup instead of O(n) search
}
```

### Problem: In-Loop Queries (O(n) queries)
```php
// BAD: O(n) queries - Query inside loop
$orderIds = [1, 2, 3, /* ... 1000 more */];

foreach ($orderIds as $orderId) {
    $order = Order::find($orderId); // Query per iteration!
    $order->update(['status' => 'processed']);
}
```

### Solution: Batch Operations
```php
// GOOD: O(1) queries - Single batch update
Order::whereIn('id', $orderIds)
    ->update(['status' => 'processed']);

// GOOD: O(1) queries - Load all at once
$orders = Order::whereIn('id', $orderIds)->get()->keyBy('id');

foreach ($orderIds as $orderId) {
    $order = $orders->get($orderId);
    // Process with in-memory data
}
```

### Problem: Collection Search in Loop (O(n²))
```php
// BAD: O(n²) - contains() is O(n), called n times
$existingEmails = User::pluck('email');

foreach ($newUsers as $userData) {
    if (!$existingEmails->contains($userData['email'])) {
        User::create($userData);
    }
}
```

### Solution: Use Hash-Based Lookups
```php
// GOOD: O(n) - Convert to hashmap for O(1) lookups
$existingEmails = User::pluck('email')->flip(); // O(1) lookup

foreach ($newUsers as $userData) {
    if (!$existingEmails->has($userData['email'])) {
        User::create($userData);
    }
}

// BETTER: Use database upsert
User::upsert($newUsers, ['email'], ['name', 'updated_at']);
```

### Problem: Repeated Array Filtering (O(n²))
```php
// BAD: O(n²) - filter() is O(n), called for each category
$products = Product::all();
$categories = Category::all();

foreach ($categories as $category) {
    $categoryProducts = $products->filter(fn($p) =>
        $p->category_id === $category->id
    ); // O(n) filter × m categories = O(n×m)
}
```

### Solution: Pre-group the Data
```php
// GOOD: O(n+m) - Group once, access O(1)
$productsByCategory = Product::all()->groupBy('category_id');

foreach ($categories as $category) {
    $categoryProducts = $productsByCategory->get($category->id, collect());
}
```

### Problem: String Building in Loop (O(n²))
```php
// BAD: O(n²) - String concatenation creates new string each time
$html = '';
foreach ($items as $item) {
    $html .= "<li>{$item->name}</li>"; // O(n) copy each time
}
```

### Solution: Use Array Join or StringBuilder
```php
// GOOD: O(n) - Build array, join once
$parts = [];
foreach ($items as $item) {
    $parts[] = "<li>{$item->name}</li>";
}
$html = implode('', $parts);

// BETTER: Use collection
$html = $items->map(fn($item) => "<li>{$item->name}</li>")->implode('');
```

### Big O Complexity Reference

| Operation | Bad Pattern | Good Pattern | Improvement |
|-----------|-------------|--------------|-------------|
| Nested loops | O(n²) | Eager load/keyBy | O(n) |
| In-loop queries | O(n) queries | Batch query | O(1) queries |
| contains() in loop | O(n²) | flip()/has() | O(n) |
| filter() in loop | O(n×m) | groupBy() | O(n+m) |
| String concat | O(n²) | implode() | O(n) |
| array_search in loop | O(n²) | array_flip | O(n) |

### Detecting Big O Issues
```php
// Add to AppServiceProvider for development
use Illuminate\Support\Facades\DB;

DB::listen(function ($query) {
    static $queryCount = 0;
    $queryCount++;

    if ($queryCount > 100) {
        Log::warning("High query count: {$queryCount}", [
            'sql' => $query->sql,
        ]);
    }
});

// Use Laravel Debugbar
// composer require barryvdh/laravel-debugbar --dev
```

## Query Optimization

### Select Only Needed Columns
```php
// BAD
$users = User::all();

// GOOD
$users = User::select(['id', 'name', 'email'])->get();
```

### Use Chunking for Large Datasets
```php
// Process in chunks (memory efficient)
User::chunk(1000, function ($users) {
    foreach ($users as $user) {
        // Process
    }
});

// ChunkById for updates
User::where('active', false)
    ->chunkById(1000, function ($users) {
        foreach ($users as $user) {
            $user->delete();
        }
    });
```

### Efficient Counting
```php
// BAD
$count = User::all()->count();

// GOOD
$count = User::count();

// With relationships
$users = User::withCount('posts')->get();
// Access: $user->posts_count
```

## Index Strategy

```php
Schema::table('orders', function (Blueprint $table) {
    // Single column - for WHERE clauses
    $table->index('status');

    // Composite - for WHERE + ORDER BY
    $table->index(['user_id', 'created_at']);

    // Unique - for uniqueness + lookups
    $table->unique('order_number');
});
```

## Relationship Patterns

```php
// One to Many
public function orders(): HasMany
{
    return $this->hasMany(Order::class);
}

// Many to Many with Pivot
public function roles(): BelongsToMany
{
    return $this->belongsToMany(Role::class)
        ->withPivot(['expires_at'])
        ->withTimestamps();
}

// Has Many Through
public function orderItems(): HasManyThrough
{
    return $this->hasManyThrough(OrderItem::class, Order::class);
}
```

## Database Transactions

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function () {
    $order = Order::create([...]);
    $order->items()->createMany([...]);
});
```

## Common Pitfalls

1. **N+1 Queries** - Always eager load relationships
2. **Big O Issues** - Avoid nested loops, use keyBy/groupBy for O(1) lookups
3. **Missing Indexes** - Add indexes for WHERE and ORDER BY
4. **SELECT *** - Only select needed columns
5. **No Chunking** - Use chunk() for large datasets
6. **In-Loop Queries** - Batch queries outside loops
7. **contains() in Loops** - Use flip()->has() for O(1) lookups
8. **No Foreign Keys** - Always use constraints
9. **No Transactions** - Wrap related operations

## Package Integration

- **beyondcode/laravel-query-detector** - N+1 detection
- **barryvdh/laravel-debugbar** - Query profiling
- **spatie/laravel-query-builder** - API query building

## Best Practices

- Design indexes based on actual queries
- Use foreign key constraints
- Monitor slow queries in production
- Use database transactions for related operations

## Related Commands

- `/laravel-agent:db:optimize` - Analyze and optimize database queries
- `/laravel-agent:db:diagram` - Generate database schema diagram

## Related Agents

- `laravel-database` - Database optimization specialist
- `laravel-migration` - Migration specialist

## Related Skills

- `laravel-performance` - Query optimization and caching
