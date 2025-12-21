---
description: "Full codebase health report"
allowed-tools: Task, Read, Glob, Grep, Bash
---

# /analyze:codebase - Full Codebase Health Report

Generate a comprehensive health report analyzing code quality, architecture, security, performance, and maintainability of your Laravel codebase.

## Usage

```bash
/laravel-agent:analyze:codebase [path] [--focus=area]
```

## Input
$ARGUMENTS = `[target-path] [--focus=area] [--output=format]`

Examples:
- `/analyze:codebase` - Full codebase analysis
- `/analyze:codebase app/` - Analyze app directory only
- `/analyze:codebase --focus=architecture` - Architecture-focused analysis
- `/analyze:codebase --output=json` - JSON output for CI integration

## Analysis Areas

| Area | Description |
|------|-------------|
| `all` | Complete analysis (default) |
| `architecture` | Project structure, patterns, dependencies |
| `quality` | Code quality, SOLID, DRY, complexity |
| `security` | OWASP vulnerabilities, auth, encryption |
| `performance` | N+1, caching, indexing, queries |
| `testing` | Coverage, quality, missing tests |
| `dependencies` | Package health, updates, conflicts |
| `laravel` | Laravel best practices compliance |

## Process

### 1. Gather Metrics

```bash
# Count lines of code
find app/ -name "*.php" -exec wc -l {} + | tail -1

# Count files by type
find . -name "*.php" | wc -l
find . -name "*.blade.php" | wc -l
find . -name "*.vue" | wc -l
find . -name "*.js" -o -name "*.ts" | wc -l

# Check test coverage
php artisan test --coverage
```

### 2. Architecture Analysis

```
┌─────────────────────────────────────────────────────────────┐
│                   ARCHITECTURE ANALYSIS                      │
├──────────────────┬──────────────────────────────────────────┤
│ Component        │ Assessment                                │
├──────────────────┼──────────────────────────────────────────┤
│ Structure        │ Standard Laravel / Domain-Driven / Custom │
│ Patterns Used    │ Repository, Service, Action, etc.        │
│ Dependencies     │ Coupling analysis between layers          │
│ Modularity       │ Feature isolation score                   │
│ API Design       │ RESTful compliance, versioning            │
└──────────────────┴──────────────────────────────────────────┘
```

**Check for:**
- Clear separation of concerns
- Consistent naming conventions
- Proper use of Laravel features
- Dependency injection usage
- Event-driven patterns

### 3. Code Quality Metrics

```
┌─────────────────────────────────────────────────────────────┐
│                   QUALITY METRICS                            │
├──────────────────┬──────────────┬────────────┬──────────────┤
│ Metric           │ Value        │ Threshold  │ Status       │
├──────────────────┼──────────────┼────────────┼──────────────┤
│ Avg Method Lines │ 15           │ ≤ 20       │ ✅ PASS      │
│ Avg Class Lines  │ 180          │ ≤ 200      │ ✅ PASS      │
│ Cyclomatic Avg   │ 8            │ ≤ 10       │ ✅ PASS      │
│ Max Dependencies │ 7            │ ≤ 5        │ ⚠️ WARNING   │
│ DRY Violations   │ 3            │ 0          │ ❌ FAIL      │
│ SOLID Score      │ 78%          │ ≥ 80%      │ ⚠️ WARNING   │
└──────────────────┴──────────────┴────────────┴──────────────┘
```

**Analyze:**
- Method and class sizes
- Cyclomatic complexity
- Code duplication
- SOLID principles adherence
- Type hint coverage
- PHPDoc coverage

### 4. Security Scan

```
┌─────────────────────────────────────────────────────────────┐
│                   SECURITY SCAN                              │
├──────────────────┬───────────────────────────────────────────┤
│ Category         │ Findings                                  │
├──────────────────┼───────────────────────────────────────────┤
│ SQL Injection    │ 0 raw queries with user input            │
│ XSS              │ 2 unescaped outputs found                │
│ CSRF             │ Protected (middleware active)            │
│ Mass Assignment  │ 1 model missing $fillable                │
│ Auth Bypass      │ 0 public routes to protected resources   │
│ Secrets Exposure │ 0 hardcoded credentials                  │
│ File Upload      │ 1 missing validation                     │
│ Dependencies     │ 3 packages with known vulnerabilities    │
└──────────────────┴───────────────────────────────────────────┘
```

**Check for:**
- OWASP Top 10 vulnerabilities
- Unsafe query patterns
- Missing authorization
- Exposed sensitive data
- Insecure configurations

### 5. Performance Analysis

```
┌─────────────────────────────────────────────────────────────┐
│                   PERFORMANCE ANALYSIS                       │
├──────────────────┬───────────────────────────────────────────┤
│ Issue Type       │ Occurrences                               │
├──────────────────┼───────────────────────────────────────────┤
│ N+1 Queries      │ 12 potential (eager loading missing)     │
│ Missing Indexes  │ 5 foreign keys without index             │
│ Large Queries    │ 3 unbounded selects                      │
│ Cache Misses     │ 8 repeated expensive operations          │
│ Big O Issues     │ 2 nested loops detected                  │
│ Memory Leaks     │ 1 large collection in memory             │
└──────────────────┴───────────────────────────────────────────┘
```

