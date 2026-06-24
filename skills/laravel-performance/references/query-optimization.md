# Laravel Application-Level Performance Reference

## Database Query Selection & Streaming

### Prevent Lazy Loading in Development

```php
// app/Providers/AppServiceProvider.php
Model::preventLazyLoading(!app()->isProduction());
```

### Memory-Efficient Large Dataset Processing

#### Use cursor() — Lowest Memory
```php
// Process one at a time, minimal memory footprint
User::cursor()->each(function (User $user) {
    // Process one row, discarded after iteration
    // Cannot use eager loading
    $user->process();
});
```

#### Use lazy() — Memory-Efficient with Eager Loading
```php
// Lazy collection; can use relationships
User::lazy()->each(function (User $user) {
    // Memory efficient iteration with relationships loaded
    echo $user->profile->bio;  // Works with eager loading
});
```

#### Use chunk() — Standard Batching
```php
// Process in chunks (memory efficient)
User::chunk(1000, function ($users) {
    foreach ($users as $user) {
        // Process
    }
});

// ChunkById for updates (safer for modifications)
User::where('active', false)
    ->chunkById(1000, function ($users) {
        foreach ($users as $user) {
            $user->delete();
        }
    });
```

### Cursor vs. Lazy vs. Chunk Choice Matrix

| Use Case | Method | Memory | Eager Load? | Best For |
|----------|--------|--------|------------|----------|
| Read-only iteration, huge dataset | `cursor()` | ✅ Minimal | ❌ No | Exports, reports, background jobs |
| Iteration with relationships | `lazy()` | ✅ Low | ✅ Yes | Processing with related data |
| Standard batch processing | `chunk()` | ⚠️ Medium | ✅ Yes | Updates, mass operations, web requests |

## Memory Optimization

### Clear Query Log in Long Processes
```php
// Prevent query log from consuming memory
DB::disableQueryLog();
```

### Unset Large Variables
```php
// Free memory explicitly
$largeDataset = collect([/* ... */]);
// process...
unset($largeDataset);
```

### Use Generators for Large Data
```php
function processLargeFile($path): Generator
{
    $handle = fopen($path, 'r');
    while (($line = fgets($handle)) !== false) {
        yield $line;  // One line at a time
    }
    fclose($handle);
}

foreach (processLargeFile('large-file.csv') as $line) {
    // Process one line
}
```

## Heavy Operations in Requests — Move to Queue

Heavy work that doesn't need immediate response should be offloaded:

```php
// BAD - blocks the request
foreach ($users as $user) {
    Mail::send(new WelcomeEmail($user));
}

// GOOD - queue for background processing
foreach ($users as $user) {
    Mail::queue(new WelcomeEmail($user));
}

// Or dispatch a job
dispatch(new SendWelcomeEmails($users));
```

## Mass Updates — Use Raw Queries When Possible

For operations on large datasets without model callbacks:

```php
// BAD - loads all models, runs individual queries
Order::where('status', 'pending')
    ->where('created_at', '<', now()->subDays(30))
    ->get()
    ->each->update(['status' => 'expired']);

// GOOD - single database query, no model overhead
DB::table('orders')
    ->where('status', 'pending')
    ->where('created_at', '<', now()->subDays(30))
    ->update(['status' => 'expired']);
```

## Query-Level Optimization

**For N+1 queries, Big O complexity issues, missing indexes, and query optimization strategies, see the `laravel-database` skill's performance reference.**

The `laravel-database` skill owns the canonical library for:
- **N+1 query detection and fixes** with eager loading strategies
- **Big O complexity patterns** (nested loops, O(n²) in collections, array searches)
- **Index design and strategy** (single-column, composite, covering)
- **Query-level optimization** (SELECT columns, sorting, aggregation)

This reference focuses on **application-level** performance (streaming, batching, memory, and moving work to queues). For database-level tuning, refer to `laravel-database`.
