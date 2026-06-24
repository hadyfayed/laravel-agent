# Laravel Database Performance Reference

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

## N+1 Query Patterns (Detailed)

### Pattern: Basic Lazy Loading in Loop

**Symptom:** One query fetches parent records, then N queries fetch related records inside a loop.

```php
// DETECTED: N+1 issue
$orders = Order::all();  // 1 query
foreach ($orders as $order) {
    echo $order->user->name;  // N queries (one per order)
}
```

**Fix:** Use eager loading with `with()`.

```php
$orders = Order::with('user')->get();  // 1 + 1 queries
foreach ($orders as $order) {
    echo $order->user->name;  // No additional queries
}
```

### Pattern: Missing Eager Load in Controller

**Symptom:** Controller returns model(s) without relationships, then view accesses relationships.

```php
// DETECTED: N+1 in controller action
public function index()
{
    return Order::all();  // No eager loading
    // View: @foreach($orders as $order) {{ $order->user->name }}
}
```

**Fix:** Eager load in controller.

```php
public function index()
{
    return Order::with('user', 'items', 'status')->get();
}
```

### Pattern: Accessing Relationships in Resource Classes

**Symptom:** API resources access relationships without eager loading.

```php
// DETECTED: N+1 in resource transformation
class OrderResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'user' => new UserResource($this->user),  // N+1!
            'items' => OrderItemResource::collection($this->items),  // N+1!
        ];
    }
}

// Invoked with:
Order::all()->map(fn($o) => new OrderResource($o));
```

**Fix:** Eager load before transforming.

```php
// In controller
$orders = Order::with('user', 'items')->get();
return OrderResource::collection($orders);

// Or use load() if already fetched
$orders = Order::all();
$orders->load('user', 'items');  // Eager load after fetch
return OrderResource::collection($orders);
```

### Pattern: Relationship Count in Loop

**Symptom:** Calling `->count()` on relationship inside a loop.

```php
// DETECTED: N query counts
$orders = Order::all();
foreach ($orders as $order) {
    echo $order->items()->count();  // COUNT query per order!
}
```

**Fix:** Use `withCount()` for relationship counts.

```php
$orders = Order::withCount('items')->get();
foreach ($orders as $order) {
    echo $order->items_count;  // No additional queries
}
```

### Pattern: Nested Relationship Loading

**Symptom:** Accessing nested relationships without `with()`.

```php
// DETECTED: Nested N+1
foreach ($orders as $order) {
    foreach ($order->items as $item) {
        echo $item->product->name;  // 1 + N + N*M queries
    }
}
```

**Fix:** Use nested eager loading.

```php
$orders = Order::with('items.product')->get();  // 1 + 1 + 1 queries
foreach ($orders as $order) {
    foreach ($order->items as $item) {
        echo $item->product->name;  // No additional queries
    }
}
```

### Pattern: Relationship Existence Check

**Symptom:** Checking if relationship exists inside a loop.

```php
// DETECTED: N queries for existence check
$orders = Order::all();
foreach ($orders as $order) {
    if ($order->user()->exists()) {  // Query per order!
        // Process
    }
}
```

**Fix:** Use eager load and local property.

```php
$orders = Order::with('user')->get();
foreach ($orders as $order) {
    if ($order->user) {  // No query, uses loaded relationship
        // Process
    }
}
```

### Pattern: Polymorphic Relationship Without Loading

**Symptom:** Accessing polymorphic relationships without morphWith().

```php
// DETECTED: N queries for polymorphic relationships
$comments = Comment::all();  // 1 query
foreach ($comments as $comment) {
    echo $comment->commentable->title;  // N queries (one per type)
}
```

**Fix:** Use `morphWith()` (Laravel 8.42+) or load manually.

