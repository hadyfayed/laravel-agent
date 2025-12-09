---
description: "Generate API documentation"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /api:docs - Generate API Documentation

Generate OpenAPI/Swagger documentation for your API.

## Input
$ARGUMENTS = `[format]`

Examples:
- `/api:docs` - Generate with Scribe (default)
- `/api:docs openapi` - Generate OpenAPI 3.0 spec
- `/api:docs postman` - Generate Postman collection

## Process

1. **Check Documentation Package**
   ```bash
   composer show knuckleswtf/scribe 2>/dev/null && echo "SCRIBE=yes" || echo "SCRIBE=no"
   composer show dedoc/scramble 2>/dev/null && echo "SCRAMBLE=yes" || echo "SCRAMBLE=no"
   ```

2. **Generate Documentation**
   ```bash
   # Scribe
   php artisan scribe:generate

   # Scramble (auto-generates from code)
   # Docs available at /docs/api
   ```

3. **Report Results**
   ```markdown
   ## API Documentation Generated

   ### Access
   - HTML: /docs
   - OpenAPI: /docs/openapi.yaml
   - Postman: /docs/collection.json

   ### Endpoints Documented
   - Auth: 4 endpoints
   - Users: 5 endpoints
   - Orders: 6 endpoints

   ### Missing Documentation
   - POST /api/v1/webhooks (no description)
   - GET /api/v1/reports (missing response example)
   ```

## Documentation Packages

### Scribe (Recommended)
Full-featured, attribute-based:
```php
/**
 * @group Orders
 * @authenticated
 */
class OrderController
{
    /**
     * List orders
     *
     * @queryParam status Filter by status. Example: pending
     * @response 200 scenario="success" {"data": [...]}
     */
    public function index() {}
}
```

### Scramble
Zero-config, auto-generates from code
