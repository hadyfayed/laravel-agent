---
description: "Create a versioned API resource with documentation"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /api:make - Create API Resource

Create a complete versioned API with resources, controllers, filters, and OpenAPI docs.

## Input
$ARGUMENTS = `<ResourceName> [version] [features]`

Examples:
- `/api:make Products`
- `/api:make Orders v2`
- `/api:make Invoices v1 with filtering and rate-limiting`

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
