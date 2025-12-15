# Laravel Architecture Guidelines

Architectural patterns and decisions for Laravel applications.

## Pattern Limit

**Maximum 5 design patterns per project** to prevent complexity.

Common patterns:
1. Repository Pattern
2. Action Pattern
3. Service Pattern
4. Observer Pattern
5. Strategy Pattern

Choose based on project needs.

## Code Organization

### Feature-Based Structure
For larger applications:

```
app/
├── Features/
│   └── Orders/
│       ├── OrderServiceProvider.php
│       ├── Domain/
│       │   ├── Models/
│       │   ├── Events/
│       │   └── Enums/
│       ├── Http/
│       │   ├── Controllers/
│       │   ├── Requests/
│       │   └── Resources/
│       ├── Actions/
│       └── Tests/
```

### Standard Structure
For smaller applications:

```
app/
├── Actions/
├── Http/
│   ├── Controllers/
│   ├── Requests/
│   └── Resources/
├── Models/
├── Services/
└── Enums/
```

## Decision Matrix

| Need | Solution | Location |
|------|----------|----------|
| CRUD + UI | Feature | `app/Features/` |
| Reusable logic | Module | `app/Modules/` |
| Single operation | Action | `app/Actions/` |
| Complex orchestration | Service | `app/Services/` |

## Actions

Use actions for single-purpose operations:

```php
<?php

declare(strict_types=1);

namespace App\Actions\Orders;

final class CreateOrderAction
{
    public function __construct(
        private readonly InventoryService $inventory,
        private readonly PaymentGateway $payment,
    ) {}

    public function execute(User $user, array $items): Order
    {
        // Validate inventory
        $this->inventory->reserve($items);

        // Create order
        $order = Order::create([
            'user_id' => $user->id,
            'total' => $this->calculateTotal($items),
        ]);

        // Add items
        $order->items()->createMany($items);

        // Dispatch event
        event(new OrderCreated($order));

        return $order;
    }
}
```

## Services

Use services for complex business logic:

```php
<?php

declare(strict_types=1);

namespace App\Services;

final class PaymentService
{
    public function __construct(
        private readonly PaymentGateway $gateway,
        private readonly RefundProcessor $refunds,
    ) {}

    public function processOrder(Order $order): PaymentResult
    {
        // Complex payment logic
    }

    public function refund(Order $order, float $amount): RefundResult
    {
        // Refund logic
    }
}
```

## Repositories (Optional)

Only use if you need to abstract data access:

```php
<?php

declare(strict_types=1);

namespace App\Repositories;

interface OrderRepositoryInterface
{
    public function findById(int $id): ?Order;
    public function findByUser(User $user): Collection;
    public function save(Order $order): void;
}

final class EloquentOrderRepository implements OrderRepositoryInterface
{
    public function findById(int $id): ?Order
    {
        return Order::find($id);
    }

    // ...
}
```

## DTOs

Use DTOs for complex data structures:

```php
<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class CreateOrderData
{
    public function __construct(
        public int $userId,
        public array $items,
        public ?string $couponCode = null,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            userId: $request->user()->id,
            items: $request->validated('items'),
            couponCode: $request->validated('coupon_code'),
        );
    }
}
```

## Events & Listeners

Decouple side effects with events:

```php
// Event
final readonly class OrderCreated
{
    public function __construct(
        public Order $order,
    ) {}
}

// Listener
final class SendOrderConfirmation
{
    public function handle(OrderCreated $event): void
    {
        $event->order->user->notify(
            new OrderConfirmationNotification($event->order)
        );
    }
}
```

## Enums

Use enums for fixed values:

```php
<?php

declare(strict_types=1);

namespace App\Enums;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Processing = 'processing';
    case Shipped = 'shipped';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match($this) {
            self::Pending => 'Pending',
            self::Processing => 'Processing',
            self::Shipped => 'Shipped',
            self::Delivered => 'Delivered',
            self::Cancelled => 'Cancelled',
        };
    }

    public function canTransitionTo(self $status): bool
    {
        return match($this) {
            self::Pending => in_array($status, [self::Processing, self::Cancelled]),
            self::Processing => in_array($status, [self::Shipped, self::Cancelled]),
            self::Shipped => $status === self::Delivered,
            default => false,
        };
    }
}
```

## Dependency Injection

Always inject dependencies:

```php
// GOOD - injected
final class OrderController extends Controller
{
    public function __construct(
        private readonly CreateOrderAction $createOrder,
    ) {}

    public function store(StoreOrderRequest $request)
    {
        $order = $this->createOrder->execute($request->validated());
    }
}

// BAD - static/facade abuse
final class OrderController extends Controller
{
    public function store(Request $request)
    {
        $order = CreateOrderAction::run($request->all());
    }
}
```

## SOLID Principles

1. **Single Responsibility** - One class, one purpose
2. **Open/Closed** - Open for extension, closed for modification
3. **Liskov Substitution** - Subtypes must be substitutable
4. **Interface Segregation** - Specific interfaces over general
5. **Dependency Inversion** - Depend on abstractions

## Anti-Patterns to Avoid

1. **Fat Controllers** - Move logic to actions/services
2. **Fat Models** - Extract to traits or services
3. **God Classes** - Split into focused classes
4. **Tight Coupling** - Use dependency injection
5. **Magic Numbers** - Use enums/constants
6. **Deep Nesting** - Use early returns
