# Laravel Agent

> An AI Laravel developer on drugs - thinks like an architect, codes like a craftsman, deploys like DevOps.

A Claude Code plugin marketplace providing **16 specialized Laravel development agents** that cover the entire development lifecycle. The architect analyzes every request, decides the optimal implementation approach, enforces SOLID/DRY principles, and delegates to specialized builders.

## Features

- **Intelligent Architecture Decisions** - Automatically decides between Feature, Module, Service, or Action
- **SOLID/DRY Enforcement** - Every generated code follows best practices
- **Pattern Limit** - Max 5 design patterns per project to prevent complexity
- **Laravel Boost Integration** - Uses MCP tools when available for superior context
- **Full Lifecycle Coverage** - From database to frontend to deployment
- **Multi-Tenancy Support** - Optional tenant isolation with Laratrust
- **Comprehensive Testing** - Pest tests generated for everything

## Installation

### Step 1: Add the Marketplace

```bash
/plugin marketplace add hadyfayed/laravel-agent
```

### Step 2: Install Plugins

**Core Plugins (Recommended):**
```bash
/plugin install laravel-architect@hadyfayed      # Brain - decides everything
/plugin install laravel-feature-builder@hadyfayed
/plugin install laravel-module-builder@hadyfayed
/plugin install laravel-service-builder@hadyfayed
/plugin install laravel-refactor@hadyfayed
```

**API & Testing:**
```bash
/plugin install laravel-api-builder@hadyfayed    # Versioned APIs with OpenAPI
/plugin install laravel-testing@hadyfayed        # Pest testing suite
```

**Database & Auth:**
```bash
/plugin install laravel-database@hadyfayed       # Migrations, optimization
/plugin install laravel-auth@hadyfayed           # Policies, Laratrust
```

**Frontend (TALL + Filament):**
```bash
/plugin install laravel-livewire@hadyfayed       # Livewire 3 components
/plugin install laravel-filament@hadyfayed       # Filament admin panels
```

**Async Operations:**
```bash
/plugin install laravel-queue@hadyfayed          # Jobs, events, notifications
```

**AI & LLM:**
```bash
/plugin install laravel-ai@hadyfayed             # Prism PHP, MCP servers
```

**DevOps & Security:**
```bash
/plugin install laravel-deploy@hadyfayed         # Forge, Vapor, Docker, Bref
/plugin install laravel-cicd@hadyfayed           # GitHub Actions, GitLab CI
/plugin install laravel-security@hadyfayed       # OWASP audits, security headers
```

### Step 3: Initialize Your Project

```bash
/init
```

## All Plugins

| Plugin | Description | Commands |
|--------|-------------|----------|
| **laravel-architect** | Brain - analyzes, decides, delegates | `/build`, `/init`, `/patterns` |
| **laravel-feature-builder** | Complete features with CRUD/views/API | `/feature:make` |
| **laravel-module-builder** | Reusable domain modules | - |
| **laravel-service-builder** | Services and actions | - |
| **laravel-refactor** | SOLID/DRY improvements | `/refactor` |
| **laravel-api-builder** | REST, GraphQL (Lighthouse), OAuth2 | `/api:make` |
| **laravel-testing** | Pest tests (unit/feature/API/browser) | `/test:make` |
| **laravel-database** | Migrations, optimization, relationships | `/db:optimize` |
| **laravel-auth** | Policies, Laratrust/Spatie, Socialite | - |
| **laravel-livewire** | Livewire 3 reactive components | `/livewire:make` |
| **laravel-filament** | Filament 3/4 admin with Shield RBAC | `/filament:make` |
| **laravel-queue** | Jobs, events, notifications, Horizon | `/job:make` |
| **laravel-ai** | AI features with Prism PHP & MCP | `/ai:make` |
| **laravel-deploy** | Forge, Vapor, Docker, Bref deployment | `/deploy:setup` |
| **laravel-cicd** | GitHub Actions, GitLab CI, Bitbucket | `/cicd:setup` |
| **laravel-security** | OWASP audits, security headers, CSP | `/security:audit` |

## Usage

### Intelligent Build (Recommended)

Let the architect decide:

```bash
/build invoice management system
```

The architect will:
1. Analyze the request
2. Scan your codebase for existing patterns
3. Decide implementation type
4. Delegate to appropriate builder
5. Verify with tests

### Examples by Type

```bash
# Feature (CRUD + views + API)
/build product catalog with categories

# Module (reusable logic, no UI)
/build pricing calculation engine

# Action (single operation)
/build send welcome email after registration

# Service (orchestrates operations)
/build payment processing with Stripe
```

### Direct Commands

```bash
# Create feature directly
/feature:make Orders with line items and status

# Create versioned API
/api:make Products v2 with filtering

# Generate tests
/test:make OrderService unit comprehensive

# Create Livewire component
/livewire:make Products table

# Create Filament resource
/filament:make Products

# Create queued job
/job:make ProcessOrder

# Optimize database
/db:optimize OrderController

# Refactor code
/refactor app/Http/Controllers/OrderController.php

# Check pattern usage
/patterns

# DevOps commands
/deploy:setup vapor           # Configure Vapor deployment
/cicd:setup github            # Setup GitHub Actions
/security:audit               # Run security audit
```

## How It Works

```
┌─────────────────┐
│  /build <desc>  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│         laravel-architect           │
│  • Analyzes request                 │
│  • Scans codebase                   │
│  • Checks pattern registry (max 5)  │
│  • Decides implementation type      │
│  • Enforces SOLID/DRY               │
└────────┬────────────────────────────┘
         │
         ▼ Delegates to:
┌────────┴────────┬─────────────┬──────────────┐
│                 │             │              │
▼                 ▼             ▼              ▼
Feature       Module        Service        Others...
Builder       Builder       Builder
```

