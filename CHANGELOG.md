# Changelog

All notable changes to Laravel Agent will be documented in this file.

## [3.0.0] — 2026-06-24

Major restructure to the modern Claude Code **skill standard**. The previous mix of 30 agents, 53 colon-namespaced commands, and 21 skills (with heavy three-way duplication) is now a single, coherent `skills/` taxonomy of **65 skills** under a written three-kind contract, backed by **11 retained agents** and a generated single-source-of-truth catalog.

### Breaking changes

- **Commands removed.** All 53 `commands/*.md` are deleted; each is replaced by an equivalent **skill** invoked as `/laravel-agent:<skill>`. See the migration table below.
- **Agents consolidated 30 → 11.** Topic agents whose knowledge now lives in reference skills were removed; only the 11 forked-worker agents remain (`laravel-feature, laravel-module, laravel-service, laravel-api, laravel-filament, laravel-livewire, laravel-testing, laravel-review, laravel-security, laravel-architect, claude-plugin-builder`).
- **Auth family consolidated.** `laravel-sanctum`, `laravel-passport`, `laravel-socialite` skills folded into `laravel-auth`.

### Added

- **Three-kind skill contract** (`docs/architecture/skill-standard.md`): reference (auto-trigger knowledge), scaffolder (`context: fork` → retained agent), utility (`disable-model-invocation`). 15 reference + 11 scaffolder + 39 utility skills, each with `evals/evals.json`.
- **Catalog generator** (`scripts/build-catalog.mjs`, 8 unit tests) — owns all counts + generates `CATALOG.md`; `--check` + CI guard (`.github/workflows/catalog-check.yml`) make count drift impossible.
- Progressive disclosure throughout: large skills split into `references/`.

### Fixed

- Phantom `laravel-validator` agent reference (repointed to `laravel-security`).
- MCP `composer.json` autoload (dangling `tests/` mapping).
- Catalog generator docs-count targets were non-idempotent and silently froze; now re-matchable + regression-tested.
- Removed fictional `skills/SKILLS.md`; `plugin.json` trimmed to a minimal manifest (auto-discovery is the source of truth).

### Migration — command → skill

Invoke the new skill in place of the old command. Skills also auto-trigger when relevant (except utilities, which stay manual).

| Old command | New invocation |
| :-- | :-- |
| `/agent:make` | `/laravel-agent:agent-make` |
| `/ai:make` | `/laravel-agent:ai-make` |
| `/analyze:codebase` | `/laravel-agent:analyze-codebase` |
| `/api:docs` | `/laravel-agent:laravel-api` |
| `/api:make` | `/laravel-agent:laravel-api` |
| `/auth:setup` | `/laravel-agent:auth-setup` |
| `/backup:setup` | `/laravel-agent:backup-setup` |
| `/broadcast:make` | `/laravel-agent:broadcast-make` |
| `/bug:fix` | `/laravel-agent:bug-fix` |
| `/build` | `/laravel-agent:laravel-build` |
| `/cicd:setup` | `/laravel-agent:cicd-setup` |
| `/command:make` | `/laravel-agent:command-make` |
| `/db:diagram` | `/laravel-agent:db-diagram` |
| `/db:optimize` | `/laravel-agent:db-optimize` |
| `/deploy:setup` | `/laravel-agent:deploy-setup` |
| `/docs:generate` | `/laravel-agent:docs-generate` |
| `/dto:make` | `/laravel-agent:dto-make` |
| `/feature-flag:make` | `/laravel-agent:feature-flag-make` |
| `/feature:make` | `/laravel-agent:laravel-feature` |
| `/filament:make` | `/laravel-agent:laravel-filament` |
| `/geo:make` | `/laravel-agent:geo-make` |
| `/git:commit` | `/laravel-agent:git-commit` |
| `/git:pr` | `/laravel-agent:git-pr` |
| `/git:release` | `/laravel-agent:git-release` |
| `/health:setup` | `/laravel-agent:health-setup` |
| `/import:make` | `/laravel-agent:import-make` |
| `/job:make` | `/laravel-agent:job-make` |
| `/livewire:make` | `/laravel-agent:laravel-livewire` |
| `/mcp:make` | `/laravel-agent:mcp-make` |
| `/migrate:from-legacy` | `/laravel-agent:migrate-from-legacy` |
| `/module:make` | `/laravel-agent:laravel-module` |
| `/notification:make` | `/laravel-agent:notification-make` |
| `/patterns` | `/laravel-agent:laravel-patterns` |
| `/pdf:make` | `/laravel-agent:pdf-make` |
| `/plugin:publish` | `/laravel-agent:plugin-publish` |
| `/plugin:scaffold` | `/laravel-agent:plugin-scaffold` |
| `/pulse:setup` | `/laravel-agent:pulse-setup` |
| `/refactor` | `/laravel-agent:laravel-refactor` |
| `/reverb:setup` | `/laravel-agent:reverb-setup` |
| `/review:audit` | `/laravel-agent:laravel-review` |
| `/review:pr` | `/laravel-agent:laravel-review` |
| `/review:staged` | `/laravel-agent:laravel-review` |
| `/scaffold:app` | `/laravel-agent:scaffold-app` |
| `/search:setup` | `/laravel-agent:search-setup` |
| `/security:audit` | `/laravel-agent:security-audit` |
| `/seo:setup` | `/laravel-agent:seo-setup` |
| `/service:make` | `/laravel-agent:laravel-service` |
| `/skill:make` | `/laravel-agent:skill-make` |
| `/telescope:setup` | `/laravel-agent:telescope-setup` |
| `/test:coverage` | `/laravel-agent:test-coverage` |
| `/test:make` | `/laravel-agent:test-make` |
| `/upgrade:laravel` | `/laravel-agent:upgrade-laravel` |
| `/webhook:make` | `/laravel-agent:webhook-make` |

### Deferred to follow-ups

- Docs site (Jekyll) regeneration against the new taxonomy.
- Cosmetic dedup/typo polish; adopting the official `skill-creator` eval schema. See `docs/superpowers/v3-cleanup-and-deferred.md`.

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
