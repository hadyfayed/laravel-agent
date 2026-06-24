# DTO Basic Patterns

## Basic DTO

The simplest form: properties with type hints, no validation.

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;

final class CreateUserData extends Data
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
        public ?string $phone = null,
    ) {}
}
```

## DTO from Array

Convert simple associative arrays to typed objects.

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;

final class FilterData extends Data
{
    public function __construct(
        public string $search,
        public string $sort_by = 'created_at',
        public string $order = 'desc',
        public int $per_page = 15,
    ) {}
}
```

Usage:

```php
$filters = FilterData::from($request->query());
// Or from array
$filters = FilterData::from([
    'search' => 'laptop',
    'sort_by' => 'price',
]);
```

## DTO with Optional Nested Object

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;

final class PaginationData extends Data
{
    public function __construct(
        public int $current_page,
        public int $per_page,
        public int $total,
        public ?MetaData $meta = null,
    ) {}
}

final class MetaData extends Data
{
    public function __construct(
        public int $last_page,
        public bool $has_more,
    ) {}
}
```

## Enumeration

```php
<?php

declare(strict_types=1);

namespace App\Data;

use App\Enums\OrderStatus;
use Spatie\LaravelData\Data;

final class OrderStatusData extends Data
{
    public function __construct(
        public int $order_id,
        public OrderStatus $status,
        public ?string $reason = null,
    ) {}
}
```

## Array of DTOs

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\DataCollectionOf;

final class CartData extends Data
{
    public function __construct(
        public int $user_id,
        
        #[DataCollectionOf(CartItemData::class)]
        public array $items,
        
        public int $total_cents,
    ) {}
}

final class CartItemData extends Data
{
    public function __construct(
        public int $product_id,
        public string $name,
        public int $quantity,
        public int $price_cents,
    ) {}
}
```

Usage:

```php
$cart = CartData::from([
    'user_id' => 1,
    'items' => [
        ['product_id' => 10, 'name' => 'Laptop', 'quantity' => 1, 'price_cents' => 999900],
        ['product_id' => 11, 'name' => 'Mouse', 'quantity' => 2, 'price_cents' => 2500],
    ],
    'total_cents' => 1004900,
]);
```
