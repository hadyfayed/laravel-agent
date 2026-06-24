# Performance Analysis Patterns

## N+1 Query Detection

### Pattern: Lazy loading in loops

```php
// DETECTED: N+1 query
foreach ($orders as $order) {
    echo $order->user->name;  // Query per iteration
}

// FIX: Use eager loading
$orders = Order::with('user')->get();
foreach ($orders as $order) {
    echo $order->user->name;  // All loaded upfront
}
```

### Pattern: Missing eager load in controller

```php
// DETECTED: N+1 in index()
public function index()
{
    return Order::all();  // Loads orders
    // Later in view: @foreach($orders as $order) {{ $order->user->name }}
}

// FIX: Eager load relationships
public function index()
{
    return Order::with('user', 'items')->get();
}
```

### Pattern: Nested relationships

```php
// DETECTED: N+1 on nested relationships
foreach ($orders as $order) {
    foreach ($order->items as $item) {
        echo $item->product->name;  // 1 + N + M queries
    }
}

// FIX: Use nested eager loading
$orders = Order::with('items.product')->get();
```

## Big O Complexity Issues

### Pattern: O(n²) nested loops

```php
// DETECTED: O(n²) nested loops
foreach ($users as $user) {
    foreach ($orders as $order) {
        if ($order->user_id === $user->id) {
            // Process
        }
    }
}

// FIX: Use keyed collections or eager loading
$orders = Order::whereIn('user_id', $users->pluck('id'))->get();
$ordersByUser = $orders->groupBy('user_id');
foreach ($users as $user) {
    $userOrders = $ordersByUser->get($user->id);
}
```

### Pattern: O(n²) contains() in loop

```php
// DETECTED: O(n²) contains() performance
foreach ($items as $item) {
    if ($allowedIds->contains($item->id)) {  // Linear search each iteration
        // Process
    }
}

// FIX: Use flip()->has() for O(1) lookup
$allowedIdMap = $allowedIds->flip();
foreach ($items as $item) {
    if ($allowedIdMap->has($item->id)) {  // Hash lookup
        // Process
    }
}
```

### Pattern: O(n) queries in loop

```php
// DETECTED: Query per iteration — O(n) queries
foreach ($orderIds as $orderId) {
    $order = Order::find($orderId);  // Query per iteration!
    $order->process();
}

// FIX: Batch query upfront
$orders = Order::whereIn('id', $orderIds)->get()->keyBy('id');
foreach ($orderIds as $orderId) {
    $order = $orders->get($orderId);  // O(1) lookup
    $order->process();
}
```

### Pattern: O(n) array search in loop

```php
// DETECTED: in_array() per iteration — O(n²)
foreach ($records as $record) {
    if (in_array($record->id, $ids)) {  // Linear search
        // Process
    }
}

// FIX: Use flip() for O(1) lookup
$idMap = array_flip($ids);
foreach ($records as $record) {
    if (isset($idMap[$record->id])) {  // Hash lookup
        // Process
    }
}
```

## Index Analysis

### Missing indexes on foreign keys

```
DETECTED: Foreign key without index
users.department_id — used in:
  - app/Models/User.php (belongs to Department)
  - app/Http/Controllers/UserController.php:list() (WHERE department_id = ?)

FIX: Create index in migration
Schema::table('users', function (Blueprint $table) {
    $table->index('department_id');
});
```

### Missing indexes on WHERE clauses

```
DETECTED: Column used in WHERE but not indexed
orders.status — used in 8 queries
  - OrderController:index (WHERE status = ?)
  - reports:monthly (WHERE status IN (...))

FIX: Create index
Schema::table('orders', function (Blueprint $table) {
    $table->index('status');
});
```

### Composite indexes for multi-column queries

```php
// DETECTED: Query with multiple WHERE conditions
Order::where('user_id', $user)->where('status', 'pending')->get();

// FIX: Create composite index
Schema::table('orders', function (Blueprint $table) {
    $table->index(['user_id', 'status']);
});
```

## Caching Opportunities

### Missing route caching

```bash
DETECTED: Routes cached=false
FIX: Enable in production
php artisan route:cache
```

### Missing config caching

```bash
DETECTED: Config cached=false
FIX: Enable in production
php artisan config:cache
```

### Missing query caching

```php
// DETECTED: Repeated expensive query
public function getSettings() {
    return Setting::all();  // Runs every time
}

// FIX: Cache result
public function getSettings() {
    return Cache::remember('settings', 3600, fn() => Setting::all());
}
```

## Memory-Intensive Operations

### Pattern: Loading entire table into memory

```php
// DETECTED: Memory spike on large tables
$users = User::all();  // Loads all 100k rows into memory
foreach ($users as $user) {
    // Process
}

// FIX: Chunk queries
User::chunk(1000, function ($users) {
    foreach ($users as $user) {
        // Process
    }
});
```

### Pattern: Unbound SELECT

```php
// DETECTED: SELECT * on large tables
$orders = DB::table('orders')->select('*')->get();

// FIX: Select only needed columns
$orders = DB::table('orders')
    ->select('id', 'user_id', 'total')
    ->get();
```
