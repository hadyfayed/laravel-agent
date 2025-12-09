---
description: "Review a pull request with parallel specialized reviewers"
allowed-tools: Task, Read, Glob, Grep, Bash
---

# /review:pr - Pull Request Review

Run comprehensive code review on a pull request using 4 parallel specialized reviewers.

## Input
$ARGUMENTS = `[pr-number-or-branch]`

Examples:
- `/review:pr 123` - Review PR #123
- `/review:pr feature/user-auth` - Review branch against main
- `/review:pr` - Review current branch against main

## Process

### 1. Gather PR Context

```bash
# Get PR info (if using gh cli)
gh pr view $PR_NUMBER --json files,commits,body

# Or get branch diff
git fetch origin
git diff origin/main...HEAD --name-only
git diff origin/main...HEAD --stat
```

### 2. Identify Changed Files

```bash
# Get list of changed files
git diff origin/main...HEAD --name-only | grep -E '\.(php|blade\.php)$'
```

### 3. Launch Parallel Reviewers

Spawn 4 agents simultaneously using Task tool:

**Security Reviewer:**
- SQL injection patterns
- XSS vulnerabilities
- Mass assignment
- Auth/authz gaps
- CSRF protection
- File upload security

**Quality Reviewer:**
- SOLID violations
- DRY violations
- Cyclomatic complexity
- Coupling issues
- Naming conventions
- Dead code

**Laravel Reviewer:**
- N+1 queries
- Eloquent best practices
- Event patterns
- Resource usage
- Middleware patterns
- Validation patterns

**Testing Reviewer:**
- Test coverage for changes
- Edge case testing
- Assertion quality
- Test isolation
- New tests needed

### 4. Validate & Filter

Only include issues with confidence >= 80%

### 5. Generate Report

```markdown
# PR Review: #<number> - <title>

## Overview
- Files changed: X
- Lines added: X
- Lines removed: X
- Review status: **Approved/Changes Requested/Comment**

## Summary
| Severity | Count |
|----------|-------|
| Critical | X |
| Warning | X |
| Suggestion | X |

## Critical Issues (Block Merge)
[Issues that must be fixed]

## Warnings (Should Fix)
[Issues that should be addressed]

## Suggestions (Consider)
[Improvements to consider]

## Positive Findings
[Good patterns observed]

## Verdict
[ ] **APPROVED** - Ready to merge
[x] **CHANGES REQUESTED** - Address critical issues
[ ] **COMMENT** - Suggestions only
```

## GitHub Integration

```bash
# Post review as PR comment
gh pr review $PR_NUMBER --body "$(cat review-report.md)"

# Request changes
gh pr review $PR_NUMBER --request-changes --body "$(cat review-report.md)"

# Approve
gh pr review $PR_NUMBER --approve --body "$(cat review-report.md)"
```
