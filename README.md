# Laravel Agent

[![Documentation](https://img.shields.io/badge/docs-hadyfayed.github.io-blue)](https://hadyfayed.github.io/laravel-agent/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-purple)](https://claude.ai/code)

> AI-powered Laravel development assistant - architecture decisions, code generation, testing, deployment, and more.

A Claude Code plugin with **29 specialized agents**, **47 commands**, **21 auto-invoked skills**, and **9 quality hooks** covering the entire Laravel development lifecycle.

**[View Documentation](https://hadyfayed.github.io/laravel-agent/)**

## Features

- **Single Plugin Install** - One command installs everything
- **23 Specialized Agents** - Architecture, features, APIs, testing, security, deployment, performance, packages, and more
- **42 Commands** - Direct access to all capabilities
- **13 Auto-Invoked Skills** - Claude automatically applies Laravel expertise based on context
- **Pre-configured Hooks** - Laravel linting and auto-formatting on file changes
- **MCP Extension** - Complements Laravel Boost with testing, queue, and performance tools
- **SOLID/DRY Enforcement** - Every generated code follows best practices
- **Pattern Limit** - Max 5 design patterns per project to prevent complexity
- **Multi-Tenancy Support** - Optional tenant isolation (opt-in, not forced)
- **85+ Package Integrations** - Detects and adapts to installed packages

## Installation

```bash
# Add the marketplace
/plugin marketplace add hadyfayed/laravel-agent

# Install the plugin
/plugin install laravel-agent@hadyfayed-laravel-agent
```

That's it! All 29 agents, 47 commands, and 21 skills are now available.

## Available Commands

### Core
| Command | Description |
|---------|-------------|
| `/laravel-agent:build` | Intelligent build - architect analyzes and delegates |
| `/laravel-agent:patterns` | View current pattern usage (max 5) |

### Builders
| Command | Description |
|---------|-------------|
| `/laravel-agent:feature:make` | Create complete feature (CRUD, views, API, tests) |
| `/laravel-agent:module:make` | Create reusable domain module |
| `/laravel-agent:service:make` | Create service or action |
| `/laravel-agent:scaffold:app` | Full app scaffolding from natural language description |

### API
| Command | Description |
|---------|-------------|
| `/laravel-agent:api:make` | Create versioned API resource |
| `/laravel-agent:api:docs` | Generate OpenAPI documentation |

### Testing
| Command | Description |
|---------|-------------|
| `/laravel-agent:test:make` | Generate Pest tests |
| `/laravel-agent:test:coverage` | Run coverage analysis |

### Database
| Command | Description |
|---------|-------------|
| `/laravel-agent:db:optimize` | Optimize queries and indexes |
| `/laravel-agent:db:diagram` | Generate ER diagram |

### Frontend
| Command | Description |
|---------|-------------|
| `/laravel-agent:livewire:make` | Create Livewire 3 component |
| `/laravel-agent:filament:make` | Create Filament resource |

### Auth & Security
| Command | Description |
|---------|-------------|
| `/laravel-agent:auth:setup` | Setup authentication |
| `/laravel-agent:security:audit` | Run OWASP security audit |

### Async & Notifications
| Command | Description |
|---------|-------------|
| `/laravel-agent:job:make` | Create queued job |
| `/laravel-agent:broadcast:make` | Create broadcast event |
| `/laravel-agent:notification:make` | Create multi-channel notification (55+ channels) or setup channel |

### AI & Content
| Command | Description |
|---------|-------------|
| `/laravel-agent:ai:make` | Create AI-powered feature (Prism PHP) |
| `/laravel-agent:bug:fix` | AI-assisted bug fixing |
| `/laravel-agent:docs:generate` | Generate documentation |
| `/laravel-agent:pdf:make` | Generate PDF templates (invoices, reports) |
| `/laravel-agent:seo:setup` | Setup SEO infrastructure (sitemaps, meta tags, Open Graph) |
| `/laravel-agent:geo:make` | Create geolocation features |

### DevOps & Infrastructure
| Command | Description |
|---------|-------------|
| `/laravel-agent:deploy:setup` | Setup deployment (Forge, Vapor, Docker) |
| `/laravel-agent:cicd:setup` | Setup CI/CD pipeline |
| `/laravel-agent:reverb:setup` | Setup Laravel Reverb WebSockets |
| `/laravel-agent:feature-flag:make` | Create feature flag (Pennant) |
| `/laravel-agent:migrate:from-legacy` | Migrate from legacy codebase |
| `/laravel-agent:backup:setup` | Configure automated backups (spatie/laravel-backup) |
| `/laravel-agent:health:setup` | Setup health monitoring (spatie/laravel-health) |
| `/laravel-agent:search:setup` | Configure Scout + Meilisearch/Algolia/Typesense |
| `/laravel-agent:telescope:setup` | Setup Laravel Telescope for debugging |
| `/laravel-agent:pulse:setup` | Setup Laravel Pulse for production monitoring |

### Data & Integration
| Command | Description |
|---------|-------------|
| `/laravel-agent:dto:make` | Create Data Transfer Objects (spatie/laravel-data) |
| `/laravel-agent:webhook:make` | Create webhook handlers (Stripe, GitHub, etc.) |
| `/laravel-agent:import:make` | Create CSV/Excel importers |
| `/laravel-agent:upgrade:laravel` | Automated Laravel version upgrades |

### Code Review & Git
| Command | Description |
|---------|-------------|
| `/laravel-agent:review:staged` | Review staged changes |
| `/laravel-agent:review:pr` | Review pull request |
| `/laravel-agent:review:audit` | Full code audit |
| `/laravel-agent:analyze:codebase` | Full codebase health report |
| `/laravel-agent:refactor` | Refactor code for SOLID/DRY |
| `/laravel-agent:git:commit` | Create conventional commit |
| `/laravel-agent:git:pr` | Create pull request |
| `/laravel-agent:git:release` | Create release |

## Usage Examples

### Intelligent Build (Recommended)

Let the architect decide the best approach:

```bash
/laravel-agent:build invoice management system with PDF export
```

The architect will:
1. Analyze the request
2. Scan your codebase for existing patterns
3. Decide implementation type (Feature/Module/Service/Action)
4. Delegate to appropriate builder
5. Generate tests and verify

### Direct Commands

```bash
# Create a complete feature
/laravel-agent:feature:make Products with categories and variants

# Create API with versioning
/laravel-agent:api:make Products v2

# Generate tests
/laravel-agent:test:make OrderService

# Create Livewire component
/laravel-agent:livewire:make ProductsTable

# Create Filament admin resource
/laravel-agent:filament:make Products

# Security audit
/laravel-agent:security:audit

# Setup deployment
/laravel-agent:deploy:setup vapor

# Review staged changes
/laravel-agent:review:staged
```

## Agents

| Agent | Purpose |
|-------|---------|
| `laravel-architect` | Decision maker - analyzes requests, delegates to builders |
| `laravel-feature-builder` | Builds complete features with CRUD, views, API |
| `laravel-module-builder` | Builds reusable domain modules |
| `laravel-service-builder` | Builds services and actions |
| `laravel-refactor` | Code improvement and refactoring |
| `laravel-api-builder` | REST APIs with versioning, OpenAPI |
| `laravel-testing` | Pest tests - unit, feature, API, browser |
| `laravel-database` | Migrations, optimization, relationships |
| `laravel-auth` | Authentication, authorization, policies |
| `laravel-livewire` | Livewire 3 reactive components |
| `laravel-filament` | Filament admin panels |
| `laravel-queue` | Jobs, events, notifications |
| `laravel-ai` | AI features with Prism PHP |
| `laravel-deploy` | Forge, Vapor, Docker, Bref deployment |
| `laravel-cicd` | GitHub Actions, GitLab CI pipelines |
| `laravel-security` | OWASP audits, security headers, false positive filtering |
| `laravel-reverb` | WebSockets with Laravel Reverb |
| `laravel-pennant` | Feature flags and A/B testing |
| `laravel-migration` | Laravel/PHP version upgrades |
| `laravel-review` | Code review orchestrator |
| `laravel-git` | Git workflow automation |
| `laravel-package` | Laravel package development |
| `laravel-performance` | Performance optimization specialist |
| `laravel-scout` | Full-text search with Scout |
| `laravel-cashier` | Subscription billing with Stripe/Paddle |
| `laravel-passport` | Full OAuth2 server implementation |
| `laravel-octane` | High-performance with Swoole/RoadRunner |
| `laravel-nova` | Laravel Nova admin panels |
| `laravel-inertia` | Inertia.js SPAs with Vue/React |

## Skills (Auto-Invoked)

Skills are automatically activated based on context - no commands needed.

| Skill | Triggers | Purpose |
|-------|----------|---------|
| `laravel-feature` | "build feature", "create feature" | Complete feature development |
| `laravel-api` | "build api", "create endpoint" | REST API development |
| `laravel-database` | "migration", "query", "N+1" | Database operations & optimization |
| `laravel-testing` | "test", "pest", "coverage" | Writing Pest tests |
| `laravel-auth` | "auth", "permission", "role" | Authentication & authorization |
| `laravel-livewire` | "livewire", "reactive", "component" | Livewire 3 components |
| `laravel-inertia` | "inertia", "vue spa", "react spa" | Inertia.js SPAs with Vue/React |
| `laravel-filament` | "filament", "admin panel" | Admin panel development |
| `laravel-nova` | "nova", "nova resource", "admin dashboard" | Laravel Nova admin panels |
| `laravel-performance` | "slow", "optimize", "cache" | Performance optimization |
| `laravel-security` | "security", "vulnerability", "XSS" | Security audits & fixes |
| `laravel-deploy` | "deploy", "production", "server" | Deployment & hosting |
| `laravel-queue` | "queue", "job", "notification" | Background jobs & notifications |
| `laravel-websocket` | "websocket", "real-time", "Reverb" | Real-time features |
| `laravel-horizon` | "horizon", "queue dashboard", "failed jobs" | Redis queue monitoring |
| `laravel-sanctum` | "sanctum", "api token", "spa auth" | API token & SPA authentication |
| `laravel-socialite` | "socialite", "oauth", "social login" | OAuth social authentication |
| `laravel-passport` | "passport", "oauth2 server" | Full OAuth2 server |
| `laravel-scout` | "scout", "search", "algolia", "meilisearch" | Full-text search |
| `laravel-cashier` | "cashier", "stripe", "subscription" | Subscription billing |
| `laravel-octane` | "octane", "swoole", "roadrunner" | High-performance servers |

## Architecture Decision Matrix

| Request Type | Implementation | Location |
|--------------|----------------|----------|
| CRUD + UI + API | Feature | `app/Features/<Name>/` |
| Reusable logic, no UI | Module | `app/Modules/<Name>/` |
| Orchestrates operations | Service | `app/Services/` |
| Single operation | Action | `app/Actions/<Domain>/` |

## Package Integrations

The agents detect and adapt to 70+ packages including:

- **Architecture**: nwidart/laravel-modules, lorisleiva/laravel-actions
- **AI/LLM**: prism-php/prism, laravel/mcp
- **API**: nuwave/lighthouse, laravel/passport, laravel/sanctum, spatie/laravel-fractal
- **Auth**: spatie/laravel-permission, santigarcor/laratrust
- **Billing**: laravel/cashier
- **Admin**: filament/filament, bezhansalleh/filament-shield
- **Testing**: pestphp/pest, laravel/dusk
- **Database**: spatie/laravel-medialibrary, spatie/laravel-activitylog, venturecraft/revisionable
- **Performance**: laravel/octane, laravel/horizon, beyondcode/laravel-query-detector
- **WebSockets**: laravel/reverb
- **Feature Flags**: laravel/pennant
- **Multi-Tenancy**: stancl/tenancy
- **Deployment**: bref/laravel-bridge, laravel/vapor-core, laravel/envoy
- **Notifications**: 55+ channels via laravel-notification-channels (Telegram, Discord, Twilio, etc.)
- **PDF**: spatie/laravel-pdf, barryvdh/laravel-dompdf
- **SEO**: spatie/laravel-sitemap, artesaos/seotools, ralphjsmit/laravel-seo
- **Settings**: spatie/laravel-settings
- **DTOs**: spatie/laravel-data
- **Search**: laravel/scout, meilisearch/meilisearch-php
- **Geolocation**: spatie/geocoder
- **Backups**: spatie/laravel-backup
- **Health**: spatie/laravel-health
- **Import/Export**: maatwebsite/excel, spatie/simple-excel
- **Model Features**: spatie/eloquent-sortable, spatie/laravel-schemaless-attributes
- **Security**: spatie/crypto
- **Dev Tools**: grazulex/laravel-devtoolbox

## Hooks (7 Scripts)

Pre-configured hooks for Laravel code quality:

| Hook | Purpose |
|------|---------|
| `pre-commit.sh` | Comprehensive checks: syntax, Pint, PHPStan, security, Blade, migrations |
| `post-edit.sh` | Auto-format PHP, update IDE helper |
| `security-scan.sh` | Detect secrets, API keys, debug functions |
| `migration-safety.sh` | Warn about destructive operations |
| `blade-lint.sh` | Validate CSRF, XSS, directives |
| `test-runner.sh` | Run related tests on changes |
| `env-check.sh` | Block .env commits, validate examples |
| `scout-indexing.sh` | Validate Scout searchable models |
| `cashier-webhook.sh` | Validate Cashier/Stripe webhooks |

See `hooks/README.md` for installation instructions.

## MCP Extension

Complements [Laravel Boost](https://github.com/laravel/boost) with additional tools:

| Category | Tools |
|----------|-------|
| Testing | `test:run`, `test:coverage` |
| Queue | `queue:status`, `queue:failed` |
| Cache | `cache:status` |
| Performance | `perf:queries` |
| Migrations | `migrate:status` |
| Events | `event:list` |
| Schedule | `schedule:list` |
| Security | `security:deps` |

See `mcp/README.md` for details.

## Requirements

- Claude Code with Plugin support
- Laravel 10+ project

## Documentation

Visit the [documentation site](https://hadyfayed.github.io/laravel-agent/) for:

- Getting started guide
- Complete command reference
- Skills and hooks documentation
- Architecture overview
- Package integrations

## License

MIT

## Contributing

Contributions welcome! Please open an issue or pull request.

## Credits

Built for [Claude Code](https://claude.ai/code)
