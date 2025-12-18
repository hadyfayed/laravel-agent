---
description: "Analyze and optimize database queries and schema"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /db:optimize - Database Optimization

Analyze queries, suggest indexes, fix N+1 issues, and detect Big O complexity problems.

## Input
$ARGUMENTS = `[target]`

Examples:
- `/db:optimize` - Analyze entire application
- `/db:optimize OrderController` - Analyze specific controller
- `/db:optimize orders` - Analyze specific table

## What Gets Analyzed

| Area | Checks |
|------|--------|
| N+1 Queries | Lazy loading in loops, missing eager loads |
| Big O Issues | Nested loops O(n²), contains() in loops, in-loop queries |
| Indexes | Missing indexes on foreign keys, WHERE clauses, ORDER BY |
| Schema | Inefficient column types, missing constraints |
| Queries | SELECT *, unnecessary columns, slow queries |

## Big O Complexity Patterns Detected

```php
// DETECTED: O(n²) nested loops
foreach ($users as $user) {
    foreach ($orders as $order) {
        if ($order->user_id === $user->id) { /* ... */ }
    }
}
// FIX: Use User::with('orders') or groupBy()

// DETECTED: O(n²) contains() in loop
foreach ($items as $item) {
    if ($collection->contains($item->id)) { /* ... */ }
}
// FIX: Use $collection->pluck('id')->flip()->has()

// DETECTED: O(n) queries in loop
foreach ($orderIds as $orderId) {
    $order = Order::find($orderId); // Query per iteration!
}
// FIX: Order::whereIn('id', $orderIds)->get()->keyBy('id')
```

## Process

Use Task tool with subagent_type `laravel-database`:
```
Optimize database:

Target: <target or "all">

1. Scan for N+1 queries
2. Detect Big O complexity issues (O(n²) patterns)
3. Check missing indexes
4. Analyze slow queries
5. Suggest eager loading
6. Review schema efficiency
7. Provide specific fixes with code examples
```

## Output

```markdown
## Database Optimization Report

### N+1 Queries Found
| Location | Relationship | Fix |
|----------|--------------|-----|
| OrderController:index | user | Add ->with('user') |

### Big O Issues Found
| Location | Pattern | Complexity | Fix |
|----------|---------|------------|-----|
| ImportService:42 | Nested loops | O(n²) | Use groupBy() |
| SyncService:85 | contains() in loop | O(n²) | Use flip()->has() |

### Missing Indexes
| Table | Column | Query Pattern |
|-------|--------|---------------|
| orders | user_id | WHERE user_id = ? |

### Recommendations
1. Add eager loading for relationships
2. Use keyBy()/groupBy() for O(1) lookups
3. Batch operations instead of in-loop queries
```
