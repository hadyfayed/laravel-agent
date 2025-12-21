---
description: "Full app scaffolding from description"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /scaffold:app - Full Application Scaffolding

Generate a complete Laravel application structure from a natural language description. This command creates models, migrations, controllers, views, tests, and all supporting infrastructure.

## Usage

```bash
/laravel-agent:scaffold:app [app description]
```

## Input
$ARGUMENTS = Natural language description of the application to build

## Examples

```bash
/laravel-agent:scaffold:app e-commerce store with products, categories, cart, and checkout
/laravel-agent:scaffold:app blog platform with posts, comments, tags, and user profiles
/laravel-agent:scaffold:app project management tool with tasks, milestones, and team members
/laravel-agent:scaffold:app SaaS booking system with appointments, customers, and payments
/laravel-agent:scaffold:app inventory management with products, warehouses, and stock tracking
```

## Process

### 1. Analyze Requirements

Parse the description to identify:

```
┌─────────────────────────────────────────────────────────────┐
│                    REQUIREMENT ANALYSIS                      │
├──────────────────┬──────────────────────────────────────────┤
│ Component        │ Extracted From Description                │
├──────────────────┼──────────────────────────────────────────┤
│ Entities         │ Nouns (products, users, orders)          │
│ Relationships    │ Associations (has, belongs, many)        │
│ Actions          │ Verbs (create, process, send)            │
│ Features         │ Capabilities (search, export, notify)    │
│ Integrations     │ External (payment, email, storage)       │
└──────────────────┴──────────────────────────────────────────┘
```

### 2. Generate Application Blueprint

```markdown
## Application Blueprint: [App Name]

### Domain Models
- User (authentication, profiles)
- [Model 1] (attributes, relationships)
- [Model 2] (attributes, relationships)
...

### Features
1. [Feature 1] - description
2. [Feature 2] - description
...

### API Endpoints
- GET /api/v1/[resource]
- POST /api/v1/[resource]
...

### Admin Panel
- [Resource] management
- Dashboard with metrics
...
```

### 3. Scaffold Components

Execute scaffolding in order:

```
Phase 1: Foundation
├── Database migrations
├── Eloquent models
├── Model factories
└── Database seeders

Phase 2: Backend
├── Form Requests
├── API Resources
├── Controllers
├── Services/Actions
└── Policies

Phase 3: Frontend
├── Blade views OR Inertia pages
├── Components
├── Layouts
└── Assets

Phase 4: Features
├── Authentication (if needed)
├── Admin panel (if needed)
├── API documentation
└── Queue jobs

Phase 5: Quality
├── Feature tests
├── Unit tests
├── Integration tests
└── Documentation
```

### 4. File Generation

For each entity identified:

**Migration:**
```php
Schema::create('[table]', function (Blueprint $table) {
    $table->id();
    // Extracted attributes
    $table->timestamps();
    $table->softDeletes();
});
```

**Model:**
```php
class [Model] extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [...];
    protected $casts = [...];

    // Relationships
    // Scopes
    // Accessors
}
```

**Controller:**
```php
class [Model]Controller extends Controller
{
    public function index() { ... }
    public function create() { ... }
    public function store() { ... }
    public function show() { ... }
    public function edit() { ... }
    public function update() { ... }
    public function destroy() { ... }
}
```

**Tests:**
```php
describe('[Model]', function () {
    it('can create [model]');
    it('can list [models]');
    it('can update [model]');
    it('can delete [model]');
    // Relationship tests
    // Business logic tests
});
```

### 5. Implementation

Use Task tool with `laravel-architect` agent:

```
Scaffold a complete Laravel application based on this description:

"$ARGUMENTS"

Follow this process:
1. Analyze requirements and extract entities
2. Generate application blueprint
3. Create migrations in dependency order
4. Create models with relationships
5. Create form requests with validation
6. Create API resources
7. Create controllers
8. Create service classes for complex logic
9. Create policies for authorization
10. Create views/pages
11. Create tests for all features
12. Create seeders with realistic data
13. Update routes
14. Generate API documentation

Use appropriate specialized agents:
- laravel-database for migrations/models
- laravel-api-builder for API resources
- laravel-feature-builder for features
- laravel-testing for tests
- laravel-filament or laravel-livewire for admin
```

### 6. Post-Scaffold Tasks

```bash
# Run migrations
php artisan migrate

# Seed database
php artisan db:seed

# Run tests
php artisan test

# Generate API docs
php artisan scribe:generate
```

## Output Structure

```
app/
├── Http/
│   ├── Controllers/
│   │   ├── [Model]Controller.php
│   │   └── Api/
│   │       └── V1/
│   │           └── [Model]Controller.php
│   ├── Requests/
│   │   └── [Model]/
│   │       ├── Store[Model]Request.php
│   │       └── Update[Model]Request.php
│   └── Resources/
│       └── [Model]Resource.php
├── Models/
│   └── [Model].php
├── Policies/
│   └── [Model]Policy.php
└── Services/
    └── [Model]Service.php

database/
├── migrations/
│   └── xxxx_xx_xx_create_[tables]_table.php
├── factories/
│   └── [Model]Factory.php
└── seeders/
    └── [Model]Seeder.php

resources/
└── views/
    └── [models]/
        ├── index.blade.php
        ├── create.blade.php
        ├── edit.blade.php
        └── show.blade.php

routes/
├── web.php (updated)
└── api.php (updated)

tests/
├── Feature/
│   └── [Model]Test.php
└── Unit/
    └── [Model]Test.php
```

## Scaffold Options

| Option | Description |
|--------|-------------|
| `--api-only` | Only generate API (no views) |
| `--admin` | Include Filament admin panel |
| `--livewire` | Use Livewire for frontend |
| `--inertia=vue` | Use Inertia with Vue |
| `--inertia=react` | Use Inertia with React |
| `--multi-tenant` | Add tenancy support |
| `--no-tests` | Skip test generation |

## Example: E-Commerce Scaffold

```bash
/laravel-agent:scaffold:app e-commerce with products, categories, cart, orders, payments
```

Generates:
- 8 migrations (users, products, categories, carts, cart_items, orders, order_items, payments)
- 8 models with relationships
- Product catalog with filtering
- Shopping cart functionality
- Checkout process
- Order management
- Payment integration ready
- Admin panel with Filament
- 50+ tests

## Related Commands

- [/laravel-agent:build](/commands/build.md) - Intelligent single feature building
- [/laravel-agent:feature:make](/commands/feature-make.md) - Create single feature
- [/laravel-agent:module:make](/commands/module-make.md) - Create domain module

## Related Agents

- `laravel-architect` - Overall architecture decisions
- `laravel-database` - Database design
- `laravel-feature-builder` - Feature implementation
- `laravel-testing` - Test generation
