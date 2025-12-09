# Review Commands Reference

This document clarifies the review-related commands across Laravel Agent plugins.

## Command Overview

| Command | Plugin | Purpose | Use When |
|---------|--------|---------|----------|
| `/review:staged` | laravel-review | Quick pre-commit check | Before committing |
| `/review:pr` | laravel-review | Full PR review with parallel agents | Creating/reviewing PRs |
| `/review:audit` | laravel-review | Comprehensive codebase audit | Periodic quality checks |
| `/security:audit` | laravel-security | Deep OWASP security audit | Security-focused analysis |
| `/bug:fix` | laravel-ai | AI-powered error analysis | Debugging specific errors |
| `/docs:generate` | laravel-ai | Generate documentation | Creating docs from code |

## When to Use Each

### `/review:staged` (laravel-review)
- **Speed:** Fast (~30 seconds)
- **Depth:** Surface-level security + quality
- **Use:** Pre-commit hook, quick sanity check
```bash
/review:staged --fail-on=critical
```

### `/review:pr` (laravel-review)
- **Speed:** Medium (~2-3 minutes)
- **Depth:** Full 4-agent parallel review
- **Use:** Pull request creation, team reviews
```bash
/review:pr 123
/review:pr --base=main
```

### `/review:audit` (laravel-review)
- **Speed:** Slow (~5-10 minutes)
- **Depth:** Comprehensive quality + security + testing
- **Use:** Sprint end, release prep, new project onboarding
```bash
/review:audit
/review:audit app/Services --focus=quality
```

### `/security:audit` (laravel-security)
- **Speed:** Medium (~3-5 minutes)
- **Depth:** Deep OWASP Top 10 analysis
- **Use:** Security compliance, penetration test prep
```bash
/security:audit
/security:audit auth
/security:audit --focus=injection
```

### `/bug:fix` (laravel-ai)
- **Speed:** Fast (~1 minute)
- **Depth:** Error-specific analysis
- **Use:** Debugging production errors, understanding exceptions
```bash
/bug:fix
/bug:fix "SQLSTATE[42S22]"
/bug:fix storage/logs/laravel.log
```

### `/docs:generate` (laravel-ai)
- **Speed:** Medium (~2-3 minutes)
- **Depth:** Code analysis for documentation
- **Use:** README generation, API docs, architecture docs
```bash
/docs:generate
/docs:generate api
/docs:generate architecture
```

## Integration

### Recommended Workflow

```
Development:
  /bug:fix ────► Fix error ────► /review:staged ────► Commit

PR Creation:
  /review:pr ────► Address issues ────► Merge

Release:
  /review:audit ────► /security:audit ────► /docs:generate ────► Release
```

### Git Hooks Integration

```bash
# Pre-commit: Quick check
/review:staged --fail-on=critical

# Pre-push: Quality gate
/review:audit --score-only  # Fail if < 70
```
