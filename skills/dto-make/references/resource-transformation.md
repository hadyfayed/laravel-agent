# Resource Transformation

## DTO from Model

Transform Eloquent models to DTOs for API responses.

```php
<?php

declare(strict_types=1);

namespace App\Data;

use App\Models\Product;
use Carbon\Carbon;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Lazy;
use Spatie\LaravelData\Attributes\MapOutputName;
use Spatie\LaravelData\Attributes\WithCast;
use Spatie\LaravelData\Casts\DateTimeInterfaceCast;

final class ProductData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public string $slug,
        public ?string $description,

        #[MapOutputName('price')]
        public int $price_cents,

        public string $formatted_price,

        #[WithCast(DateTimeInterfaceCast::class, format: 'Y-m-d')]
        public Carbon $created_at,

        // Lazy loaded relationships
        public Lazy|CategoryData $category,

        /** @var ProductImageData[] */
        public Lazy|array $images,
    ) {}

    public static function fromModel(Product $product): self
    {
        return new self(
            id: $product->id,
            name: $product->name,
            slug: $product->slug,
            description: $product->description,
            price_cents: $product->price_cents,
            formatted_price: $product->formatted_price,
            created_at: $product->created_at,
            category: Lazy::whenLoaded('category', $product, fn () =>
                CategoryData::from($product->category)
            ),
            images: Lazy::whenLoaded('images', $product, fn () =>
                ProductImageData::collect($product->images)
            ),
        );
    }

    public function withFullIncludes(): self
    {
        return $this->include('category', 'images');
    }
}

final class CategoryData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
    ) {}
}

final class ProductImageData extends Data
{
    public function __construct(
        public int $id,
        public string $url,
        public ?string $alt_text = null,
    ) {}
}
```

Usage in controller:

```php
public function show(Product $product): ProductData
{
    return ProductData::fromModel(
        $product->load(['category', 'images'])
    );
}

public function index(): JsonResponse
{
    $products = Product::with(['category'])->paginate();

    return ProductData::collect($products)->toResponse(request());
}
```

## Collection Methods

Work with collections of DTOs.

```php
// Collect from Eloquent collection
$productDTOs = ProductData::collect($products);

// Filter
$expensive = $productDTOs->filter(fn ($p) => $p->price_cents > 100000);

// Map transformation
$prices = $productDTOs->map(fn ($p) => $p->formatted_price);

// Convert to JSON response
return response()->json($productDTOs);

// Include relationships
$data = ProductData::collect($products)->include('images');
```

## Pagination Response

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\DataCollectionOf;

final class PaginatedProductData extends Data
{
    public function __construct(
        #[DataCollectionOf(ProductData::class)]
        public array $data,

        public int $current_page,
        public int $per_page,
        public int $total,
        public int $last_page,
    ) {}

    public static function fromPaginatedCollection($paginator)
    {
        return new self(
            data: ProductData::collect($paginator->items())->toArray(),
            current_page: $paginator->currentPage(),
            per_page: $paginator->perPage(),
            total: $paginator->total(),
            last_page: $paginator->lastPage(),
        );
    }
}
```

Usage:

```php
$products = Product::paginate();

return response()->json(
    PaginatedProductData::fromPaginatedCollection($products)
);
```

## Nested DTO Transformation

```php
<?php

declare(strict_types=1);

namespace App\Data;

use App\Models\Order;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\DataCollectionOf;

final class OrderData extends Data
{
    public function __construct(
        public int $id,
        public string $number,
        public CustomerData $customer,
        public AddressData $shipping_address,

        #[DataCollectionOf(OrderItemData::class)]
        public array $items,

        public OrderTotalsData $totals,
    ) {}

    public static function fromModel(Order $order): self
    {
        return new self(
            id: $order->id,
            number: $order->number,
            customer: CustomerData::from($order->customer),
            shipping_address: AddressData::from($order->shippingAddress),
            items: OrderItemData::collect($order->items)->toArray(),
            totals: OrderTotalsData::from([
                'subtotal_cents' => $order->subtotal_cents,
                'tax_cents' => $order->tax_cents,
                'total_cents' => $order->total_cents,
            ]),
        );
    }
}

final class OrderTotalsData extends Data
{
    public function __construct(
        public int $subtotal_cents,
        public int $tax_cents,
        public int $total_cents,
    ) {}
}
```

## Conditional Transformation

```php
public function withDetails(bool $include = false): self
{
    if (!$include) {
        return $this;
    }

    return new self(
        // ... same fields ...
        items: OrderItemData::collect($this->items)
            ->include('details')
            ->toArray(),
    );
}

// Usage
$order = OrderData::fromModel($order)->withDetails(true);
```
