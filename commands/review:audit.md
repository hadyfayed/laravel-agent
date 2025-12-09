---
description: "Full codebase security and quality audit"
allowed-tools: Task, Read, Glob, Grep, Bash, Write
---

# /review:audit - Full Codebase Audit

Perform comprehensive security and quality audit of the entire Laravel codebase.

## Input
$ARGUMENTS = `[target-path] [--focus=area]`

Examples:
- `/review:audit` - Full codebase audit
- `/review:audit app/Http` - Audit HTTP layer
- `/review:audit --focus=security` - Security-focused audit
- `/review:audit app/Services --focus=quality` - Quality audit of services

## Focus Areas
- `all` - Complete audit (default)
- `security` - OWASP Top 10 focus
- `quality` - SOLID/DRY/complexity focus
- `performance` - N+1, caching, indexing
- `testing` - Coverage and quality

## Process

### 1. Scope Analysis

```bash
# Count files to audit
find app/ -name "*.php" | wc -l

# Identify high-priority targets
ls -la app/Http/Controllers/
ls -la app/Services/
ls -la app/Models/
```

### 2. Parallel Audit by Domain

Launch domain-specific audits in parallel:

```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Controllers  │  Services    │   Models     │   Configs    │
│ Audit        │  Audit       │   Audit      │   Audit      │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

### 3. Security Audit Checklist

**Authentication:**
- [ ] Auth middleware on protected routes
- [ ] Password hashing (bcrypt/argon2)
- [ ] Session security settings
- [ ] Remember me token security

**Authorization:**
- [ ] Policies for all models
- [ ] Gate definitions
- [ ] Role/permission checks
- [ ] Resource ownership validation

**Input Validation:**
- [ ] Form Request usage
- [ ] File upload validation
- [ ] API request validation
- [ ] Query parameter sanitization

**Output Encoding:**
- [ ] Blade escaping ({{ }} vs {!! !!})
- [ ] JSON response encoding
- [ ] Header injection prevention

**Database Security:**
- [ ] Parameterized queries
- [ ] Eloquent usage (not raw)
- [ ] Mass assignment protection
- [ ] Sensitive data encryption

**Configuration:**
- [ ] Debug mode off in production
- [ ] APP_KEY set and secure
- [ ] HTTPS enforcement
- [ ] CORS configuration
- [ ] Security headers

### 4. Quality Audit Metrics

```
┌─────────────────────────────────────────────────────────┐
│                   QUALITY METRICS                        │
├──────────────────┬──────────────────────────────────────┤
│ Metric           │ Threshold                            │
├──────────────────┼──────────────────────────────────────┤
│ Method Lines     │ ≤ 20 lines                           │
│ Class Lines      │ ≤ 200 lines                          │
│ Cyclomatic       │ ≤ 10 per method                      │
│ Dependencies     │ ≤ 5 constructor params               │
│ Test Coverage    │ ≥ 80%                                │
│ DRY Violations   │ 0 (3+ duplicates)                    │
└──────────────────┴──────────────────────────────────────┘
```

### 5. Generate Audit Report

```markdown
# Laravel Codebase Audit Report

**Generated:** <timestamp>
**Scope:** <target-path>
**Files Audited:** X

## Executive Summary

| Area | Score | Issues | Recommendation |
|------|-------|--------|----------------|
| Security | 85/100 | 3 | Address auth gaps |
| Quality | 78/100 | 7 | Reduce complexity |
| Laravel | 92/100 | 2 | Minor improvements |
| Testing | 65/100 | 5 | Increase coverage |
| **Overall** | **80/100** | **17** | **See details** |

## Security Findings

### Critical (0)
No critical security issues found.

### High (2)
1. **Missing CSRF protection** - `routes/api.php:45`
2. **Raw query with user input** - `app/Services/ReportService.php:78`

### Medium (1)
1. **Debug mode enabled in config** - `config/app.php`

## Quality Findings

### High Complexity Methods
| File | Method | Complexity | Recommendation |
|------|--------|------------|----------------|
| OrderService.php | processOrder | 15 | Extract to smaller methods |

### SOLID Violations
| File | Violation | Recommendation |
|------|-----------|----------------|
| UserController.php | SRP | Extract validation to FormRequest |

### DRY Violations
| Pattern | Occurrences | Files |
|---------|-------------|-------|
| Date formatting | 5 | Various |

## Testing Gaps

### Missing Tests
| File | Methods Without Tests |
|------|----------------------|
| PaymentService.php | processRefund, validateCard |

### Coverage by Directory
| Directory | Coverage |
|-----------|----------|
| app/Http/Controllers | 75% |
| app/Services | 60% |
| app/Models | 90% |

## Recommendations

### Immediate Actions
1. Fix raw SQL query in ReportService
2. Add CSRF middleware to API routes
3. Disable debug mode

### Short-term Improvements
1. Refactor high-complexity methods
2. Add missing tests for PaymentService
3. Extract duplicate date formatting

### Long-term Enhancements
1. Implement event-driven architecture
2. Add circuit breakers for external services
3. Implement caching strategy

## Appendix

### Files Audited
[Complete list of files reviewed]

### Tools Used
- Security: OWASP patterns, Laravel security checks
- Quality: Cyclomatic complexity, coupling analysis
- Testing: PHPUnit coverage report
```

## Output Options

```bash
# Generate markdown report
/review:audit > audit-report.md

# Generate JSON for CI integration
/review:audit --format=json > audit-report.json

# Generate only score for CI pipeline
/review:audit --score-only
# Output: 80
```
