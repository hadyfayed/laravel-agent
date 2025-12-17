---
description: "Generate comprehensive tests for a class or feature"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /test:make - Generate Tests

Generate comprehensive [Pest PHP](https://pestphp.com/) tests for any class, feature, or API. The command analyzes existing code and creates tests covering happy paths, edge cases, validation, authorization, and database interactions.

## Input
$ARGUMENTS = `<Target> [type] [coverage]`

Examples:
- `/test:make OrderService` - Unit tests for service
- `/test:make Orders feature` - Feature tests for Orders
- `/test:make api/v1/products api` - API tests
- `/test:make Checkout browser` - Dusk browser tests
- `/test:make Invoice all comprehensive` - All test types

## Types
- `unit` - Isolated class tests
- `feature` - HTTP/controller tests
- `api` - API endpoint tests
- `browser` - Dusk tests
- `all` - Generate all types

## Coverage Levels
- `basic` - Happy path only
- `comprehensive` - Happy path + edge cases + errors (default)
- `exhaustive` - All scenarios including performance

## What Gets Created

| Test Type | Location | Description |
|-----------|----------|-------------|
| Feature Tests | `tests/Feature/` | HTTP tests for controllers and routes |
| Unit Tests | `tests/Unit/` | Isolated tests for services and helpers |
| API Tests | `tests/Feature/Api/` | JSON API endpoint tests with assertions |
| Livewire Tests | `tests/Feature/Livewire/` | Component tests using Livewire testing utilities |

## Test Coverage Areas

Generated tests automatically cover:

- **Happy paths** - Standard successful operations
- **Validation** - Required fields, format validation, unique constraints
- **Authorization** - Policy checks, gate permissions, role-based access
- **Database state** - assertDatabaseHas, assertDatabaseMissing
- **Relationships** - Cascade deletes, foreign key constraints
- **Edge cases** - Empty inputs, boundary values, null handling

## Options

Customize test generation by including these in your description:

- **with mocking** - Generate mocks for external dependencies
- **with factories** - Use model factories for test data
- **with database** - Include RefreshDatabase trait and DB assertions
- **with coverage** - Add @covers annotations for coverage tracking
- **unit only** - Generate only unit tests (no HTTP tests)
- **feature only** - Generate only feature tests (no unit tests)

## Example Generated Tests

For `/test:make ProductController`:

```php
<?php

use App\Models\Product;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

describe('ProductController', function () {

    describe('index', function () {
        it('returns paginated products', function () {
            Product::factory()->count(15)->create();

            $response = $this->getJson('/api/v1/products');

            $response->assertOk()
                ->assertJsonCount(10, 'data')
                ->assertJsonStructure([
                    'data' => [['id', 'name', 'price']],
                    'meta' => ['current_page', 'total'],
                ]);
        });

        it('filters products by category', function () {
            Product::factory()->create(['category' => 'electronics']);
            Product::factory()->create(['category' => 'clothing']);

            $response = $this->getJson('/api/v1/products?filter[category]=electronics');

            $response->assertOk()
                ->assertJsonCount(1, 'data');
        });
    });

    describe('store', function () {
        it('creates a product with valid data', function () {
            $user = User::factory()->create();

            $response = $this->actingAs($user)
                ->postJson('/api/v1/products', [
                    'name' => 'Test Product',
                    'price' => 99.99,
                ]);

            $response->assertCreated()
                ->assertJsonPath('data.name', 'Test Product');

            $this->assertDatabaseHas('products', [
                'name' => 'Test Product',
            ]);
        });

        it('validates required fields', function () {
            $user = User::factory()->create();

            $response = $this->actingAs($user)
                ->postJson('/api/v1/products', []);

            $response->assertUnprocessable()
                ->assertJsonValidationErrors(['name', 'price']);
        });

        it('requires authentication', function () {
            $response = $this->postJson('/api/v1/products', [
                'name' => 'Test',
            ]);

            $response->assertUnauthorized();
        });
    });

    describe('destroy', function () {
        it('deletes a product', function () {
            $user = User::factory()->create();
            $product = Product::factory()->create();

            $response = $this->actingAs($user)
                ->deleteJson("/api/v1/products/{$product->id}");

            $response->assertNoContent();

            $this->assertDatabaseMissing('products', [
                'id' => $product->id,
            ]);
        });

        it('returns 404 for non-existent product', function () {
            $user = User::factory()->create();

            $response = $this->actingAs($user)
                ->deleteJson('/api/v1/products/99999');

            $response->assertNotFound();
        });
    });
});
```

## Pest PHP Features Used

Generated tests leverage modern Pest PHP features:

- `describe()` - Group related tests by method or feature
- `it()` - Expressive test naming
- `beforeEach()` - Shared setup for test groups
- `uses()` - Trait application (RefreshDatabase, etc.)
- `expect()` - Expectation API for fluent assertions
- Datasets - Parameterized testing for multiple inputs

## Best Practices

1. **Use factories** - Let factories handle test data creation
2. **Test behavior, not implementation** - Focus on what, not how
3. **One assertion concept per test** - Keep tests focused
4. **Add edge cases** - Generated tests cover basics; add your domain-specific cases
5. **Run frequently** - Use `/test:coverage` to track progress

## Process

Use Task tool with subagent_type `laravel-testing`:
```
Generate tests:

Target: <target>
Type: <type>
Coverage: <coverage>
```
