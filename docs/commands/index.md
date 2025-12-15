# Command Reference

Laravel Agent provides 42 commands organized by category.

## Core Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:build` | Intelligent build - architect analyzes and delegates |
| `/laravel-agent:patterns` | View current pattern usage (max 5) |

## Builder Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:feature:make` | Create complete feature (CRUD, views, API, tests) |
| `/laravel-agent:module:make` | Create reusable domain module |
| `/laravel-agent:service:make` | Create service or action class |

## API Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:api:make` | Create versioned API resource |
| `/laravel-agent:api:docs` | Generate OpenAPI documentation |

## Testing Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:test:make` | Generate Pest tests |
| `/laravel-agent:test:coverage` | Run coverage analysis |

## Database Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:db:optimize` | Optimize queries and indexes |
| `/laravel-agent:db:diagram` | Generate ER diagram |

## Frontend Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:livewire:make` | Create Livewire 3 component |
| `/laravel-agent:filament:make` | Create Filament resource |

## Auth & Security Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:auth:setup` | Setup authentication |
| `/laravel-agent:security:audit` | Run OWASP security audit |

## Async & Notification Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:job:make` | Create queued job |
| `/laravel-agent:broadcast:make` | Create broadcast event |
| `/laravel-agent:notification:make` | Create multi-channel notification |

## AI & Content Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:ai:make` | Create AI-powered feature (Prism PHP) |
| `/laravel-agent:bug:fix` | AI-assisted bug fixing |
| `/laravel-agent:docs:generate` | Generate documentation |
| `/laravel-agent:pdf:make` | Generate PDF templates |
| `/laravel-agent:seo:setup` | Setup SEO infrastructure |
| `/laravel-agent:geo:make` | Create geolocation features |

## DevOps Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:deploy:setup` | Setup deployment (Forge, Vapor, Docker) |
| `/laravel-agent:cicd:setup` | Setup CI/CD pipeline |
| `/laravel-agent:reverb:setup` | Setup Laravel Reverb WebSockets |
| `/laravel-agent:feature-flag:make` | Create feature flag (Pennant) |
| `/laravel-agent:migrate:from-legacy` | Migrate from legacy codebase |
| `/laravel-agent:backup:setup` | Configure automated backups |
| `/laravel-agent:health:setup` | Setup health monitoring |
| `/laravel-agent:search:setup` | Configure Scout search |

## Data & Integration Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:dto:make` | Create Data Transfer Objects |
| `/laravel-agent:webhook:make` | Create webhook handlers |
| `/laravel-agent:import:make` | Create CSV/Excel importers |

## Code Review & Git Commands

| Command | Description |
|---------|-------------|
| `/laravel-agent:review:staged` | Review staged changes |
| `/laravel-agent:review:pr` | Review pull request |
| `/laravel-agent:review:audit` | Full code audit |
| `/laravel-agent:refactor` | Refactor code for SOLID/DRY |
| `/laravel-agent:git:commit` | Create conventional commit |
| `/laravel-agent:git:pr` | Create pull request |
| `/laravel-agent:git:release` | Create release |

## Command Usage

### Basic Usage

```bash
/laravel-agent:feature:make Products
```

### With Arguments

```bash
/laravel-agent:api:make Products v2
```

### With Description

```bash
/laravel-agent:build invoice management with PDF export and email notifications
```

## See Also

- [Build Commands](build.md)
- [API Commands](api.md)
- [Testing Commands](testing.md)
- [DevOps Commands](devops.md)
