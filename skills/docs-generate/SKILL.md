---
name: docs-generate
description: Generate project documentation — API docs, code docs, README sections from the codebase; when documenting a project.
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Read Grep Glob Write
argument-hint: "[type] [target]"
---

## Task

Generate comprehensive documentation from your Laravel codebase. Types: `README` (default), `api`, `architecture`, `models`. Target scopes: entire project or specific directory (e.g., `app/Services`).

## Process

1. **Analyze the codebase**
   - Scan directory structure, read key configuration and entry files
   - Identify models, services, controllers, routes
   - Extract PHPDoc comments and type hints

2. **Generate documentation by type**

   **README** — Project overview with features, installation, usage examples
   - Extract `composer.json` name and description
   - List Laravel features and packages used
   - Include standard setup commands

   **API** — Endpoint reference with routes, request/response formats
   - Parse `routes/api.php` and `routes/web.php` (if applicable)
   - Document controller endpoints, HTTP methods, middleware
   - Reference authentication and permission patterns

   **Architecture** — System design with directory structure and data flow
   - Document `app/` directory structure
   - List key services, modules, patterns
   - Include relationship diagrams (Mermaid if helpful)

   **Models** — Database entities with attributes and relationships
   - Scan `app/Models`, extract Eloquent relationships
   - Document migration columns, indexes, foreign keys
   - List model methods and accessors

3. **Output to docs/ directory**

   ```
   docs/
   ├── README.md           # Project overview (all types)
   ├── API.md              # API reference (api)
   ├── ARCHITECTURE.md     # System design (architecture)
   └── MODELS.md           # Database schema (models)
   ```

4. **Interactive prompts** (if arguments omitted)

   - **Type?** README / API / Architecture / Models / All
   - **Scope?** Entire project / Directory / Feature
   - **Format?** Markdown / VitePress-compatible / Docusaurus-compatible
   - **Include diagrams?** Yes / No

5. **Report results**

   List files created with a summary of documented components (models, endpoints, services, etc.).

## See also

- `${CLAUDE_SKILL_DIR}/references/doc-templates.md` — template formats for each doc type
- Laravel API docs for model introspection patterns
