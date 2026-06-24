---
name: db-optimize
description: Optimize database performance by analyzing queries, detecting N+1 and Big O issues, suggesting indexes, and recommending query tuning; when improving database performance.
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Read Grep Glob Edit
argument-hint: "[target]"
---

## Task

Analyze a Laravel application for database performance issues and recommend optimizations.

## Input

- **target** (optional): Controller, service, table, or path to analyze; all by default

## Steps

1. **Detect N+1 Query Patterns**
   ```bash
   grep -r "foreach.*->" app/ | grep -v "with("
   ```
   - Lazy loading inside loops
   - Missing eager loading in queries
   - Nested relationship loading without `with()`
   
   See `${CLAUDE_SKILL_DIR}/references/n1-patterns.md` for patterns and fixes.

2. **Detect Big O Complexity Issues**
   ```bash
   grep -r "foreach.*foreach" app/
   grep -r "\.contains(" app/
   grep -r "in_array(" app/
   ```
   - O(n²) nested loops
   - O(n²) contains() in loops
   - O(n²) array searches
   - O(n) queries in loops

   See `${CLAUDE_SKILL_DIR}/references/bigO-patterns.md` for patterns and fixes.

3. **Analyze Index Coverage**
   - Foreign keys without indexes
   - Columns in WHERE clauses without indexes
   - Composite indexes for multi-column queries
   - ORDER BY and GROUP BY without indexes

4. **Identify Missing Eager Loading**
   - Controllers returning Model::all() or Model::get()
   - Relationships accessed in views/resources
   - Relationship counts without withCount()
   - Polymorphic relationships without morphWith()

5. **Detect Slow Query Patterns**
   - SELECT * on large tables
   - Unbounded queries (no limit, paginate, or chunk)
   - Missing column selection
   - Unnecessary joins
   - Inefficient aggregations

6. **Check Schema Efficiency**
   - Inefficient column types (int for user_id, string for timestamps)
   - Missing constraints (NOT NULL, UNIQUE)
   - Missing default values
   - Overlapping indexes

## Output Report

Generate a prioritized report with:

### N+1 Queries
| File | Line | Relationship | Current | Fix |
|------|------|--------------|---------|-----|
| OrderController:45 | 45 | user | `$order->user` in loop | `with('user')` |
| UserController:23 | 23 | roles | `$user->roles` in loop | `with('roles')` |

### Big O Issues
| File | Line | Pattern | Complexity | Fix |
|------|------|---------|------------|-----|
| ImportService:42 | 42 | Nested loops | O(n²) | Use `groupBy()` or keyed collection |
| SyncService:85 | 85 | `contains()` in loop | O(n²) | Use `flip()->has()` for O(1) |

### Missing Indexes
| Table | Column(s) | Query Pattern | Priority |
|-------|-----------|---------------|----------|
| orders | user_id | WHERE user_id = ? | High |
| users | email | WHERE email = ? | High |
| orders | (user_id, status) | WHERE user_id AND status | Medium |

### Index Recommendations
```sql
ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE users ADD INDEX idx_email (email);
ALTER TABLE orders ADD INDEX idx_user_status (user_id, status);
```

## Laravel Relationship Optimization

### Eager Loading
```php
// N+1 issue
foreach (Order::all() as $order) {
    echo $order->user->name;
}

// Fixed with eager loading
foreach (Order::with('user')->get() as $order) {
    echo $order->user->name;
}
```

### Relationship Counts
```php
// N+1 issue — COUNT query per order
foreach ($orders as $order) {
    echo $order->items()->count();
}

// Fixed with withCount()
$orders = Order::withCount('items')->get();
foreach ($orders as $order) {
    echo $order->items_count;
}
```

### Nested Relationships
```php
// N+1 on nested relationships
Order::with('items')->get()->each(fn($o) => $o->items->each(fn($i) => $i->product));

// Fixed with nested eager loading
Order::with('items.product')->get();
```

## Reference

For detailed patterns and solutions:
- `${CLAUDE_SKILL_DIR}/references/n1-patterns.md` — N+1 query detection and fixes
- `${CLAUDE_SKILL_DIR}/references/bigO-patterns.md` — Big O complexity patterns
- `${CLAUDE_SKILL_DIR}/references/index-strategy.md` — Index design and optimization

Also refer to the `laravel-database` reference skill for comprehensive database best practices.

## Options

```bash
# Analyze entire application
/db:optimize

# Analyze specific controller
/db:optimize app/Http/Controllers/OrderController

# Analyze specific model relationships
/db:optimize app/Models/Order

# Analyze service layer
/db:optimize app/Services
```
