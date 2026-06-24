---
name: dto-make
description: Generate a typed DTO with spatie/laravel-data, validation, and casting; when creating data transfer objects.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(composer require) Read Write Edit
argument-hint: "<Name> [--from=request|model|array] [--resource]"
---

## Task

Generate a type-safe Data Transfer Object using spatie/laravel-data for request validation, API responses, and data transformation.

## Input

- **Name:** DTO class name (e.g., `CreateUserData`, `ProductData`, `OrderData`)
- **from:** Origin type (default: `request`)
  - `request` — Input validation from form/request
  - `model` — Transform Eloquent model to DTO
  - `array` — Basic array-to-object conversion
- **resource:** Include API resource transformation methods

## Steps

1. **Install spatie/laravel-data** if not present:
   ```bash
   composer require spatie/laravel-data
   ```

2. **Create DTO class** in `app/Data/<Name>.php`:
   - Constructor with typed properties
   - Validation rules (via attributes or static methods)
   - Cast definitions for special types (Carbon, Enum, etc.)
   - Transform methods if `--resource` flag is set

3. **Choose template** based on your use case:
   - **Basic DTO** — Simple properties, minimal validation
   - **DTO with Validation** — Attribute-based validation rules
   - **DTO from Model** — Resource transformation with lazy loading
   - **Nested DTOs** — Multi-level data structures with collections
   - **DTO with Enum** — Type-safe status/state fields

4. **Controller integration:**
   - Use DTO directly in method signature for auto-validation
   - Use `from()` factory to construct from arrays or models
   - Use `validateAndCreate()` for manual validation

5. **Tests:**
   - Create test with sample data
   - Verify validation rules fire on invalid input
   - Test model-to-DTO transformation if applicable

## Reference

For comprehensive patterns and examples:
- `${CLAUDE_SKILL_DIR}/references/basic-patterns.md` — Template examples
- `${CLAUDE_SKILL_DIR}/references/validation-and-casts.md` — Validation rules and type casts
- `${CLAUDE_SKILL_DIR}/references/resource-transformation.md` — API response patterns

## Security guardrails

- Never expose sensitive fields (passwords, tokens) in DTOs
- Always validate enum values; do not trust user input
- Use `Lazy` for expensive relationships to avoid N+1 queries
- Sanitize string fields before casting to prevent injection
- Store DTOs with proper type hints for IDE support
