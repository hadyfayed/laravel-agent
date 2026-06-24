# Laravel Testing Factories and Assertions Reference

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

## Factory Conventions

- Define `definition()` returning the default attribute set.
- Use nested factories for relationships: `'user_id' => User::factory()`.
- Add named state methods (`pending()`, `delivered()`) for common scenarios.
- Use `$this->faker` for randomized, non-flaky test data.

## Assertion Quick Reference

These idioms are drawn from the feature and pattern tests in `pest-patterns.md`.

### HTTP Responses
```php
$response->assertCreated();
$response->assertUnauthorized();
$response->assertUnprocessable();
$response->assertJsonStructure(['data' => ['id', 'order_number', 'total']]);
$response->assertJsonValidationErrors(['items']);
```

### Database
```php
$this->assertDatabaseHas('orders', ['user_id' => $this->user->id]);
```

### Expect (Pest)
```php
expect($calculator->subtotal($items))->toBe(45.00);
expect(fn () => $order->cancel())->toThrow(InvalidStateException::class);
```

### Fakes
```php
Event::fake();
Queue::fake();
Notification::fake();

Event::assertDispatched(OrderCreated::class);
Queue::assertPushed(SendOrderConfirmation::class);
Notification::assertSentTo($user, OrderConfirmation::class);
```

## What to Test

- The happy path for each public action or endpoint.
- Authorization: unauthenticated and unauthorized requests are rejected.
- Validation: required fields, types, and boundaries (`assertJsonValidationErrors`).
- Side effects: events dispatched, jobs queued, notifications sent (via fakes).
- Edge cases and error states (exceptions, invalid transitions).
- Behavior, not implementation — refactor without breaking the test suite.