```php
// Laravel 8.42+
$comments = Comment::with('commentable')->get();

// Or manual loading for different types
$comments = Comment::all();
$commentable = collect($comments)
    ->groupBy('commentable_type')
    ->flatMap(function ($group, $type) {
        $ids = $group->pluck('commentable_id');
        return app($type)->whereIn('id', $ids)->get()
            ->keyBy(fn($m) => $m->id);
    });

foreach ($comments as $comment) {
    $comment->setRelation('commentable',
        $commentable["{$comment->commentable_id}"]
    );
}
```

### Pattern: Many-to-Many Relationships

**Symptom:** Accessing pivot data or related models in many-to-many relationships.

```php
// DETECTED: N+1 on belongsToMany
$users = User::all();  // 1 query
foreach ($users as $user) {
    $roles = $user->roles;  // N queries (one per user)
    foreach ($roles as $role) {
        echo $role->pivot->created_at;  // Pivot data included
    }
}
```

**Fix:** Eager load with pivot data.

```php
$users = User::with('roles')->get();  // Uses relationship query, not N queries
foreach ($users as $user) {
    foreach ($user->roles as $role) {
        echo $role->pivot->created_at;  // Already loaded
    }
}
```

### Pattern: Eager Load with Conditions

**Symptom:** Need to eager load but filter the relationship.

```php
// DETECTED: Lazy loading with filter
$orders = Order::with('items')->get();  // Only active items
foreach ($orders as $order) {
    $activeItems = $order->items->where('status', 'active');  // In-memory filter!
}
```

**Fix:** Use eager loading constraint.

```php
$orders = Order::with(['items' => fn($q) => $q->where('status', 'active')])
    ->get();
```

### Detection Tools for N+1

#### Using Laravel Debugbar
Install and enable Laravel Debugbar to see actual query counts:
```bash
composer require barryvdh/laravel-debugbar --dev
```

#### Query Logging
```php
DB::listen(function ($query) {
    logger()->info($query->sql);
});
```

#### N+1 Detection Package
```bash
composer require --dev beyondcode/laravel-query-detector
# or
composer require --dev barryvdh/laravel-debugbar
```

#### Quick Detection via Grep
```bash
# Find lazy loading in loops
grep -rn "foreach.*->" app/ | grep -v "with("

# Find missing eager loads
grep -rn "::all()" app/Http/Controllers/
```

### N+1 Summary Table

| Pattern | Queries | Fix |
|---------|---------|-----|
| Basic loop | 1 + N | `with()` |
| Nested loop | 1 + N + M | `with('rel.nested')` |
| Count in loop | 1 + N | `withCount()` |
| Pivot data | 1 + N | `with('relation')` stores pivot |
| Conditional eager load | Many | `with(['rel' => fn($q) => ...])` |
| Polymorphic | 1 + N | `with('morphable')` |

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

**Complexity:** If users = 1000 and orders = 5000, this is 5 million comparisons.

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

### Pattern: O(n²) contains() in Loop

**Symptom:** Calling `contains()` inside a loop on a collection.

```php
// DETECTED: O(n²) collection search
$allowedIds = collect([1, 2, 3, 4, 5]);
foreach ($items as $item) {
    if ($allowedIds->contains($item->id)) {  // Linear search each iteration!
        $allowed[] = $item;
    }
}
```

**Complexity:** If items = 1000 and allowedIds = 100, this is 100,000 searches.

**Fix:** Use flip() for O(1) hash lookup.

```php
// O(n) — flip creates hash map for O(1) lookups
$allowedMap = $allowedIds->flip();
foreach ($items as $item) {
    if ($allowedMap->has($item->id)) {
        $allowed[] = $item;
    }
}
```

### Pattern: O(n²) in_array() in Loop

**Symptom:** Using `in_array()` inside a loop.

```php
// DETECTED: O(n²) array search
$forbidden = [1, 2, 3, 4, 5];
foreach ($items as $item) {
    if (in_array($item->id, $forbidden)) {  // Linear search each iteration
        continue;
    }
    $allowed[] = $item;
}
```

