---
description: "Create a versioned API resource with documentation"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /api:make - Create API Resource

Create a complete versioned API with resources, controllers, filters, and OpenAPI docs.

## Overview

The `/api:make` command creates a complete, versioned REST API resource following best practices. It generates controllers, resources, requests, and routes with proper versioning, authentication, and OpenAPI documentation.

## Input
$ARGUMENTS = `<ResourceName> [version] [features]`

Examples:
- `/api:make Products`
- `/api:make Orders v2`
- `/api:make Invoices v1 with filtering and rate-limiting`
- `/api:make Products with filtering, sorting, and pagination`
- `/api:make Orders with line items, status transitions, and webhook events`
- `/api:make Users with registration, profile updates, and avatar upload`

## What Gets Created

| Component | Location | Description |
|-----------|----------|-------------|
| API Controller | `app/Http/Controllers/Api/V1/` | RESTful controller with index, show, store, update, destroy |
| API Resource | `app/Http/Resources/V1/` | JSON resource transformer with conditional attributes |
| Resource Collection | `app/Http/Resources/V1/` | Collection wrapper with pagination meta |
| Form Requests | `app/Http/Requests/Api/V1/` | Store and Update request validation |
| Query Filters | `app/Http/Filters/` | Spatie Query Builder filters for searching/sorting |
| API Routes | `routes/api/v1.php` | Versioned routes with middleware |
| OpenAPI Spec | `docs/api/` | OpenAPI 3.0 documentation |
| API Tests | `tests/Feature/Api/V1/` | Pest PHP API tests with assertions |

## API Versioning Strategy

The command implements URL-based versioning by default:

```bash
# Version 1 endpoints
GET    /api/v1/products
GET    /api/v1/products/{id}
POST   /api/v1/products
PUT    /api/v1/products/{id}
DELETE /api/v1/products/{id}

# Future versions
GET    /api/v2/products  # When breaking changes needed
```

## Options

Customize generation by including these in your description:

- **with Sanctum** - Add Laravel Sanctum token authentication
- **with rate limiting** - Add per-user rate limiting middleware
- **with pagination** - Include cursor or offset pagination
- **with filtering** - Add Spatie Query Builder for advanced filtering
- **with webhooks** - Generate webhook event dispatching
- **without docs** - Skip OpenAPI documentation generation

## Example Output Structure

For `/api:make Products with filtering and pagination`:

```bash
app/
├── Http/
│   ├── Controllers/Api/V1/
│   │   └── ProductController.php
│   ├── Requests/Api/V1/
│   │   ├── StoreProductRequest.php
│   │   └── UpdateProductRequest.php
│   ├── Resources/V1/
│   │   ├── ProductResource.php
│   │   └── ProductCollection.php
│   └── Filters/
│       └── ProductFilter.php
routes/
├── api.php
└── api/
    └── v1.php
docs/api/
└── products.yaml
tests/Feature/Api/V1/
└── ProductTest.php
```

## Generated Controller Example

```php
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\StoreProductRequest;
use App\Http\Requests\Api\V1\UpdateProductRequest;
use App\Http\Resources\V1\ProductCollection;
use App\Http\Resources\V1\ProductResource;
use App\Models\Product;
use Spatie\QueryBuilder\QueryBuilder;

class ProductController extends Controller
{
    public function index()
    {
        $products = QueryBuilder::for(Product::class)
            ->allowedFilters(['name', 'category', 'price'])
            ->allowedSorts(['name', 'price', 'created_at'])
            ->paginate();

        return new ProductCollection($products);
    }

    public function store(StoreProductRequest $request)
    {
        $product = Product::create($request->validated());

        return new ProductResource($product);
    }

    public function show(Product $product)
    {
        return new ProductResource($product->load('category'));
    }

    public function update(UpdateProductRequest $request, Product $product)
    {
        $product->update($request->validated());

        return new ProductResource($product);
    }

    public function destroy(Product $product)
    {
        $product->delete();

        return response()->noContent();
    }
}
```

## Best Practices

1. **Use consistent naming** - Plural resource names (products, not product)
2. **Version from the start** - Always use v1, even for initial release
3. **Include rate limiting** - Protect your API from abuse
4. **Document everything** - OpenAPI docs enable client generation
5. **Test thoroughly** - Generated tests cover happy paths; add edge cases

## Process

1. **Parse Arguments**
   - `name`: Resource name
   - `version`: API version (default: v1)
   - `features`: filtering, sorting, includes, rate-limiting

2. **Invoke API Builder**

   Use Task tool with subagent_type `laravel-api-builder`:
   ```
   Build API resource:

   Name: <name>
   Version: <version>
   Spec: RESTful CRUD endpoints
   Features: [filtering, sorting, pagination, includes]
   ```

3. **Report Results**
   ```markdown
   ## API Created: <Name> (V<version>)

   ### Endpoints
   - GET /api/v<version>/<names>
   - POST /api/v<version>/<names>
   - GET /api/v<version>/<names>/{id}
   - PUT /api/v<version>/<names>/{id}
   - DELETE /api/v<version>/<names>/{id}

   ### Generate Docs
   php artisan l5-swagger:generate
   ```
