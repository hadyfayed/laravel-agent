# Index Strategy and Optimization

## Why Indexes Matter

Database indexes speed up SELECT queries and WHERE conditions at the cost of slower INSERT/UPDATE (index maintenance). A well-indexed schema can reduce query time from milliseconds to microseconds.

## Index Types

### Single-Column Index

```sql
ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE users ADD INDEX idx_email (email);
```

**Use when:**
- Column is frequently used in WHERE conditions
- Column is a foreign key
- Column is used for sorting (ORDER BY)

### Composite (Multi-Column) Index

```sql
ALTER TABLE orders ADD INDEX idx_user_status (user_id, status);
ALTER TABLE users ADD INDEX idx_email_deleted (email, deleted_at);
```

**Use when:**
- Multiple columns are queried together frequently
- Column order matters: put equality conditions first, range conditions last
- Query pattern: `WHERE user_id = ? AND status = ?`

### Unique Index

```sql
ALTER TABLE users ADD UNIQUE INDEX idx_email_unique (email);
```

**Use when:**
- Column must be unique (email, username, etc.)
- Database should enforce uniqueness

### Full-Text Index

```sql
ALTER TABLE posts ADD FULLTEXT INDEX idx_title_body (title, body);
```

**Use when:**
- Searching text content
- Need fuzzy/semantic search

### Key Index (Primary Key)

```sql
ALTER TABLE orders ADD PRIMARY KEY (id);
```

**Automatic:**
- Every table should have a primary key
- Usually auto-incrementing ID (bigint)

## Index Rules

### Left-Most Index Rule (Composite Indexes)

For a composite index `(user_id, status, created_at)`:
- ✅ Queries using `user_id` only
- ✅ Queries using `user_id AND status`
- ✅ Queries using `user_id AND status AND created_at`
- ❌ Queries using `status AND created_at` (missing user_id)
- ❌ Queries using `created_at` (missing prefix)

### Order Matters in Composite Indexes

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

## Detection: Missing Indexes

### Foreign Keys

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

### WHERE Clauses

**Pattern:** Columns in WHERE should be indexed.

```php
// DETECTED: Missing index
Order::where('status', 'pending')->get();  // Scans entire table!

// Fix: Add index
Schema::table('orders', function (Blueprint $table) {
    $table->index('status');
});
```

### ORDER BY and GROUP BY

**Pattern:** Columns in ORDER BY or GROUP BY should be indexed.

```php
// DETECTED: Missing index
User::orderBy('created_at')->get();  // Full sort!

// Fix: Add index
Schema::table('users', function (Blueprint $table) {
    $table->index('created_at');
});
```

### JOIN Conditions

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

## Index Design Strategy

### High-Traffic Tables

**orders table (millions of rows):**
```sql
-- Common queries:
-- WHERE user_id = ?
-- WHERE status = ? AND created_at > ?
-- ORDER BY created_at DESC

ALTER TABLE orders ADD INDEX idx_user_id (user_id);
ALTER TABLE orders ADD INDEX idx_status_created (status, created_at DESC);
```

### Low-Cardinality Columns

**Pattern:** Status, is_active, role (few unique values).

```php
// DETECTED: Index on low-cardinality column
$users = User::where('is_active', true)->get();  // Index wastes space

// Decision: Index only if queries are frequent and result set is small
// If is_active is true for 90% of users, full table scan may be better
```

### Large String Columns

**Pattern:** Indexing varchar(255) or larger.

```sql
-- DETECTED: Inefficient index on large string
ALTER TABLE posts ADD INDEX idx_content (content);  -- Creates large index

-- Fix: Use prefix index (first 10 chars)
ALTER TABLE posts ADD INDEX idx_content (content(10));

-- Or: Use FULLTEXT for text search
ALTER TABLE posts ADD FULLTEXT idx_content (content);
```

## Migration Template

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

## Performance Impact

### Before Index
```
Query: SELECT * FROM orders WHERE user_id = 123
Time: 450ms (full table scan)
Rows examined: 1,000,000
```

### After Index
```
Query: SELECT * FROM orders WHERE user_id = 123
Time: 2ms (index lookup)
Rows examined: 5,000
```

## Index Overhead

**Storage:** Each index uses disk space (≈10–20% of table size).

**Write Performance:** INSERT/UPDATE/DELETE are slower due to index maintenance.

**Rule:** Index frequently-queried columns, avoid indexing rarely-queried columns.

## Monitoring

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

## Summary Checklist

- ✅ Every foreign key has an index
- ✅ Every column in WHERE has an index (or in composite index)
- ✅ ORDER BY and GROUP BY columns are indexed
- ✅ Composite indexes follow left-most rule and equality-then-range order
- ✅ Unique columns have unique indexes
- ✅ Large text searches use FULLTEXT indexes
- ✅ Low-cardinality columns indexed only if frequent and selective
- ✅ Unused indexes are removed
