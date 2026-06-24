# Validation and Casts

## Validation Attributes

Use attribute-based validation rules on properties.

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
            'password.confirmed' => 'Passwords do not match.',
        ];
    }
}
```

## Type Casts

Transform incoming data to specific types.

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Carbon\Carbon;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\WithCast;
use Spatie\LaravelData\Casts\DateTimeInterfaceCast;
use Spatie\LaravelData\Casts\Enum as EnumCast;
use App\Enums\PaymentStatus;

final class OrderData extends Data
{
    public function __construct(
        public int $id,
        public string $number,

        #[WithCast(DateTimeInterfaceCast::class, format: 'Y-m-d H:i:s')]
        public Carbon $created_at,

        #[WithCast(EnumCast::class)]
        public PaymentStatus $status,

        public int $amount_cents,
    ) {}
}
```

## Custom Cast

Create a reusable cast for domain logic.

```php
<?php

declare(strict_types=1);

namespace App\Data\Casts;

use Spatie\LaravelData\Casts\Cast;
use Spatie\LaravelData\Support\Creation\CreationContext;

final class MoneyAsCentsCast implements Cast
{
    public function cast(mixed $value, array $properties, CreationContext $context): int
    {
        if (is_float($value)) {
            return (int) round($value * 100);
        }

        return (int) $value;
    }
}
```

Usage:

```php
use App\Data\Casts\MoneyAsCentsCast;

final class ProductData extends Data
{
    public function __construct(
        public string $name,

        #[WithCast(MoneyAsCentsCast::class)]
        public int $price_cents,
    ) {}
}
```

## Mapping Input Names

Map incoming field names to different property names.

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\MapInputName;
use Spatie\LaravelData\Attributes\MapOutputName;

final class ProductData extends Data
{
    public function __construct(
        public int $id,
        public string $name,

        #[MapInputName('regular_price'), MapOutputName('price')]
        public int $price_cents,

        #[MapInputName('stock_qty')]
        public int $quantity,
    ) {}
}
```

Usage:

```php
// Input expects: regular_price, stock_qty
$product = ProductData::from([
    'id' => 1,
    'name' => 'Laptop',
    'regular_price' => 999.99,  // Maps to price_cents
    'stock_qty' => 100,          // Maps to quantity
]);

// Output produces: price instead of price_cents
$json = $product->toJson();
// {"id":1,"name":"Laptop","price":99999,"quantity":100}
```

## Conditional Validation

Validate based on field values.

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\Validation\RequiredIf;
use Spatie\LaravelData\Attributes\Validation\Max;

final class PromotionData extends Data
{
    public function __construct(
        public string $type, // 'fixed' or 'percentage'

        #[RequiredIf('type', 'fixed'), Max(1000000)]
        public ?int $fixed_amount = null,

        #[RequiredIf('type', 'percentage'), Max(100)]
        public ?int $percentage = null,
    ) {}
}
```