**Fix:** Use array_flip() for O(1) lookup.

```php
// O(n) — flip creates lookup map
$forbiddenMap = array_flip($forbidden);
foreach ($items as $item) {
    if (isset($forbiddenMap[$item->id])) {  // Hash lookup
        continue;
    }
    $allowed[] = $item;
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

**Complexity:** If orderIds has 100 items, this is 100 database queries.

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

### Pattern: O(n²) Search with Nested Data

**Symptom:** Searching through nested arrays or collections.

```php
// DETECTED: O(n²) nested search
$needles = [1, 2, 3];
$haystack = [[1, 2], [3, 4], [5, 6]];

foreach ($needles as $needle) {
    foreach ($haystack as $hay) {
        if (in_array($needle, $hay)) {  // Linear search in nested array
            $found[] = $needle;
        }
    }
}
```

**Fix:** Flatten and use hash map.

```php
// O(n + m) — flatten once, lookup with hash
$flatMap = array_flip(array_merge(...$haystack));
foreach ($needles as $needle) {
    if (isset($flatMap[$needle])) {  // O(1) lookup
        $found[] = $needle;
    }
}
```

### Pattern: O(n²) String Operations in Loop

**Symptom:** String manipulation inside nested loops.

```php
// DETECTED: O(n²) string operations
$results = [];
foreach ($records as $record) {
    foreach ($fields as $field) {
        $results[] = $record->$field . ' - ' . $field;  // String concat
    }
}
```

**Fix:** Use efficient string building.

```php
// O(n) — pre-allocate or use implode
$results = [];
foreach ($records as $record) {
    $line = [];
    foreach ($fields as $field) {
        $line[] = $record->$field;
    }
    $results[] = implode(' - ', $line);
}
```

### Pattern: O(n³) Triple Nested Loop

**Symptom:** Three levels of nesting.

```php
// DETECTED: O(n³) complexity
foreach ($users as $user) {
    foreach ($user->orders as $order) {
        foreach ($order->items as $item) {
            // Calculations — if accessing relationships here, add 3 more O(n) factors
        }
    }
}
```

**Complexity:** With eager loading of relations, this is fine (O(n) to iterate). Without eager loading, it's O(n * m * k) database queries.

**Fix:** Eager load all nested relationships.

```php
// O(n) — all data loaded upfront
$users = User::with('orders.items')->get();
foreach ($users as $user) {
    foreach ($user->orders as $order) {
        foreach ($order->items as $item) {
            // Calculations
        }
    }
}
```

### Pattern: O(n²) Filtering with Unordered Lookups

**Symptom:** Filtering without indexing or sorting.

```php
// DETECTED: O(n²) filtering
$active = [];
foreach ($items as $item) {
    $match = false;
    foreach ($active_ids as $id) {  // Linear search each time
        if ($item->id == $id) {
            $match = true;
            break;
        }
    }
    if ($match) {
        $active[] = $item;
    }
}
```

**Fix:** Use array_filter() with flip() for O(n) operation.

```php
// O(n) — single pass
$activeIdMap = array_flip($active_ids);
$active = array_filter($items, fn($item) => isset($activeIdMap[$item->id]));
```

### Pattern: O(n²) Deduplication

**Symptom:** Removing duplicates with nested loop.

```php
// DETECTED: O(n²) deduplication
$unique = [];
foreach ($items as $item) {
    $found = false;
    foreach ($unique as $u) {  // Linear search in unique list
        if ($u->id === $item->id) {
            $found = true;
            break;
        }
    }
    if (!$found) {
        $unique[] = $item;
    }
}
```

**Fix:** Use array_unique() or collection->unique().

```php
// O(n) — hash-based deduplication
$unique = $items->unique('id')->values();
// or
$unique = array_values(array_column($items, null, 'id'));
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

### Quick Detection Regex

Search your codebase for these patterns:

