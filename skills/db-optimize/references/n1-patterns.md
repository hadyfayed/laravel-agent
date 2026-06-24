# N+1 Query Pattern Detection and Solutions

## Pattern: Basic Lazy Loading in Loop

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

## Pattern: Missing Eager Load in Controller

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

## Pattern: Accessing Relationships in Resource Classes

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

## Pattern: Relationship Count in Loop

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

## Pattern: Nested Relationship Loading

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

## Pattern: Relationship Existence Check

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

## Pattern: Polymorphic Relationship Without Loading

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

## Pattern: Many-to-Many Relationships

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

## Pattern: Eager Load with Conditions

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

## Detection Tools

### Using Laravel Debugbar
Install and enable Laravel Debugbar to see actual query counts:
```bash
composer require barryvdh/laravel-debugbar --dev
```

### Query Logging
```php
DB::listen(function ($query) {
    logger()->info($query->sql);
});
```

### N+1 Detection Package
```bash
composer require --dev barryvdh/laravel-debugbar
# or
composer require --dev laravelsa/laravelsa
```

## Summary Table

| Pattern | Queries | Fix |
|---------|---------|-----|
| Basic loop | 1 + N | `with()` |
| Nested loop | 1 + N + M | `with('rel.nested')` |
| Count in loop | 1 + N | `withCount()` |
| Pivot data | 1 + N | `with('relation')` stores pivot |
| Conditional eager load | Many | `with(['rel' => fn($q) => ...])` |
| Polymorphic | 1 + N | `with('morphable')` |
