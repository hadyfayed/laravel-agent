---
description: "Review staged changes before commit"
allowed-tools: Task, Read, Glob, Grep, Bash
---

# /review:staged - Pre-Commit Review

Quick review of staged changes before committing. Runs focused checks on changed code only.

## Input
$ARGUMENTS = `[--fail-on=level]`

Examples:
- `/review:staged` - Review staged changes
- `/review:staged --fail-on=critical` - Fail only on critical issues
- `/review:staged --fail-on=warning` - Fail on warnings and above

## Process

### 1. Get Staged Changes

```bash
# List staged files
git diff --cached --name-only | grep -E '\.(php|blade\.php)$'

# Get staged diff
git diff --cached
```

### 2. Quick Security Scan

Focus on high-confidence security issues:

```php
// SQL Injection (95% confidence)
/DB::raw\([^)]*\$|whereRaw\([^)]*\$|selectRaw\([^)]*\$/

// XSS (95% confidence)
/\{\!\!.*\$.*\!\!\}/

// Mass Assignment (90% confidence)
/->create\(\$request->all\(\)\)|->fill\(\$request->all\(\)\)/

// Hardcoded Secrets (95% confidence)
/'(password|secret|key|token)'\s*=>\s*'[^']+'/i
```

### 3. Quick Quality Scan

```php
// Long methods (85% confidence)
// Count lines between function start and end

// Debug statements (95% confidence)
/\bdd\(|\bdump\(|\bvar_dump\(|\bprint_r\(/
```

### 4. Output

```markdown
## Pre-Commit Review

### Staged Files
- app/Http/Controllers/UserController.php (+45, -12)
- app/Services/OrderService.php (+23, -5)

### Issues Found
| Severity | Issue | File | Line |
|----------|-------|------|------|
| Critical | Debug statement (dd) | OrderService.php | 45 |
| Warning | Long method (35 lines) | UserController.php | 23 |

### Verdict
[ ] **PASS** - Safe to commit
[x] **FAIL** - Fix issues before committing
```

## Exit Codes

For CI/Hook integration:
- `0` - No issues or only suggestions
- `1` - Warnings found (if --fail-on=warning)
- `2` - Critical issues found

## Git Hook Integration

```bash
# .git/hooks/pre-commit
#!/bin/bash
claude /review:staged --fail-on=critical
exit $?
```