```bash
# Nested loops
grep -n "foreach.*foreach" app/**/*.php

# contains() in loop
grep -n "foreach.*contains(" app/**/*.php

# in_array() in loop
grep -n "foreach.*in_array" app/**/*.php

# Query in loop
grep -n "foreach.*::" app/**/*.php | grep -E "find|where|get|first"

# String concat in loop
grep -n "foreach.*\." app/**/*.php
```

### Performance Rule of Thumb

| Complexity | 100 items | 1,000 items | 10,000 items |
|-----------|-----------|------------|-------------|
| O(n) | ✅ fast | ✅ fast | ✅ fast |
| O(n log n) | ✅ fast | ✅ fast | ✅ fast |
| O(n²) | ✅ fast | ⚠️ slow | ❌ very slow |
| O(n³) | ⚠️ slow | ❌ very slow | ❌ timeout |
| O(2ⁿ) | ❌ slow | ❌ impossible | ❌ impossible |

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

## Index Strategy and Optimization

### Why Indexes Matter

Database indexes speed up SELECT queries and WHERE conditions at the cost of slower INSERT/UPDATE (index maintenance). A well-indexed schema can reduce query time from milliseconds to microseconds.

### Index Types

#### Single-Column Index

```sql
ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE users ADD INDEX idx_email (email);
```

**Use when:**
- Column is frequently used in WHERE conditions
- Column is a foreign key
- Column is used for sorting (ORDER BY)

#### Composite (Multi-Column) Index

```sql
ALTER TABLE orders ADD INDEX idx_user_status (user_id, status);
ALTER TABLE users ADD INDEX idx_email_deleted (email, deleted_at);
```

**Use when:**
- Multiple columns are queried together frequently
- Column order matters: put equality conditions first, range conditions last
- Query pattern: `WHERE user_id = ? AND status = ?`

#### Unique Index

```sql
ALTER TABLE users ADD UNIQUE INDEX idx_email_unique (email);
```

**Use when:**
- Column must be unique (email, username, etc.)
- Database should enforce uniqueness

#### Full-Text Index

```sql
ALTER TABLE posts ADD FULLTEXT INDEX idx_title_body (title, body);
```

**Use when:**
- Searching text content
- Need fuzzy/semantic search

#### Key Index (Primary Key)

```sql
ALTER TABLE orders ADD PRIMARY KEY (id);
```

**Automatic:**
- Every table should have a primary key
- Usually auto-incrementing ID (bigint)

### Index Rules

#### Left-Most Index Rule (Composite Indexes)

For a composite index `(user_id, status, created_at)`:
- ✅ Queries using `user_id` only
- ✅ Queries using `user_id AND status`
- ✅ Queries using `user_id AND status AND created_at`
- ❌ Queries using `status AND created_at` (missing user_id)
- ❌ Queries using `created_at` (missing prefix)

#### Order Matters in Composite Indexes

Put columns in order of frequency:
1. Columns used with `=` (equality)
2. Columns used with `<`, `>`, `BETWEEN` (range)
3. Columns used for ordering

**Example:**
```sql
-- Query: WHERE user_id = ? AND created_at > ? ORDER BY status
-- Best index:
ALTER TABLE orders ADD INDEX (user_id, created_at, status);
```

### Detection: Missing Indexes

#### Foreign Keys

**Pattern:** Every foreign key should have an index.

```php
// Migration defines FK
Schema::create('orders', function (Blueprint $table) {
    $table->foreignId('user_id')->constrained();  // Auto-creates index? No!
});

// Fix: Explicitly add index
Schema::create('orders', function (Blueprint $table) {
    $table->foreignId('user_id')->constrained();
    $table->index('user_id');  // Add index
});
```

#### WHERE Clauses

**Pattern:** Columns in WHERE should be indexed.

```php
// DETECTED: Missing index
Order::where('status', 'pending')->get();  // Scans entire table!

// Fix: Add index
Schema::table('orders', function (Blueprint $table) {
    $table->index('status');
});
```

