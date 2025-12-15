# Changelog

All notable changes to Laravel Agent will be documented in this file.

## [Unreleased]

### Added

#### Skills (12 Auto-Invoked)
- **laravel-feature** - Complete feature development (triggers: "build feature", "create feature")
- **laravel-api** - REST API development (triggers: "build api", "create endpoint")
- **laravel-database** - Database operations & optimization (triggers: "migration", "query", "N+1")
- **laravel-testing** - Writing Pest tests (triggers: "test", "pest", "coverage")
- **laravel-auth** - Authentication & authorization (triggers: "auth", "permission", "role")
- **laravel-livewire** - Livewire 3 components (triggers: "livewire", "reactive", "component")
- **laravel-filament** - Admin panel development (triggers: "filament", "admin panel")
- **laravel-performance** - Performance optimization (triggers: "slow", "optimize", "cache")
- **laravel-security** - Security audits & fixes (triggers: "security", "vulnerability", "XSS", "OWASP")
- **laravel-deploy** - Deployment & hosting (triggers: "deploy", "production", "server", "Forge", "Vapor")
- **laravel-queue** - Background jobs & notifications (triggers: "queue", "job", "notification", "async")
- **laravel-websocket** - Real-time features (triggers: "websocket", "real-time", "Reverb", "broadcast")

#### Hooks
- **pre-commit.sh** - PHP syntax checking, Laravel Pint formatting, PHPStan analysis
- **post-edit.sh** - Auto-format PHP files, update IDE helper for models
- **hooks.example.json** - Sample Claude Code hooks configuration

#### MCP Extension
- **laravel-agent/mcp-extension** - Complements Laravel Boost with additional tools
- Testing tools: `test:run`, `test:coverage`
- Queue tools: `queue:status`, `queue:failed`
- Cache tools: `cache:status`
- Performance tools: `perf:queries`
- Migration tools: `migrate:status`
- Event tools: `event:list`
- Schedule tools: `schedule:list`
- Security tools: `security:deps`

#### New Agents
- **laravel-migration** - Laravel/PHP version upgrade specialist (9→10→11→12, PHP 8.1→8.4)
- **laravel-package** - Laravel package development with Testbench, Packagist publishing
- **laravel-performance** - Performance optimization (Octane, caching, query optimization)

#### New Commands
- **notification:make** - Multi-channel notifications with 55+ channels (Telegram, Discord, Twilio, etc.)
- **pdf:make** - PDF generation with spatie/laravel-pdf or barryvdh/laravel-dompdf
- **seo:setup** - SEO infrastructure (sitemaps, meta tags, Open Graph, structured data)
- **geo:make** - Geolocation features with spatie/geocoder
- **backup:setup** - Automated backups with spatie/laravel-backup
- **health:setup** - Health monitoring with spatie/laravel-health
- **search:setup** - Full-text search with Scout + Meilisearch/Algolia/Typesense
- **dto:make** - Data Transfer Objects with spatie/laravel-data
- **webhook:make** - Webhook handlers for Stripe, GitHub, Paddle, etc.
- **import:make** - CSV/Excel importers with maatwebsite/excel

#### Package Integrations (85+ total)
- laravel-notification-channels (55+ channels)
- spatie/laravel-pdf, barryvdh/laravel-dompdf
- spatie/laravel-sitemap, artesaos/seotools, ralphjsmit/laravel-seo
- spatie/laravel-settings
- spatie/laravel-data
- spatie/laravel-backup
- spatie/laravel-health
- spatie/geocoder
- spatie/crypto
- maatwebsite/excel, spatie/simple-excel
- venturecraft/revisionable
- spatie/eloquent-sortable
- spatie/laravel-schemaless-attributes
- laravel/envoy
- grazulex/laravel-devtoolbox
- beyondcode/laravel-query-detector

#### Agent Enhancements
- **laravel-feature-builder** - Added settings, SEO, revisions, sortable, schemaless attributes
- **laravel-api-builder** - Added spatie/laravel-fractal for transformers
- **laravel-database** - Added N+1 detection with query-detector, devtoolbox commands
- **laravel-deploy** - Added laravel/envoy task runner
- **laravel-security** - Added spatie/crypto, devtoolbox scanning, validation pipeline
- **laravel-review** - Added devtoolbox integration for automated PR analysis
- **laravel-queue** - Added 55+ notification channels with examples
- **laravel-ai** - Added INPUT FORMAT and GUARDRAILS sections

#### Command Enhancements
- **bug:fix** - Added interactive prompts and structured output
- **docs:generate** - Added interactive prompts and output statistics
- All commands now have consistent structure with Interactive Prompts section

### Changed

#### Consolidated
- **notification:make** now handles both notification creation AND channel setup (merged notification:setup)
- **seo:setup** replaces seo:sitemap with expanded functionality (meta tags, Open Graph)
- **laravel-security** now includes validation pipeline from laravel-validator
- **laravel-review** uses laravel-security for false positive filtering

### Removed
- **notification:setup** - Merged into notification:make with `--setup` flag
- **seo:sitemap** - Replaced by seo:setup
- **laravel-validator** - Merged into laravel-security agent

### Fixed
- Consistent structure across all 42 commands
- Consistent template pattern across all 23 agents
- Updated README counts and agent descriptions

## [1.0.0] - Initial Release

### Added
- 20 specialized agents for Laravel development
- 32 commands covering full development lifecycle
- 70+ package integrations
- SOLID/DRY enforcement
- Pattern limit (max 5 per project)
- Multi-tenancy support (opt-in)
