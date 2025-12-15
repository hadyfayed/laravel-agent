---
description: "Create Data Transfer Objects using spatie/laravel-data"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /dto:make - Create Data Transfer Objects

Generate type-safe DTOs using spatie/laravel-data for request validation, API responses, and data transformation.

## Input
$ARGUMENTS = `<DTOName> [--from=<request|model|array>] [--resource]`

Examples:
- `/dto:make CreateUserData`
- `/dto:make ProductData --from=model --resource`
- `/dto:make OrderData --from=request`

## Process

1. **Install Package** (if not installed)
   ```bash
   composer require spatie/laravel-data
   ```

2. **Create DTO Class**
   - Generate in `app/Data/` directory
   - Add validation rules
   - Add transformation methods
   - Add casts if needed

3. **Generate Related Files** (optional)
   - Request class integration
   - Resource transformation
   - Factory for testing

## Templates

### Basic DTO
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

### DTO with Validation
```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\Validation\Email;
use Spatie\LaravelData\Attributes\Validation\Max;
use Spatie\LaravelData\Attributes\Validation\Min;
use Spatie\LaravelData\Attributes\Validation\Required;
use Spatie\LaravelData\Attributes\Validation\Unique;

final class CreateUserData extends Data
{
    public function __construct(
        #[Required, Max(255)]
        public string $name,

        #[Required, Email, Unique('users', 'email')]
        public string $email,

        #[Required, Min(8)]
        public string $password,

        #[Max(20)]
        public ?string $phone = null,
    ) {}

    public static function rules(): array
    {
        return [
            'password' => ['confirmed'],
        ];
    }

    public static function messages(): array
    {
        return [
            'email.unique' => 'This email is already registered.',
        ];
    }
}
```

### DTO from Model (Resource)
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
```

### Nested DTOs
```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\DataCollectionOf;

final class OrderData extends Data
{
    public function __construct(
        public int $id,
        public string $number,
        public OrderStatus $status,
        public CustomerData $customer,
        public AddressData $shipping_address,
        public AddressData $billing_address,

        #[DataCollectionOf(OrderItemData::class)]
        public array $items,

        public MoneyData $subtotal,
        public MoneyData $tax,
        public MoneyData $total,
    ) {}
}

final class MoneyData extends Data
{
    public function __construct(
        public int $amount_cents,
        public string $currency,
        public string $formatted,
    ) {}

    public static function fromCents(int $cents, string $currency = 'USD'): self
    {
        return new self(
            amount_cents: $cents,
            currency: $currency,
            formatted: number_format($cents / 100, 2) . ' ' . $currency,
        );
    }
}
```

### DTO with Enum
```php
<?php

declare(strict_types=1);

namespace App\Data;

use App\Enums\OrderStatus;
use Spatie\LaravelData\Data;

final class UpdateOrderData extends Data
{
    public function __construct(
        public OrderStatus $status,
        public ?string $notes = null,
        public ?string $tracking_number = null,
    ) {}
}
```

## Usage

### In Controller (Request Validation)
```php
public function store(CreateUserData $data): JsonResponse
{
    // $data is already validated
    $user = User::create([
        'name' => $data->name,
        'email' => $data->email,
        'password' => Hash::make($data->password),
        'phone' => $data->phone,
    ]);

    return response()->json(UserData::from($user), 201);
}
```

### As API Resource
```php
public function index(): JsonResponse
{
    $products = Product::with(['category', 'images'])->paginate();

    return ProductData::collect($products)->toResponse(request());
}

public function show(Product $product): ProductData
{
    return ProductData::from($product->load(['category', 'images']))
        ->include('category', 'images');
}
```

### Manual Creation
```php
$data = CreateUserData::from([
    'name' => 'John Doe',
    'email' => 'john@example.com',
    'password' => 'secret123',
]);

// Or from request
$data = CreateUserData::from($request);

// Validate only
$data = CreateUserData::validateAndCreate($request->all());
```

## Interactive Prompts

When run without arguments, prompt user for:

1. **DTO name?**
   - (text input)

2. **DTO purpose?**
   - Request validation (form input)
   - API response (resource)
   - Internal data transfer
   - All of the above

3. **Properties?** (interactive builder)
   - Name: (text)
   - Type: string|int|float|bool|array|Carbon|Enum|DTO
   - Nullable: yes|no
   - Validation: required|email|max|min|unique|etc.

4. **Include validation rules?**
   - Yes
   - No

5. **From existing model?**
   - Yes (select model)
   - No (manual properties)

## Output

```markdown
## DTO Created: <Name>Data

### Files Created
- app/Data/<Name>Data.php

### Properties
| Property | Type | Nullable | Validation |
|----------|------|----------|------------|
| name | string | No | required, max:255 |
| email | string | No | required, email, unique |
| phone | string | Yes | max:20 |

### Usage Examples

**Request Validation:**
```php
public function store(<Name>Data $data)
{
    // $data is validated
}
```

**API Response:**
```php
return <Name>Data::from($model);
return <Name>Data::collect($models);
```

**Manual Creation:**
```php
$data = <Name>Data::from(['name' => 'value']);
```

### Next Steps
1. Add DTO to controller method signature
2. Customize validation rules if needed
3. Add transformations for API responses
```
