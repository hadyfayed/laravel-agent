---
name: analyze-codebase
description: Generate a comprehensive codebase health report analyzing architecture, quality, security, performance, and dependencies; when auditing or understanding a Laravel project.
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Bash(grep *) Bash(find *) Read Grep Glob
argument-hint: "[target-path] [--focus=architecture|quality|security|performance|testing|dependencies|laravel]"
---

## Task

Analyze a Laravel codebase and generate a comprehensive health report covering architecture, code quality, security, performance, testing, and dependency management.

## Input

- **target-path** (optional): Directory to analyze (default: app/)
- **--focus**: Limit to one area (default: all)

## Steps

1. **Gather Metrics**
   ```bash
   find app/ -name "*.php" | wc -l
   find app/ -name "*.php" -exec wc -l {} + | tail -1
   find . -name "*.blade.php" | wc -l
   find . -name "*.vue" | wc -l
   find . -name "*.js" -o -name "*.ts" | wc -l
   ```

2. **Architecture Analysis**
   - Scan directory structure (standard Laravel, DDD, domain modules, etc.)
   - Check for pattern usage (Repository, Service, Action, Strategy, etc.)
   - Evaluate dependency coupling and isolation
   - Assess modularity and feature isolation
   - Review API design (RESTful compliance, versioning)

3. **Code Quality Metrics**
   - Average method and class line counts
   - Cyclomatic complexity estimates
   - Type hint coverage
   - PHPDoc/comment coverage
   - SOLID principles adherence
   - Code duplication (DRY violations)

4. **Security Scan**
   - Raw SQL queries with user input
   - Unescaped output (`{!! !!}` with user data)
   - Missing authorization checks
   - Mass assignment vulnerabilities (`$fillable` missing)
   - Hardcoded credentials or API keys
   - SQL injection patterns
   - File upload validation
   - Known package vulnerabilities (via `composer audit`)

5. **Performance Analysis**
   - N+1 query patterns (lazy loading in loops, missing eager loads)
   - Big O complexity issues (O(n²) nested loops, contains() in loops, in-loop queries)
   - Missing database indexes on foreign keys and common WHERE clauses
   - Unbounded SELECT queries
   - Caching opportunities
   - Memory-intensive operations
   
   See `${CLAUDE_SKILL_DIR}/references/performance-patterns.md` for detailed Big O detection patterns.

6. **Testing Assessment**
   ```bash
   php artisan test --coverage
   ```
   - Test file count and line coverage
   - Critical path coverage
   - Controllers, Services, Models coverage ratio
   - Test quality and assertion density

7. **Dependency Health**
   ```bash
   composer outdated
   composer audit
   ```
   - Update status (minor, major, deprecated)
   - Known vulnerabilities
   - Abandoned packages
   - License compatibility

8. **Laravel Best Practices**
   - Form request usage (FormRequest per route)
   - API Resource usage
   - Policy implementation
   - Event/Listener patterns
   - Job queueing for heavy operations
   - Caching strategy (config, routes, queries)
   - Eloquent ORM compliance (vs. raw queries)
   - Blade component reuse

## Output Format

Generate a markdown report with:

- **Executive Summary:** Overall health score (0–100), area scores, top 5 priorities
- **Detailed Findings:** Per-area tables with file locations, patterns, severity levels
- **Recommendations:** Immediate (this week), short-term (this month), long-term (this quarter)

See `references/` for example output format and detailed assessment checklists.
