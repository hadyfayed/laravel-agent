# Laravel Agent

[![Documentation](https://img.shields.io/badge/docs-hadyfayed.github.io-blue)](https://hadyfayed.github.io/laravel-agent/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-purple)](https://claude.ai/code)

> AI-powered Laravel development assistant - architecture decisions, code generation, testing, deployment, and more.

<!-- catalog:counts -->66 skills · 11 agents<!-- /catalog:counts -->

**[View Documentation](https://hadyfayed.github.io/laravel-agent/)**

> **v3.0.0 — skill-based.** The old colon commands (`/feature:make`) are now **skills** invoked as `/laravel-agent:<skill>` (e.g. `/laravel-agent:laravel-feature`). New to the tool? Run **`/laravel-agent:interactive`** for a guided "what do you want to build?" walkthrough. See [CHANGELOG.md](CHANGELOG.md) for the full command→skill migration table, [CONTRIBUTING.md](CONTRIBUTING.md) for the skill architecture, and [CUSTOMIZATION.md](CUSTOMIZATION.md) to adapt it to your project.

## Features

- **Single Plugin Install** - One command installs everything
- **Pre-configured Hooks** - Laravel linting and auto-formatting on file changes
- **MCP Extension** - (experimental) Proposed Artisan-backed tools; see `mcp/README`
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

## Available Skills

### Architecture & Builders (11 scaffolder)
- **`/laravel-agent:build`** — Intelligent build: architect analyzes requests and delegates to appropriate builder
- **`/laravel-agent:laravel-feature`** — Scaffold a complete feature (controllers, requests, models, migrations, tests)
- **`/laravel-agent:laravel-module`** — Scaffold a reusable domain module
- **`/laravel-agent:laravel-service`** — Scaffold a service or action class
- **`/laravel-agent:scaffold-app`** — Full app scaffolding from natural language description
- **`/laravel-agent:laravel-api`** — Scaffold a REST/JSON API with versioning
- **`/laravel-agent:laravel-review`** — Review code, PRs, staged changes for quality/security
- **`/laravel-agent:laravel-refactor`** — Refactor code for SOLID/DRY compliance
- **`/laravel-agent:plugin-scaffold`** — Scaffold Claude Code plugin artifacts
- **`/laravel-agent:security-audit`** — OWASP security audit with confidence scoring
- **`/laravel-agent:test-make`** — Generate Pest/PHPUnit tests (unit, feature, API, Dusk)

### Testing & Quality
- **`/laravel-agent:test-coverage`** — Run test coverage and identify gaps
- **`/laravel-agent:laravel-testing`** — Test patterns, assertions, TDD guidance

### Database
- **`/laravel-agent:db-optimize`** — Optimize queries, detect N+1 and Big O issues, suggest indexes
- **`/laravel-agent:db-diagram`** — Generate ER diagram (Mermaid, DBML, PlantUML)
- **`/laravel-agent:laravel-database`** — Database conventions, migrations, relationships, optimization

### Frontend & UI
- **`/laravel-agent:laravel-livewire`** — Build Livewire 3 components and reactive forms
- **`/laravel-agent:laravel-filament`** — Build Filament v3/v4 admin panels with RBAC
- **`/laravel-agent:laravel-inertia`** — Build Inertia.js SPAs with Vue 3 or React

### API & Integration
- **`/laravel-agent:api-docs`** — Generate OpenAPI documentation
- **`/laravel-agent:laravel-passport`** — Full OAuth2 server implementation
- **`/laravel-agent:laravel-sanctum`** — API token and SPA authentication
- **`/laravel-agent:webhook-make`** — Scaffold webhook infrastructure with signature verification

### Authentication & Authorization
- **`/laravel-agent:auth-setup`** — Set up authentication (Sanctum/Fortify/Breeze)
- **`/laravel-agent:laravel-auth`** — Auth patterns, guards, policies, roles & permissions

### Background Jobs & Async
- **`/laravel-agent:job-make`** — Create queued jobs with retries/backoff
- **`/laravel-agent:broadcast-make`** — Create broadcast events and channels
- **`/laravel-agent:notification-make`** — Multi-channel notifications (mail, SMS, Telegram, Discord, Slack, etc.)
- **`/laravel-agent:laravel-queue`** — Job batching, chains, event listeners, Horizon integration

### Real-Time & WebSockets
- **`/laravel-agent:reverb-setup`** — Configure Laravel Reverb WebSocket server
- **`/laravel-agent:laravel-websocket`** — WebSocket patterns, broadcasting, scaling

### Monitoring & Observability
- **`/laravel-agent:telescope-setup`** — Install Telescope for debugging and request inspection
- **`/laravel-agent:pulse-setup`** — Configure Laravel Pulse for production monitoring
- **`/laravel-agent:health-setup`** — Configure application health checks and monitoring

### Search & Performance
- **`/laravel-agent:search-setup`** — Set up Scout with Algolia/Meilisearch/Typesense
- **`/laravel-agent:laravel-scout`** — Full-text search patterns and optimization
- **`/laravel-agent:laravel-performance`** — Performance optimization (caching, N+1 fixes, scaling)
- **`/laravel-agent:laravel-octane`** — High-performance servers (Swoole, RoadRunner, FrankenPHP)
- **`/laravel-agent:laravel-horizon`** — Redis queue dashboard and auto-scaling

### AI & Content Generation
- **`/laravel-agent:ai-make`** — Create AI features with Prism PHP (chat, embeddings, tool-calling)
- **`/laravel-agent:bug-fix`** — Systematically diagnose and fix bugs
- **`/laravel-agent:docs-generate`** — Generate project documentation
- **`/laravel-agent:pdf-make`** — Generate PDF documents (invoices, reports, certificates)
- **`/laravel-agent:seo-setup`** — Configure SEO infrastructure (sitemaps, meta tags, schema)
- **`/laravel-agent:geo-make`** — Create geolocation features with distance queries

### Data & Imports
- **`/laravel-agent:dto-make`** — Create Data Transfer Objects (spatie/laravel-data)
- **`/laravel-agent:import-make`** — Create CSV/Excel importers with validation
- **`/laravel-agent:analyze-codebase`** — Comprehensive codebase health report

### Deployment & DevOps
- **`/laravel-agent:deploy-setup`** — Configure deployment (Forge/Vapor/Docker)
- **`/laravel-agent:cicd-setup`** — Set up CI/CD pipelines (GitHub Actions/GitLab/Bitbucket)
- **`/laravel-agent:laravel-deploy`** — Deployment patterns, zero-downtime releases

### Billing & Subscriptions
- **`/laravel-agent:laravel-cashier`** — Stripe/Paddle subscriptions, invoices, webhooks

### Features & Patterns
- **`/laravel-agent:feature-flag-make`** — Create feature flags (Pennant)
- **`/laravel-agent:laravel-patterns`** — Design patterns (Action, Service, Repository, DTO, Strategy)

### Utilities & Framework
- **`/laravel-agent:backup-setup`** — Configure automated backups (spatie/laravel-backup)
- **`/laravel-agent:migrate-from-legacy`** — Migrate legacy apps/databases into Laravel
- **`/laravel-agent:upgrade-laravel`** — Upgrade Laravel/PHP versions with breaking changes
- **`/laravel-agent:laravel-build`** — Run full build pipeline (Pint, PHPStan, tests, assets)
- **`/laravel-agent:command-make`** — Create custom Artisan commands
- **`/laravel-agent:mcp-make`** — Scaffold MCP tools/servers
- **`/laravel-agent:skill-make`** — Create new skills
- **`/laravel-agent:agent-make`** — Create new agents
- **`/laravel-agent:git-commit`** — Create conventional commits
- **`/laravel-agent:git-pr`** — Create pull requests
- **`/laravel-agent:git-release`** — Cut releases with version bumps and tags
- **`/laravel-agent:interactive`** — Guided mode to pick the right skill for your task
- **`/laravel-agent:package-make`** — Scaffold reusable Laravel packages
- **`/laravel-agent:plugin-publish`** — Publish plugins to marketplace
- **`/laravel-agent:laravel-socialite`** — OAuth social authentication

### Security & Best Practices
- **`/laravel-agent:laravel-security`** — OWASP best practices, XSS/CSRF/injection prevention
- **`/laravel-agent:laravel-nova`** — Laravel Nova admin panels
- **`/laravel-agent:laravel-health`** — Health check patterns and monitoring

**New to laravel-agent?** Start with `/laravel-agent:interactive` for a guided walkthrough of what you want to build.

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
| `laravel-feature` | Builds complete features with CRUD, views, API |
| `laravel-module` | Builds reusable domain modules |
| `laravel-service` | Builds services and actions |
| `laravel-refactor` | Code improvement and refactoring |
| `laravel-api` | REST APIs with versioning, OpenAPI |
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