#### ORDER BY and GROUP BY

**Pattern:** Columns in ORDER BY or GROUP BY should be indexed.

```php
// DETECTED: Missing index
User::orderBy('created_at')->get();  // Full sort!

// Fix: Add index
Schema::table('users', function (Blueprint $table) {
    $table->index('created_at');
});
```

#### JOIN Conditions

**Pattern:** Columns in JOIN predicates should be indexed.

```php
// DETECTED: Join on non-indexed column
Order::join('users', 'orders.user_id', '=', 'users.id')
    ->where('users.status', 'active')
    ->get();

// Fix: Index both columns
Schema::table('orders', function (Blueprint $table) {
    $table->index('user_id');
});
Schema::table('users', function (Blueprint $table) {
    $table->index('status');
});
```

### Index Design Strategy

#### High-Traffic Tables

**orders table (millions of rows):**
```sql
-- Common queries:
-- WHERE user_id = ?
-- WHERE status = ? AND created_at > ?
-- ORDER BY created_at DESC

ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE orders ADD INDEX idx_status_created (status, created_at DESC);
```

#### Low-Cardinality Columns

**Pattern:** Status, is_active, role (few unique values).

```php
// DETECTED: Index on low-cardinality column
$users = User::where('is_active', true)->get();  // Index wastes space

// Decision: Index only if queries are frequent and result set is small
// If is_active is true for 90% of users, full table scan may be better
```

#### Large String Columns

**Pattern:** Indexing varchar(255) or larger.

```sql
-- DETECTED: Inefficient index on large string
ALTER TABLE posts ADD INDEX idx_content (content);  -- Creates large index

-- Fix: Use prefix index (first 10 chars)
ALTER TABLE posts ADD INDEX idx_content (content(10));

-- Or: Use FULLTEXT for text search
ALTER TABLE posts ADD FULLTEXT idx_content (content);
```

### Migration Template

```php
class AddIndexesToOrders extends Migration
{
    public function up()
    {
        Schema::table('orders', function (Blueprint $table) {
            // Foreign key indexes
            $table->index('user_id');
            $table->index('shipping_address_id');

            // WHERE clause indexes
            $table->index('status');
            $table->index('payment_status');

            // Composite indexes for common queries
            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);

            // Unique indexes
            $table->unique('invoice_number');
        });
    }

    public function down()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex('orders_user_id_index');
            $table->dropIndex('orders_status_index');
            $table->dropIndex('orders_user_id_status_index');
            // ... etc
        });
    }
}
```

### Performance Impact

#### Before Index
```
Query: SELECT * FROM orders WHERE user_id = 123
Time: 450ms (full table scan)
Rows examined: 1,000,000
```

#### After Index
```
Query: SELECT * FROM orders WHERE user_id = 123
Time: 2ms (index lookup)
Rows examined: 5,000
```

### Index Overhead

**Storage:** Each index uses disk space (≈10–20% of table size).

**Write Performance:** INSERT/UPDATE/DELETE are slower due to index maintenance.

**Rule:** Index frequently-queried columns, avoid indexing rarely-queried columns.

### Monitoring

```sql
-- Find unused indexes
SELECT * FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE COUNT_READ = 0;

-- Find slow queries
SET GLOBAL slow_query_log = 'ON';
SELECT * FROM mysql.slow_log;

-- Analyze index usage
ANALYZE TABLE orders;
EXPLAIN SELECT * FROM orders WHERE user_id = 123;
```

### Summary Checklist

- ✅ Every foreign key has an index
- ✅ Every column in WHERE has an index (or in composite index)
- ✅ ORDER BY and GROUP BY columns are indexed
- ✅ Composite indexes follow left-most rule and equality-then-range order
- ✅ Unique columns have unique indexes
- ✅ Large text searches use FULLTEXT indexes
- ✅ Low-cardinality columns indexed only if frequent and selective
- ✅ Unused indexes are removed
