---
name: laravel-api
description: >
  Build production-ready REST APIs with versioning, documentation, and rate limiting.
  Use when the user wants to create API endpoints, build a REST API, add API resources,
  or generate OpenAPI documentation. Triggers: "build api", "create endpoint", "api resource",
  "rest api", "api documentation", "swagger", "json api", "graphql".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel API Builder Skill

Build RESTful APIs with versioning, documentation, and best practices.

## When to Use

- User wants to "build an API" or "create endpoints"
- Need versioned API routes (v1, v2)
- Want OpenAPI/Swagger documentation
- Building API resources and transformers

## Quick Start

```bash
/laravel-agent:api:make <Resource> [version]
/laravel-agent:api:docs
```

## Structure Generated

```
app/Http/
├── Controllers/Api/
│   └── V1/
│       └── <Resource>Controller.php
├── Resources/
│   └── V1/
│       ├── <Resource>Resource.php
│       └── <Resource>Collection.php
├── Middleware/
│   └── ApiVersion.php
routes/
└── api/
    └── v1.php
```

## Complete API Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreProductRequest;
use App\Http\Requests\Api\V1\UpdateProductRequest;
use App\Http\Resources\V1\ProductCollection;
use App\Http\Resources\V1\ProductResource;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Spatie\QueryBuilder\QueryBuilder;
use Spatie\QueryBuilder\AllowedFilter;

final class ProductController extends Controller
{
    public function index(Request $request): ProductCollection
    {
        $products = QueryBuilder::for(Product::class)
            ->allowedFilters([
                'name',
                'status',
                AllowedFilter::exact('category_id'),
                AllowedFilter::scope('price_between'),
            ])
            ->allowedSorts(['name', 'price', 'created_at'])
            ->allowedIncludes(['category', 'variants'])
            ->paginate($request->input('per_page', 15))
            ->appends($request->query());

        return new ProductCollection($products);
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        $product = Product::create($request->validated());

        return response()->json([
            'data' => new ProductResource($product),
            'message' => 'Product created successfully.',
        ], Response::HTTP_CREATED);
    }

    public function show(Product $product): ProductResource
    {
        $product->load(['category', 'variants']);

        return new ProductResource($product);
    }

    public function update(UpdateProductRequest $request, Product $product): ProductResource
    {
        $product->update($request->validated());

        return new ProductResource($product->fresh());
    }

    public function destroy(Product $product): JsonResponse
    {
        $product->delete();

        return response()->json([
            'message' => 'Product deleted successfully.',
        ], Response::HTTP_OK);
    }
}
```

## API Resource with Conditional Data

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => 'products',
            'attributes' => [
                'name' => $this->name,
                'slug' => $this->slug,
                'description' => $this->description,
                'price' => $this->price,
                'price_formatted' => $this->price_formatted,
                'status' => $this->status->value,
                'created_at' => $this->created_at->toISOString(),
                'updated_at' => $this->updated_at->toISOString(),
            ],
            'relationships' => [
                'category' => $this->whenLoaded('category', fn () => [
                    'id' => $this->category->id,
                    'name' => $this->category->name,
                ]),
                'variants' => $this->whenLoaded('variants', fn () =>
                    ProductVariantResource::collection($this->variants)
                ),
            ],
            'links' => [
                'self' => route('api.v1.products.show', $this->id),
            ],
            'meta' => $this->when($request->user()?->isAdmin(), [
                'internal_notes' => $this->internal_notes,
            ]),
        ];
    }
}
```

## API Collection with Meta

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\ResourceCollection;

final class ProductCollection extends ResourceCollection
{
    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
        ];
    }

    public function with(Request $request): array
    {
        return [
            'meta' => [
                'api_version' => 'v1',
                'documentation' => url('/api/docs'),
            ],
        ];
    }
}
```

## Versioned Routes

```php
// routes/api/v1.php
<?php