**Analyze:**
- N+1 query patterns
- Missing database indexes
- Unbounded queries
- Missing caching opportunities
- Big O complexity issues
- Memory-intensive operations

### 6. Testing Assessment

```
┌─────────────────────────────────────────────────────────────┐
│                   TESTING ASSESSMENT                         │
├──────────────────┬───────────────────────────────────────────┤
│ Metric           │ Value                                     │
├──────────────────┼───────────────────────────────────────────┤
│ Total Tests      │ 156                                       │
│ Line Coverage    │ 72%                                       │
│ Branch Coverage  │ 65%                                       │
│ Critical Paths   │ 85% covered                               │
│ Controllers      │ 15/20 tested (75%)                        │
│ Services         │ 8/12 tested (67%)                         │
│ Models           │ 18/18 tested (100%)                       │
└──────────────────┴───────────────────────────────────────────┘
```

**Evaluate:**
- Test coverage by directory
- Critical path coverage
- Test quality (assertions per test)
- Missing test cases
- Flaky tests

### 7. Dependency Health

```
┌─────────────────────────────────────────────────────────────┐
│                   DEPENDENCY HEALTH                          │
├──────────────────┬───────────────────────────────────────────┤
│ Status           │ Count                                     │
├──────────────────┼───────────────────────────────────────────┤
│ Up to date       │ 45                                        │
│ Minor updates    │ 12                                        │
│ Major updates    │ 5                                         │
│ Deprecated       │ 2                                         │
│ Vulnerabilities  │ 3                                         │
│ Abandoned        │ 1                                         │
└──────────────────┴───────────────────────────────────────────┘
```

**Check:**
- `composer outdated`
- `npm outdated`
- Known vulnerabilities
- Abandoned packages
- License compliance

### 8. Laravel Best Practices

```
┌─────────────────────────────────────────────────────────────┐
│                   LARAVEL COMPLIANCE                         │
├──────────────────┬──────────────┬────────────────────────────┤
│ Practice         │ Status       │ Notes                      │
├──────────────────┼──────────────┼────────────────────────────┤
│ Form Requests    │ ✅ 95%       │ 2 controllers missing      │
│ API Resources    │ ✅ 100%      │ All APIs use resources     │
│ Policies         │ ⚠️ 75%      │ 5 models missing policies  │
│ Events/Listeners │ ✅ Used      │ 12 events defined          │
│ Queued Jobs      │ ✅ Used      │ Heavy tasks are queued     │
│ Caching          │ ⚠️ Partial  │ Config/routes not cached   │
│ Eloquent ORM     │ ✅ 98%       │ 1 raw query found          │
│ Blade Components │ ✅ Used      │ Reusable components exist  │
└──────────────────┴──────────────┴────────────────────────────┘
```

## Report Output

### Executive Summary

```markdown
# Codebase Health Report

**Project:** [Project Name]
**Generated:** [Timestamp]
**Laravel Version:** [Version]
**PHP Version:** [Version]

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
```

### Detailed Findings

```markdown
## Security Findings

### Critical (0)
No critical issues.

### High (2)
1. **Unescaped output** - `resources/views/users/show.blade.php:45`
   - Issue: Using `{!! !!}` with user data
   - Fix: Use `{{ }}` or sanitize input

2. **Missing authorization** - `app/Http/Controllers/ReportController.php:32`
   - Issue: No policy check before showing report
   - Fix: Add `$this->authorize('view', $report)`

### Medium (3)
...

## Performance Findings

### N+1 Queries (12)
| File | Line | Query | Fix |
|------|------|-------|-----|
| OrderController.php | 45 | orders.items | `with('items')` |
| UserController.php | 23 | users.roles | `with('roles')` |
...

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
1. Consider extracting to domain modules
2. Implement event-driven architecture
3. Add observability (Pulse/Horizon)
```

## Output Formats

```bash
# Markdown report (default)
/analyze:codebase > health-report.md

# JSON for CI/CD integration
/analyze:codebase --output=json > health-report.json

# HTML report
/analyze:codebase --output=html > health-report.html

# Score only (for CI gates)
/analyze:codebase --score-only
# Output: 78

# Specific area only
/analyze:codebase --focus=security --output=json
```

## CI/CD Integration

```yaml
# .github/workflows/health-check.yml
name: Codebase Health
on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Analysis
        run: /analyze:codebase --output=json > report.json

      - name: Check Score
        run: |
          SCORE=$(/analyze:codebase --score-only)
          if [ $SCORE -lt 70 ]; then
            echo "Health score $SCORE is below threshold 70"
            exit 1
          fi

      - name: Upload Report
        uses: actions/upload-artifact@v4
        with:
          name: health-report
          path: report.json
```

## Related Commands

- [/laravel-agent:review:audit](/commands/review-audit.md) - Security-focused audit
- [/laravel-agent:db:optimize](/commands/db-optimize.md) - Database optimization
- [/laravel-agent:test:coverage](/commands/test-coverage.md) - Test coverage report
- [/laravel-agent:refactor](/commands/refactor.md) - Code refactoring

## Related Agents

- `laravel-review` - Code review specialist
- `laravel-security` - Security analysis
- `laravel-testing` - Test coverage analysis
- `laravel-database` - Database optimization
