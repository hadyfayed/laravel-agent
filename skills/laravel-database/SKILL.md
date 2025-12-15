---
name: laravel-database
description: >
  Database operations including migrations, Eloquent relationships, query optimization,
  and schema design. Use when the user needs help with database, migrations, models,
  relationships, queries, or performance. Triggers: "migration", "database", "schema",
  "eloquent", "query", "relationship", "index", "N+1", "optimize query".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Database Skill

Expert database operations, schema design, and query optimization.

## When to Use

- Creating migrations or modifying schema
- Designing Eloquent relationships
- Optimizing slow queries
- Fixing N+1 problems
- Adding indexes for performance

## Quick Start

```bash
/laravel-agent:db:optimize
/laravel-agent:db:diagram
```

## Key Patterns

### Migrations
```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('status')->default('pending');
    $table->decimal('total', 10, 2);
    $table->timestamps();

    // Indexes for common queries
    $table->index(['user_id', 'status']);
    $table->index('created_at');
});
```

### Relationships
```php
// One-to-Many
public function orders(): HasMany
{
    return $this->hasMany(Order::class);
}

// Many-to-Many with pivot
public function roles(): BelongsToMany
{
    return $this->belongsToMany(Role::class)
        ->withPivot('expires_at')
        ->withTimestamps();
}

// Has-Many-Through
public function orderItems(): HasManyThrough
{
    return $this->hasManyThrough(OrderItem::class, Order::class);
}
```

### N+1 Prevention
```php
// BAD - N+1 queries
$orders = Order::all();
foreach ($orders as $order) {
    echo $order->user->name; // N+1!
}

// GOOD - Eager loading
$orders = Order::with('user')->get();

// Prevent in development
Model::preventLazyLoading(!app()->isProduction());
```

### Query Optimization
```php
// Select only needed columns
User::select('id', 'name', 'email')->get();

// Use chunking for large datasets
User::chunk(1000, function ($users) {
    // Process chunk
});

// Use cursor for memory efficiency
User::cursor()->each(function ($user) {
    // Process one at a time
});
```

## Index Strategy

| Query Pattern | Index Type |
|---------------|------------|
| `WHERE column = ?` | Single column |
| `WHERE a = ? AND b = ?` | Composite (a, b) |
| `ORDER BY column` | Single column |
| `WHERE a = ? ORDER BY b` | Composite (a, b) |
| Full-text search | FULLTEXT |

## Tools Integration

- **beyondcode/laravel-query-detector** - N+1 detection
- **grazulex/laravel-devtoolbox** - Query analysis
- **Laravel Telescope** - Query monitoring

## Best Practices

- Add indexes for WHERE and ORDER BY columns
- Use foreign key constraints
- Eager load relationships
- Chunk large operations
- Use database transactions
- Monitor slow queries
