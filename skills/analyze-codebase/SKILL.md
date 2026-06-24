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

Generate a report as markdown with:

- **Executive Summary:** Overall health score (0–100), area scores, top 5 priorities
- **Detailed Findings:** Per-area tables with file locations, patterns, severity levels
- **Recommendations:** Immediate (this week), short-term (this month), long-term (this quarter)

## Reference

For deep patterns and checklists:
- `${CLAUDE_SKILL_DIR}/references/performance-patterns.md` — Big O and N+1 detection
- `${CLAUDE_SKILL_DIR}/references/architecture-checklist.md` — SOLID and structure assessment
- `${CLAUDE_SKILL_DIR}/references/security-checklist.md` — OWASP and Laravel-specific vulnerabilities

## Example Output

```markdown
# Codebase Health Report

**Project:** Example App
**Generated:** 2026-06-24
**Laravel Version:** 11.x
**PHP Version:** 8.2

## Overall Health Score: 78/100

| Area          | Score  | Grade |
|---------------|--------|-------|
| Architecture  | 85/100 | A     |
| Code Quality  | 75/100 | B     |
| Security      | 80/100 | A-    |
| Performance   | 70/100 | B-    |
| Testing       | 72/100 | B     |
| Dependencies  | 85/100 | A     |
| Laravel       | 82/100 | A-    |

## Top Priorities

1. 🔴 **Critical:** Fix 3 security vulnerabilities in dependencies
2. 🟠 **High:** Resolve 12 N+1 query issues
3. 🟡 **Medium:** Add missing policies for 5 models
4. 🟡 **Medium:** Increase test coverage to 80%
5. 🔵 **Low:** Update 5 packages to major versions

## Security Findings

### High (2)
1. **Unescaped output** - `resources/views/users/show.blade.php:45`
   Fix: Use `{{ }}` or sanitize input

2. **Missing authorization** - `app/Http/Controllers/ReportController.php:32`
   Fix: Add `$this->authorize('view', $report)`

## Performance Findings

### N+1 Queries (12)
| File | Line | Relationship | Fix |
|------|------|--------------|-----|
| OrderController.php | 45 | items | Add `with('items')` |
| UserController.php | 23 | roles | Add `with('roles')` |

### Big O Issues (2)
| File | Line | Pattern | Complexity |
|------|------|---------|------------|
| ImportService.php | 42 | Nested loops | O(n²) |
| SyncService.php | 85 | contains() in loop | O(n²) |

## Recommendations

### Immediate (This Week)
1. Run `composer audit` and fix vulnerabilities
2. Add eager loading to resolve N+1 queries
3. Add missing form requests

### Short-term (This Month)
1. Increase test coverage to 80%
2. Add policies to all models
3. Implement caching strategy

### Long-term (This Quarter)
1. Consider domain-driven modules
2. Implement event-driven architecture
3. Add observability (Pulse/Horizon)
```
