# Big O Complexity Patterns Detection and Solutions

## Pattern: O(n²) Nested Loops

**Symptom:** Two nested loops comparing or searching elements.

```php
// DETECTED: O(n²) nested loops
foreach ($users as $user) {
    foreach ($orders as $order) {
        if ($order->user_id === $user->id) {
            $userOrders[] = $order;
        }
    }
}
```

**Complexity:** If users = 1000 and orders = 5000, this is 5 million comparisons.

**Fix:** Group by foreign key.

```php
// O(n + m) — groupBy creates O(1) lookup
$ordersByUser = $orders->groupBy('user_id');
foreach ($users as $user) {
    $userOrders = $ordersByUser->get($user->id) ?? collect();
}
```

## Pattern: O(n²) contains() in Loop

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

## Pattern: O(n²) in_array() in Loop

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

## Pattern: O(n) Query Per Loop Iteration

**Symptom:** Database query inside a loop.

```php
// DETECTED: O(n) queries
foreach ($userIds as $userId) {
    $user = User::find($userId);  // Query per iteration!
    $user->process();
}
```

**Complexity:** If userIds has 100 items, this is 100 database queries.

**Fix:** Batch fetch with whereIn().

```php
// O(1) — single database query
$users = User::whereIn('id', $userIds)->get()->keyBy('id');
foreach ($userIds as $userId) {
    $users[$userId]->process();  // O(1) collection lookup
}
```

## Pattern: O(n²) Search with Nested Data

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

## Pattern: O(n²) String Operations in Loop

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

## Pattern: O(n³) Triple Nested Loop

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

## Pattern: O(n²) Filtering with Unordered Lookups

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

## Pattern: O(n²) Deduplication

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

## Quick Detection Regex

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

## Performance Rule of Thumb

| Complexity | 100 items | 1,000 items | 10,000 items |
|-----------|-----------|------------|-------------|
| O(n) | ✅ fast | ✅ fast | ✅ fast |
| O(n log n) | ✅ fast | ✅ fast | ✅ fast |
| O(n²) | ✅ fast | ⚠️ slow | ❌ very slow |
| O(n³) | ⚠️ slow | ❌ very slow | ❌ timeout |
| O(2ⁿ) | ❌ slow | ❌ impossible | ❌ impossible |

## Summary

| Pattern | Complexity | Fix |
|---------|-----------|-----|
| Double loop comparison | O(n²) | `groupBy()` or `flip()` |
| contains() in loop | O(n²) | `flip()->has()` |
| in_array() in loop | O(n²) | `array_flip()` |
| Query per item | O(n) queries | `whereIn()->get()` |
| Triple nested loop | O(n³) | Eager load relations |
| Deduplication | O(n²) | `unique()` or `array_unique()` |
