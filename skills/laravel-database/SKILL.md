---
name: laravel-database
description: >
  Optimize database operations, create migrations, fix N+1 queries, and design schemas.
  Use when the user mentions database issues, needs migrations, or wants query optimization.
  Triggers: "migration", "database", "query", "N+1", "index", "schema", "relationship",
  "eloquent", "slow query", "optimize database".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Database Skill

Optimize database operations, design schemas, and fix performance issues.

## When to Use

- Creating or modifying migrations
- Fixing N+1 query problems
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
2. **Missing Indexes** - Add indexes for WHERE and ORDER BY
3. **SELECT *** - Only select needed columns
4. **No Chunking** - Use chunk() for large datasets
5. **No Foreign Keys** - Always use constraints
6. **No Transactions** - Wrap related operations

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
