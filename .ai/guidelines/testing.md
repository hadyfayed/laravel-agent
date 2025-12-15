# Laravel Testing Guidelines

Standards for writing tests in Laravel applications.

## Testing Framework

Use Pest PHP as the primary testing framework:

```php
<?php

declare(strict_types=1);

use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);
```

## Test Organization

### File Structure
```
tests/
├── Feature/
│   ├── Http/
│   │   └── Controllers/
│   │       └── ProductControllerTest.php
│   └── Actions/
│       └── CreateProductActionTest.php
└── Unit/
    ├── Models/
    │   └── ProductTest.php
    └── Services/
        └── PriceCalculatorTest.php
```

### Naming
- Test files: `{ClassName}Test.php`
- Test descriptions: Use `describe()` and `it()`

```php
describe('ProductController', function () {
    describe('store', function () {
        it('creates a product with valid data', function () {
            // ...
        });

        it('returns validation errors for invalid data', function () {
            // ...
        });
    });
});
```

## Test Types

### Feature Tests
Test complete request/response cycles:

```php
it('creates an order', function () {
    $user = User::factory()->create();
    $product = Product::factory()->create();

    $response = $this->actingAs($user)
        ->postJson('/api/orders', [
            'items' => [
                ['product_id' => $product->id, 'quantity' => 2],
            ],
        ]);

    $response->assertCreated();
    $this->assertDatabaseHas('orders', ['user_id' => $user->id]);
});
```

### Unit Tests
Test isolated units of code:

```php
describe('PriceCalculator', function () {
    it('calculates total with tax', function () {
        $calculator = new PriceCalculator();

        $result = $calculator->calculateWithTax(100, 0.08);

        expect($result)->toBe(108.00);
    });
});
```

### API Tests
Test API endpoints with proper assertions:

```php
it('returns paginated products', function () {
    Product::factory()->count(20)->create();

    $response = $this->getJson('/api/v1/products');

    $response->assertOk()
        ->assertJsonCount(15, 'data')
        ->assertJsonStructure([
            'data' => [['id', 'name', 'price']],
            'meta' => ['current_page', 'total'],
        ]);
});
```

## Factories

Always use factories for test data:

```php
// Basic factory
User::factory()->create();

// With specific attributes
User::factory()->create(['name' => 'John']);

// With relationships
User::factory()
    ->has(Order::factory()->count(3))
    ->create();

// With states
Order::factory()->shipped()->create();
```

## Assertions

### Database Assertions
```php
$this->assertDatabaseHas('products', ['name' => 'Widget']);
$this->assertDatabaseMissing('products', ['name' => 'Deleted']);
$this->assertDatabaseCount('products', 5);
$this->assertSoftDeleted('products', ['id' => $product->id]);
```

### Response Assertions
```php
$response->assertOk();                    // 200
$response->assertCreated();               // 201
$response->assertNoContent();             // 204
$response->assertUnauthorized();          // 401
$response->assertForbidden();             // 403
$response->assertNotFound();              // 404
$response->assertUnprocessable();         // 422
```

### Pest Expectations
```php
expect($user->name)->toBe('John');
expect($items)->toHaveCount(3);
expect($price)->toBeGreaterThan(0);
expect($order->status)->toBeInstanceOf(OrderStatus::class);
expect(fn() => $action->execute())->toThrow(InvalidStateException::class);
```

## Mocking

### Facades
```php
use Illuminate\Support\Facades\Mail;

Mail::fake();

// Perform action that sends mail

Mail::assertSent(WelcomeMail::class);
```

### External Services
```php
$gateway = Mockery::mock(PaymentGateway::class);
$gateway->shouldReceive('charge')
    ->once()
    ->with(100.00)
    ->andReturn(['success' => true]);

$this->app->instance(PaymentGateway::class, $gateway);
```

## Test Isolation

- Always use `RefreshDatabase` trait
- Use `beforeEach()` for common setup
- Never depend on test execution order
- Clean up any created files

```php
uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});

afterEach(function () {
    Storage::disk('public')->deleteDirectory('uploads');
});
```

## Coverage Requirements

| Type | Target |
|------|--------|
| Controllers | 90% |
| Actions/Services | 95% |
| Models | 80% |
| Critical paths | 100% |

## Best Practices

1. **One concept per test** - Test one behavior at a time
2. **Descriptive names** - Use clear, readable test descriptions
3. **Arrange-Act-Assert** - Structure tests clearly
4. **Test behavior** - Not implementation details
5. **Fast tests** - Mock slow operations
6. **Independent tests** - No shared state between tests