use App\Http\Controllers\Api\V1\ProductController;
use App\Http\Controllers\Api\V1\AuthController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->name('api.v1.')->group(function () {
    // Public routes
    Route::get('products', [ProductController::class, 'index'])->name('products.index');
    Route::get('products/{product}', [ProductController::class, 'show'])->name('products.show');

    // Protected routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('products', [ProductController::class, 'store'])->name('products.store');
        Route::put('products/{product}', [ProductController::class, 'update'])->name('products.update');
        Route::delete('products/{product}', [ProductController::class, 'destroy'])->name('products.destroy');
    });
});
```

## Rate Limiting

```php
// app/Providers/AppServiceProvider.php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;

public function boot(): void
{
    RateLimiter::for('api', function (Request $request) {
        return $request->user()
            ? Limit::perMinute(120)->by($request->user()->id)
            : Limit::perMinute(30)->by($request->ip());
    });

    // Strict limit for expensive operations
    RateLimiter::for('expensive', function (Request $request) {
        return Limit::perHour(10)->by($request->user()?->id ?: $request->ip());
    });
}
```

## Error Handling

```php
// app/Exceptions/Handler.php
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

public function render($request, Throwable $e)
{
    if ($request->expectsJson()) {
        if ($e instanceof ValidationException) {
            return response()->json([
                'message' => 'Validation failed.',
                'errors' => $e->errors(),
            ], 422);
        }

        if ($e instanceof NotFoundHttpException) {
            return response()->json([
                'message' => 'Resource not found.',
            ], 404);
        }

        return response()->json([
            'message' => $e->getMessage(),
        ], 500);
    }

    return parent::render($request, $e);
}
```

## API Tests

```php
<?php

declare(strict_types=1);

use App\Models\Product;
use App\Models\User;

beforeEach(function () {
    $this->user = User::factory()->create();
});

describe('Products API', function () {
    it('lists products with pagination', function () {
        Product::factory()->count(20)->create();

        $response = $this->getJson('/api/v1/products?per_page=10');

        $response->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonStructure([
                'data' => [['id', 'type', 'attributes']],
                'links',
                'meta',
            ]);
    });

    it('filters products by category', function () {
        $product = Product::factory()->create(['category_id' => 1]);
        Product::factory()->create(['category_id' => 2]);

        $response = $this->getJson('/api/v1/products?filter[category_id]=1');

        $response->assertOk()
            ->assertJsonCount(1, 'data');
    });

    it('requires authentication for creating products', function () {
        $response = $this->postJson('/api/v1/products', []);

        $response->assertUnauthorized();
    });

    it('creates a product when authenticated', function () {
        $data = Product::factory()->make()->toArray();

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/v1/products', $data);

        $response->assertCreated()
            ->assertJsonPath('data.attributes.name', $data['name']);
    });

    it('returns 404 for non-existent product', function () {
        $response = $this->getJson('/api/v1/products/99999');

        $response->assertNotFound()
            ->assertJson(['message' => 'Resource not found.']);
    });
});
```

## Common Pitfalls

1. **No Versioning** - Always version from the start
2. **Exposing Internal IDs** - Use UUIDs or slugs
3. **Inconsistent Responses** - Use API Resources
4. **Missing Rate Limits** - Protect against abuse
5. **No Error Standards** - Use RFC 7807 Problem Details
6. **N+1 in Collections** - Use `allowedIncludes()`

## Package Integration

- **spatie/laravel-query-builder** - Filter, sort, include
- **spatie/laravel-fractal** - Transformers
- **knuckleswtf/scribe** - API documentation
- **laravel/sanctum** - API authentication
- **laravel/passport** - OAuth2

## Best Practices

- Always version APIs from the start
- Use API resources for transformation
- Implement proper error responses
- Add rate limiting
- Document with OpenAPI
- Test all endpoints
- Use HATEOAS links
- Support sparse fieldsets
