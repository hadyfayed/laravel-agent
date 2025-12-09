# API-Only Starter Template

A production-ready API-only application template with versioning, documentation, and comprehensive testing.

## Features

- **Versioned API**: `/api/v1/`, `/api/v2/` structure
- **Authentication**: Sanctum tokens or Passport OAuth2
- **Documentation**: OpenAPI 3.0 with Scribe
- **Rate Limiting**: Configurable per-endpoint limits
- **Query Builder**: Spatie Query Builder for filtering/sorting
- **API Resources**: Consistent JSON responses
- **Testing**: Comprehensive Pest API tests

## Quick Start

```bash
# Create new project
laravel new my-api --git

# Install dependencies
composer require \
    laravel/sanctum \
    spatie/laravel-query-builder \
    knuckleswtf/scribe \
    spatie/laravel-data

# Run the setup command
/project:init api
```

## Directory Structure

```
app/
├── Http/
│   ├── Controllers/
│   │   └── Api/
│   │       ├── V1/
│   │       │   ├── AuthController.php
│   │       │   └── UserController.php
│   │       └── V2/
│   ├── Middleware/
│   │   └── ForceJsonResponse.php
│   ├── Resources/
│   │   └── V1/
│   │       └── UserResource.php
│   └── Requests/
│       └── Api/
├── Data/           # DTOs with Spatie Data
└── Services/       # Business logic
routes/
├── api.php         # API version routing
├── api_v1.php      # V1 routes
└── api_v2.php      # V2 routes
```

## Configuration

### Environment Variables

```env
# API Settings
API_RATE_LIMIT=60
API_RATE_LIMIT_DECAY=1

# Auth (choose one)
API_AUTH_DRIVER=sanctum  # or passport

# CORS
CORS_ALLOWED_ORIGINS=https://app.example.com
```

### Route Registration

```php
// routes/api.php
Route::prefix('v1')->group(base_path('routes/api_v1.php'));
Route::prefix('v2')->group(base_path('routes/api_v2.php'));
```

## Usage

### Authentication

```bash
# Register
POST /api/v1/auth/register
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password",
    "password_confirmation": "password"
}

# Login
POST /api/v1/auth/login
{
    "email": "john@example.com",
    "password": "password"
}

# Response
{
    "data": {
        "token": "1|abc123...",
        "token_type": "Bearer",
        "expires_at": "2024-12-31T23:59:59Z"
    }
}
```

### Filtering & Sorting

```bash
# With Spatie Query Builder
GET /api/v1/users?filter[role]=admin&sort=-created_at&include=posts

# Pagination
GET /api/v1/users?page[number]=2&page[size]=25
```

### Response Format

```json
{
    "data": { ... },
    "meta": {
        "current_page": 1,
        "total": 100,
        "per_page": 15
    },
    "links": {
        "first": "...",
        "last": "...",
        "prev": null,
        "next": "..."
    }
}
```

### Error Format

```json
{
    "message": "Validation failed",
    "errors": {
        "email": ["The email field is required."]
    }
}
```

## API Documentation

Generate OpenAPI documentation:

```bash
php artisan scribe:generate
```

Access at `/docs` (development) or export as `openapi.yaml`.

## Testing

```bash
# Run all API tests
vendor/bin/pest --filter=Api

# Run with coverage
vendor/bin/pest --coverage --min=80
```

## Slash Commands

- `/api:resource Users` - Create API resource with controller
- `/api:version v2` - Create new API version
- `/api:docs` - Generate API documentation
- `/security:audit api` - Audit API security

## Recommended Packages

| Package | Purpose |
|---------|---------|
| laravel/sanctum | API authentication |
| spatie/laravel-query-builder | Filtering & sorting |
| spatie/laravel-data | DTOs |
| knuckleswtf/scribe | API documentation |
| nuwave/lighthouse | GraphQL (optional) |
