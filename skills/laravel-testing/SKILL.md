---
name: laravel-testing
description: >
  Write comprehensive tests using Pest PHP for Laravel applications. Use when the user
  wants to write tests, improve coverage, or implement TDD. Triggers: "test", "testing",
  "pest", "phpunit", "coverage", "tdd", "unit test", "feature test", "integration test".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Testing Skill

Write comprehensive tests using Pest PHP for Laravel applications.

## When to Use

- Writing unit or feature tests
- Implementing TDD workflow
- Improving test coverage
- Testing APIs
- Browser testing with Dusk

## Quick Start

```bash
/laravel-agent:test:make <ClassName>
/laravel-agent:test:coverage
```

## Complete Feature Test

```php
<?php

declare(strict_types=1);

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
    $this->product = Product::factory()->create(['price' => 99.99]);
});

describe('Order Creation', function () {
    it('allows authenticated users to create orders', function () {
        $response = $this->actingAs($this->user)
            ->postJson('/api/orders', [
                'items' => [
                    ['product_id' => $this->product->id, 'quantity' => 2],
                ],
            ]);

        $response->assertCreated()
            ->assertJsonStructure([
                'data' => ['id', 'order_number', 'total'],
            ]);

        $this->assertDatabaseHas('orders', [
            'user_id' => $this->user->id,
        ]);
    });

    it('rejects unauthenticated requests', function () {
        $this->postJson('/api/orders', [])->assertUnauthorized();
    });

    it('validates required fields', function () {
        $this->actingAs($this->user)
            ->postJson('/api/orders', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['items']);
    });
});
```

## Unit Test Example

```php
<?php

declare(strict_types=1);

use App\Services\PriceCalculator;

describe('PriceCalculator', function () {
    beforeEach(function () {
        $this->calculator = new PriceCalculator();
    });

    it('calculates subtotal', function () {
        $items = [
            ['price' => 10.00, 'quantity' => 2],
            ['price' => 25.00, 'quantity' => 1],
        ];

        expect($this->calculator->subtotal($items))->toBe(45.00);
    });

    it('applies percentage discount', function () {
        expect($this->calculator->applyDiscount(100.00, 20))->toBe(80.00);
    });

    it('does not allow negative totals', function () {
        expect($this->calculator->applyDiscount(10.00, 50.00))->toBe(0.00);
    });
});
```

## Testing Patterns

### Testing Events
```php
use Illuminate\Support\Facades\Event;

it('dispatches OrderCreated event', function () {
    Event::fake();

    Order::factory()->create();

    Event::assertDispatched(OrderCreated::class);
});
```

### Testing Jobs
```php
use Illuminate\Support\Facades\Queue;

it('queues SendOrderConfirmation job', function () {
    Queue::fake();

    $order = Order::factory()->create();
    $order->confirm();

    Queue::assertPushed(SendOrderConfirmation::class);
});
```

### Testing Notifications
```php
use Illuminate\Support\Facades\Notification;

it('sends confirmation notification', function () {
    Notification::fake();

    $user = User::factory()->create();
    $order = Order::factory()->for($user)->create();
    $order->sendConfirmation();

    Notification::assertSentTo($user, OrderConfirmation::class);
});
```

### Testing Exceptions
```php
it('throws exception for invalid state', function () {
    $order = Order::factory()->delivered()->create();

    expect(fn () => $order->cancel())
        ->toThrow(InvalidStateException::class);
});
```

## Factory Example

```php
<?php

namespace Database\Factories;

use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

final class OrderFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'order_number' => $this->faker->unique()->numerify('ORD-######'),
            'status' => OrderStatus::Pending,
            'total' => $this->faker->randomFloat(2, 10, 500),
        ];
    }

    public function pending(): static
    {
        return $this->state(['status' => OrderStatus::Pending]);
    }

    public function delivered(): static
    {
        return $this->state(['status' => OrderStatus::Delivered]);
    }
}
```

## Common Pitfalls

1. **Not Using RefreshDatabase** - Always reset database state
2. **Testing Implementation** - Test behavior, not implementation
3. **Slow Tests** - Mock external services
4. **Missing Edge Cases** - Test boundaries and errors
5. **No Assertions** - Every test needs clear assertions
6. **Shared State** - Use beforeEach for isolation

## Package Integration

- **pestphp/pest** - Testing framework
- **pestphp/pest-plugin-laravel** - Laravel helpers
- **mockery/mockery** - Mocking library
- **laravel/dusk** - Browser testing

## Best Practices

- One assertion concept per test
- Use descriptive test names
- Test edge cases and errors
- Keep tests fast (mock slow operations)
- Use factories for test data
- Follow Arrange-Act-Assert pattern
