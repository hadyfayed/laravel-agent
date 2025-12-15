---
name: laravel-api
description: >
  Build production-ready REST APIs with versioning, documentation, and rate limiting.
  Use when the user wants to create API endpoints, build a REST API, add API resources,
  or generate OpenAPI documentation. Triggers: "build api", "create endpoint", "api resource",
  "rest api", "api documentation", "swagger".
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
routes/
└── api/
    └── v1.php
```

## Key Patterns

### Versioned Routes
```php
// routes/api/v1.php
Route::prefix('v1')->group(function () {
    Route::apiResource('products', ProductController::class);
});
```

### API Resources
```php
final class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'price' => $this->price_formatted,
            'links' => [
                'self' => route('api.v1.products.show', $this),
            ],
        ];
    }
}
```

### Rate Limiting
```php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});
```

## Response Format

```json
{
    "data": { ... },
    "meta": {
        "current_page": 1,
        "total": 100
    },
    "links": {
        "self": "...",
        "next": "..."
    }
}
```

## Package Integration

- **spatie/laravel-query-builder** - Filter, sort, include
- **spatie/laravel-fractal** - Transformers
- **knuckleswtf/scribe** - API documentation
- **laravel/sanctum** - API authentication

## Best Practices

- Always version APIs from the start
- Use API resources for transformation
- Implement proper error responses
- Add rate limiting
- Document with OpenAPI
- Test all endpoints