## Architecture Decision Matrix

| Request Type | Implementation | Location |
|--------------|----------------|----------|
| CRUD + UI + API | Feature | `app/Features/<Name>/` |
| Reusable logic, no UI | Module | `app/Modules/<Name>/` |
| Orchestrates operations | Service | `app/Services/` |
| Single operation | Action | `app/Actions/<Domain>/` |

## Laravel Boost Integration

Works best with [Laravel Boost](https://github.com/laravel/boost) installed:

```bash
composer require laravel/boost --dev
php artisan boost:install
```

The agents use Boost's MCP tools for:
- `mcp__laravel-boost__models` - Existing models
- `mcp__laravel-boost__schema` - Database structure
- `mcp__laravel-boost__routes` - Route conflicts
- `mcp__laravel-boost__docs` - Best practices

**Note:** Laravel Boost generates its own `CLAUDE.md` with Livewire, Tailwind, Filament guidelines. This plugin uses separate agent files to avoid conflicts.

## Development Lifecycle Coverage

### Planning & Architecture
- ✅ Architectural decisions
- ✅ Pattern management (max 5)
- ✅ SOLID/DRY enforcement

### Backend Development
- ✅ Features (CRUD + views + API)
- ✅ Modules (reusable domain logic)
- ✅ Services & Actions
- ✅ Database (migrations, optimization)
- ✅ Authentication & Authorization
- ✅ API (versioning, OpenAPI docs)

### Frontend Development
- ✅ Livewire 3 components
- ✅ Filament admin panels
- ✅ Alpine.js integration

### Async Operations
- ✅ Queued jobs
- ✅ Events & Listeners
- ✅ Notifications (mail, SMS, push)
- ✅ Broadcasting (WebSockets)

### Quality Assurance
- ✅ Pest testing (unit, feature, API, browser)
- ✅ Code refactoring
- ✅ Query optimization

### Project Templates

Start with production-ready templates:

```bash
# SaaS starter with multi-tenancy, billing, teams
/project:init saas

# API-only with versioning, OpenAPI docs
/project:init api
```

## Package Integrations

The agents are aware of and integrate with **35+ Laravel packages**:

### Architecture & Structure
| Package | Integration |
|---------|-------------|
| **nwidart/laravel-modules** | Use nwidart module structure instead of app/Modules |
| **lorisleiva/laravel-actions** | AsAction pattern for multi-context actions |
| **spatie/laravel-package-tools** | Distributable package development |

### AI & LLM
| Package | Integration |
|---------|-------------|
| **prism-php/prism** | AI text generation, embeddings, tool calling |
| **laravel/mcp** | MCP server creation for AI clients |

### API & GraphQL
| Package | Integration |
|---------|-------------|
| **nuwave/lighthouse** | GraphQL schema-driven API development |
| **laravel/passport** | OAuth2 server with scopes and token management |
| **laravel/sanctum** | SPA and API token authentication |
| **spatie/laravel-query-builder** | Advanced API filtering and sorting |

### Authentication & Authorization
| Package | Integration |
|---------|-------------|
| **spatie/laravel-permission** | Role-based access control (alternative to Laratrust) |
| **bezhansalleh/filament-shield** | Filament RBAC with auto-generated permissions |
| **socialiteproviders/manager** | Social login (Google, GitHub, Apple, etc.) |

### Billing & Subscriptions
| Package | Integration |
|---------|-------------|
| **laravel/cashier** | Stripe subscriptions, invoices, webhooks |

### Development Tools
| Package | Integration |
|---------|-------------|
| **barryvdh/laravel-ide-helper** | Auto-run after model creation, PHPDoc generation |
| **barryvdh/laravel-debugbar** | Query profiling during refactoring |
| **larastan/larastan** | Static analysis with Laravel-specific rules |
| **laravel/pint** | Code formatting after generation |
| **laravel/prompts** | Beautiful CLI interfaces for artisan commands |
| **laravel/tinker** | Quick prototyping and debugging |

### Database & Utilities
| Package | Integration |
|---------|-------------|
| **kitloong/laravel-migrations-generator** | Reverse engineer existing databases |
| **spatie/laravel-tags** | Model tagging functionality |
| **spatie/laravel-sluggable** | Automatic slug generation |
| **spatie/laravel-settings** | Type-safe application settings |

### Performance & Monitoring
| Package | Integration |
|---------|-------------|
| **laravel/octane** | Stateless service patterns, parallel operations |
| **laravel/horizon** | Redis queue dashboard and monitoring |
| **laravel/telescope** | Debug dashboard and request profiling |
| **spatie/laravel-health** | Application health checks and monitoring |

### Media & Files
| Package | Integration |
|---------|-------------|
| **spatie/laravel-medialibrary** | File uploads with conversions |
| **spatie/laravel-activitylog** | Audit trail for model changes |
| **spatie/laravel-backup** | Automated database/file backups |

### Search
| Package | Integration |
|---------|-------------|
| **laravel/scout** | Full-text search with Algolia/Meilisearch |

### Deployment & DevOps
| Package | Integration |
|---------|-------------|
| **bref/laravel-bridge** | AWS Lambda serverless deployment |
| **laravel/vapor-core** | Laravel Vapor serverless |

When these packages are detected, the agents automatically:
- Adjust code generation patterns
- Recommend package-specific commands
- Follow package conventions

## Requirements

- Claude Code with Plugin support (public beta)
- Laravel 10+ project
- Optional: Laravel Boost, Laratrust, Pest, Filament

## License

MIT

## Contributing

Contributions welcome! Please read the contributing guidelines first.

## Credits

- Inspired by [Laravel Boost](https://github.com/laravel/boost)
- Built for [Claude Code](https://claude.ai/code)
