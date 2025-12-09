# Laravel Agent

> AI-powered Laravel development assistant - architecture decisions, code generation, testing, deployment, and more.

A Claude Code plugin with **22 specialized agents** and **32 commands** covering the entire Laravel development lifecycle.

## Features

- **Single Plugin Install** - One command installs everything
- **22 Specialized Agents** - Architecture, features, APIs, testing, security, deployment, and more
- **32 Commands** - Direct access to all capabilities
- **SOLID/DRY Enforcement** - Every generated code follows best practices
- **Pattern Limit** - Max 5 design patterns per project to prevent complexity
- **Multi-Tenancy Support** - Optional tenant isolation (opt-in, not forced)
- **50+ Package Integrations** - Detects and adapts to installed packages

## Installation

```bash
# Add the marketplace
/plugin marketplace add hadyfayed/laravel-agent

# Install the plugin
/plugin install laravel-agent@hadyfayed-laravel-agent
```

That's it! All 22 agents and 32 commands are now available.

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

### Async
| Command | Description |
|---------|-------------|
| `/laravel-agent:job:make` | Create queued job |
| `/laravel-agent:broadcast:make` | Create broadcast event |

### AI
| Command | Description |
|---------|-------------|
| `/laravel-agent:ai:make` | Create AI-powered feature (Prism PHP) |
| `/laravel-agent:bug:fix` | AI-assisted bug fixing |
| `/laravel-agent:docs:generate` | Generate documentation |

### DevOps
| Command | Description |
|---------|-------------|
| `/laravel-agent:deploy:setup` | Setup deployment (Forge, Vapor, Docker) |
| `/laravel-agent:cicd:setup` | Setup CI/CD pipeline |
| `/laravel-agent:reverb:setup` | Setup Laravel Reverb WebSockets |
| `/laravel-agent:feature-flag:make` | Create feature flag (Pennant) |
| `/laravel-agent:migrate:from-legacy` | Migrate from legacy codebase |

### Code Review & Git
| Command | Description |
|---------|-------------|
| `/laravel-agent:review:staged` | Review staged changes |
| `/laravel-agent:review:pr` | Review pull request |
| `/laravel-agent:review:audit` | Full code audit |
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
| `laravel-security` | OWASP audits, security headers |
| `laravel-reverb` | WebSockets with Laravel Reverb |
| `laravel-pennant` | Feature flags and A/B testing |
| `laravel-migration` | Laravel/PHP version upgrades |
| `laravel-review` | Code review orchestrator |
| `laravel-validator` | Review validation and false positive filtering |
| `laravel-git` | Git workflow automation |

## Architecture Decision Matrix

| Request Type | Implementation | Location |
|--------------|----------------|----------|
| CRUD + UI + API | Feature | `app/Features/<Name>/` |
| Reusable logic, no UI | Module | `app/Modules/<Name>/` |
| Orchestrates operations | Service | `app/Services/` |
| Single operation | Action | `app/Actions/<Domain>/` |

## Package Integrations

The agents detect and adapt to 50+ packages including:

- **Architecture**: nwidart/laravel-modules, lorisleiva/laravel-actions
- **AI/LLM**: prism-php/prism, laravel/mcp
- **API**: nuwave/lighthouse, laravel/passport, laravel/sanctum
- **Auth**: spatie/laravel-permission, santigarcor/laratrust
- **Billing**: laravel/cashier
- **Admin**: filament/filament, bezhansalleh/filament-shield
- **Testing**: pestphp/pest, laravel/dusk
- **Database**: spatie/laravel-medialibrary, spatie/laravel-activitylog
- **Performance**: laravel/octane, laravel/horizon
- **WebSockets**: laravel/reverb
- **Feature Flags**: laravel/pennant
- **Multi-Tenancy**: stancl/tenancy
- **Deployment**: bref/laravel-bridge, laravel/vapor-core

## Requirements

- Claude Code with Plugin support
- Laravel 10+ project

## License

MIT

## Contributing

Contributions welcome! Please open an issue or pull request.

## Credits

Built for [Claude Code](https://claude.ai/code)
