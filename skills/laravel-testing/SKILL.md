---
name: laravel-testing
description: >
  Write comprehensive Pest tests for Laravel applications including unit, feature,
  API, and browser tests. Use when the user wants to write tests, improve coverage,
  or test specific functionality. Triggers: "test", "pest", "phpunit", "coverage",
  "unit test", "feature test", "api test", "testing".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Testing Skill

Write comprehensive tests using Pest PHP for Laravel applications.

## When to Use

- User wants to "write tests" or "add test coverage"
- Testing specific features or classes
- API endpoint testing
- Browser/Dusk testing

## Quick Start

```bash
/laravel-agent:test:make <ClassName>
/laravel-agent:test:coverage
```

## Test Types

### Feature Tests
```php
describe('Order Management', function () {
    it('creates an order', function () {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->post('/orders', [
                'product_id' => Product::factory()->create()->id,
                'quantity' => 2,
            ]);

        $response->assertRedirect('/orders');
        $this->assertDatabaseHas('orders', [
            'user_id' => $user->id,
            'quantity' => 2,
        ]);
    });

    it('requires authentication', function () {
        $this->post('/orders')->assertRedirect('/login');
    });
});
```

### API Tests
```php
describe('Products API', function () {
    it('lists products', function () {
        Product::factory()->count(3)->create();

        $this->getJson('/api/v1/products')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonStructure([
                'data' => [['id', 'name', 'price']],
                'meta' => ['total'],
            ]);
    });

    it('requires api token', function () {
        $this->getJson('/api/v1/products')
            ->assertUnauthorized();
    });
});
```

### Unit Tests
```php
describe('PriceCalculator', function () {
    it('calculates discount', function () {
        $calculator = new PriceCalculator();

        expect($calculator->withDiscount(100, 10))
            ->toBe(90.0);
    });

    it('throws on negative price', function () {
        $calculator = new PriceCalculator();

        expect(fn() => $calculator->withDiscount(-100, 10))
            ->toThrow(InvalidArgumentException::class);
    });
});
```

## Key Patterns

### Factories
```php
User::factory()
    ->has(Order::factory()->count(3))
    ->create();
```

### Database Refresh
```php
uses(RefreshDatabase::class);
```

### Mocking
```php
$this->mock(PaymentGateway::class)
    ->shouldReceive('charge')
    ->once()
    ->andReturn(true);
```

### Assertions
```php
expect($user)
    ->name->toBe('John')
    ->email->toEndWith('@example.com')
    ->orders->toHaveCount(3);
```

## Coverage Requirements

| Type | Target |
|------|--------|
| Unit | 90%+ |
| Feature | 80%+ |
| Critical paths | 100% |

## Best Practices

- Use `describe()` and `it()` for readability
- One assertion concept per test
- Use factories for test data
- Isolate tests (RefreshDatabase)
- Test edge cases and errors
- Mock external services
