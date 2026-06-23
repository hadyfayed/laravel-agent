# Changelog

All notable changes to Laravel Agent will be documented in this file.

## [3.0.0-dev] — unreleased

### Added

- **Catalog generator** (`scripts/build-catalog.mjs`) — single source of truth for skill/agent counts; `--write` regenerates `CATALOG.md`, `--check` exits non-zero on drift. Five unit tests (`scripts/build-catalog.test.mjs`) cover parse, classify, render, and apply-counts.
- **CI drift guard** (`.github/workflows/catalog-check.yml`) — fails the build if `CATALOG.md` is out of sync with the actual skill and agent files.
- **Skill standard doc** (`docs/architecture/skill-standard.md`) — written contract for the three skill kinds (reference, scaffolder, utility), required frontmatter per kind, naming conventions, progressive disclosure budget, dynamic context injection, retained-agent template, and eval schema.
- **Three pilot conversions** demonstrating the three kinds:
  - `skills/laravel-database` — reference pilot (93 lines, inline auto-trigger)
  - `skills/laravel-feature` — scaffolder pilot (100 lines, forks `agents/laravel-feature`)
  - `skills/git-commit` — utility pilot (83 lines, `disable-model-invocation: true`)

### Changed

- `plugin.json` trimmed to minimal manifest fields required by the Claude Code platform; verbose keys removed.
- Eval schema in skill-standard doc aligned with the `cases`/`expect` shape used by the pilots (was `evals`/`expected`); schema-compatibility note added pending skill-creator wiring.

### Fixed

- Phantom `laravel-validator` skill reference removed from `plugin.json` and all non-doc files.
- MCP `composer.json` autoload fixed to resolve class-not-found errors at bootstrap.

### Notes

Command→skill renames and the full migration table (remaining ~37 topics) land during the conversion waves, which begin after the human review checkpoint that follows this foundation release.

---

## [2.1.0] - 2026-04-02

### Added

#### Claude Code Plugin Development Tools
New meta-tools for creating and sharing Claude Code extensions:

- **claude-plugin-builder** agent - Creates Claude Code plugins, commands, agents, skills, and MCP tools
- **plugin:scaffold** command - Scaffold complete plugin structures with manifests
- **command:make** command - Create new slash commands with proper structure
- **agent:make** command - Create new specialized agents with workflow templates
- **skill:make** command - Create auto-invoked skills with progressive disclosure tiers
- **mcp:make** command - Create MCP tools (PHP or TypeScript)
- **plugin:publish** command - Publish plugins to marketplace or GitHub

#### New Capabilities
- Complete plugin scaffolding with `plugin.json` and `marketplace.json` generation
- Agent templates for Explorer, Builder, Orchestrator, and Reviewer types
- Skill creation with Tier 1 (metadata), Tier 2 (core), and Tier 3 (references) structure
- MCP tool generation for both PHP (PhpMcp) and TypeScript implementations
- Version management and CHANGELOG generation for publishing

### Changed
- Updated plugin.json version to 2.1.0
- Added keywords: claude-code, plugin, mcp, skills, agents
- Updated marketplace.json with new agent/command counts (23 agents, 38 commands)

---

## [1.2.0] - 2025-12-18

### Added

#### Big O Complexity Detection
- **Skills**: `laravel-database` and `laravel-performance` now detect O(n²) patterns
- **Agents**: `laravel-database`, `laravel-performance`, and `laravel-review` detect Big O issues
- **Commands**: `/db:optimize` now includes Big O analysis in optimization reports
- **Triggers**: "Big O", "O(n)", "complexity", "nested loop", "quadratic"
- **Patterns Detected**:
  - O(n²) nested loops → Use relationships or `groupBy()`
  - O(n²) `contains()` in loop → Use `flip()->has()`
  - O(n) in-loop queries → Use batch operations
  - O(n×m) `filter()` in loop → Use `groupBy()`

#### Documentation Improvements
- Bidirectional sync between commands and documentation (38 enriched docs)
- All 23 agent documentation pages now include guardrails
- All skill documentation pages enriched with Common Pitfalls sections
- Comprehensive code examples in all documentation

#### New Skills (3)
- **laravel-horizon** - Queue monitoring and management (triggers: "horizon", "queue dashboard", "failed jobs")
- **laravel-sanctum** - API token authentication (triggers: "sanctum", "api token", "spa auth")
- **laravel-socialite** - Social authentication (triggers: "socialite", "oauth", "social login")

#### Enhanced Hooks
- Real hook scripts in `hooks/scripts/` directory
- `pre-commit.sh` - Comprehensive pre-commit with syntax, Pint, PHPStan, security
- `post-edit.sh` - Auto-format PHP files, update IDE helper
- `security-scan.sh` - Detect secrets, API keys, passwords, debug functions
- `migration-safety.sh` - Warn about destructive operations
- `blade-lint.sh` - Validate CSRF, XSS prevention
- `test-runner.sh` - Run related tests on file changes
- `env-check.sh` - Validate .env files, block secret commits

### Changed
- All skills now include Big O complexity detection alongside N+1 detection
- Performance checklist includes Big O optimization guidance
- Review agent includes Big O in code quality checks with 90% confidence scoring

---

## [1.1.0] - 2025-12-16

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

#### Hooks (7 scripts)
- **pre-commit.sh** - Comprehensive pre-commit: syntax, Pint, PHPStan, security, Blade, migrations
- **post-edit.sh** - Auto-format PHP files, update IDE helper for models
- **security-scan.sh** - Detects secrets, API keys, passwords, debug functions
- **migration-safety.sh** - Warns about destructive operations, missing down()
- **blade-lint.sh** - Validates CSRF, XSS prevention, unclosed directives
- **test-runner.sh** - Runs related tests on file changes
- **env-check.sh** - Validates .env files, blocks secret commits
- **hooks.example.json** - Full Claude Code hooks configuration

#### Skill Improvements
- **laravel-feature** - Added complete code examples (Model, Controller, Request, Action, Test)
- **laravel-api** - Added QueryBuilder, rate limiting, error handling, API tests
- All skills now include "Common Pitfalls" section with anti-patterns

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
- **laravel-feature** - Added settings, SEO, revisions, sortable, schemaless attributes
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
- **laravel-security** now owns the validation pipeline and false-positive filtering capability
- **laravel-review** delegates false-positive filtering to laravel-security

### Removed
- **notification:setup** - Merged into notification:make with `--setup` flag
- **seo:sitemap** - Replaced by seo:setup
- Phantom agent removed; capability consolidated into laravel-security

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
