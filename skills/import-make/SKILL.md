---
name: import-make
description: Scaffold a data importer for CSV/Excel with validation, chunking, error handling; when building bulk data imports.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(composer require) Read Write Edit
argument-hint: "<Name> [--model=<Model>] [--package=maatwebsite|spatie]"
---

## Task

Generate a robust CSV/Excel importer with validation, batching, and comprehensive error handling.

## Input

- **Name:** Importer class name (e.g., `ProductImport`, `UserImport`, `OrderImport`)
- **model:** Target Eloquent model (optional; used for namespace hints)
- **package:** Driver choice (default: `maatwebsite`)
  - `maatwebsite` — maatwebsite/excel (full-featured, Laravel-integrated)
  - `spatie` — spatie/simple-excel (lightweight, memory-efficient)

## Steps

1. **Install package** if not present:
   ```bash
   # Maatwebsite (recommended for most cases)
   composer require maatwebsite/excel

   # OR Spatie (for memory-constrained environments)
   composer require spatie/simple-excel
   ```

2. **Create Import class** in `app/Imports/<Name>Import.php`:
   - Implements required interfaces (ToModel, WithHeadingRow, WithValidation)
   - Define validation rules per column
   - Handle model creation/upsert logic
   - Configure batch size (1000) and chunk size (1000)
   - Custom error messages for validation failures

3. **Create ImportRequest** in `app/Http/Requests/<Name>ImportRequest.php`:
   - File validation (mimes, max size)
   - Authorization check (authorize() method)
   - Rate limiting hints

4. **Create ImportController** in `app/Http/Controllers/<Name>ImportController.php`:
   - GET create() — Display upload form
   - POST store() — Handle synchronous import
   - POST storeQueued() — Handle large files via queue (optional)
   - Failure handling and reporting

5. **Create upload view** (optional):
   - File input with drag-and-drop support
   - Download template link
   - Error display for failed rows

6. **Routes:**
   - GET /<name>/import — Show form
   - POST /<name>/import — Process upload
   - GET /<name>/import/template — Download template

## Reference

For in-depth patterns and templates:
- `${CLAUDE_SKILL_DIR}/references/maatwebsite-importer.md` — Full-featured approach
- `${CLAUDE_SKILL_DIR}/references/spatie-importer.md` — Lightweight streaming approach
- `${CLAUDE_SKILL_DIR}/references/error-handling.md` — Validation and failure reporting

## Security guardrails

- Validate file size (max 10MB recommended)
- Validate file MIME types (reject suspicious files)
- Escape/sanitize CSV data before processing
- Never store raw uploaded files permanently
- Log import activity (who, when, how many rows)
- Implement permission checks (authorize() in request)
- Use transactions to rollback failed imports
- Rate-limit import endpoints to prevent abuse
