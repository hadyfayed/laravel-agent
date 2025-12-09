---
description: "AI-powered code review for Laravel applications"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /code:review - AI Code Review

Perform an AI-powered code review on your Laravel application.

## Input
$ARGUMENTS = `[target] [focus]`

Examples:
- `/code:review` - Review recent changes (git diff)
- `/code:review app/Services` - Review specific directory
- `/code:review app/Http/Controllers/OrderController.php` - Review specific file
- `/code:review --pr=123` - Review pull request
- `/code:review --focus=security` - Focus on security issues

## Focus Areas
- `all` - Comprehensive review (default)
- `security` - Security vulnerabilities
- `performance` - Performance issues
- `solid` - SOLID principles violations
- `testing` - Test coverage and quality
- `laravel` - Laravel best practices

## Process

1. **Gather Code**
   - Read target files
   - Get git diff for changes
   - Identify scope

2. **Analyze**
   - Check for code smells
   - Identify potential bugs
   - Verify best practices
   - Check security issues
   - Review performance

3. **Report**
   ```markdown
   ## Code Review: <Target>

   ### Summary
   - Files reviewed: X
   - Issues found: X critical, X warnings, X suggestions

   ### Critical Issues
   | File | Line | Issue | Suggestion |
   |------|------|-------|------------|
   | OrderController.php | 45 | SQL injection risk | Use parameterized query |

   ### Warnings
   | File | Line | Issue | Suggestion |
   |------|------|-------|------------|
   | UserService.php | 23 | N+1 query | Add eager loading |

   ### Suggestions
   | File | Line | Suggestion |
   |------|------|------------|
   | helpers.php | 12 | Consider using Str::slug() |

   ### Positive Findings
   - Good use of form requests for validation
   - Proper use of policies for authorization
   ```

## Review Criteria

### Security
- SQL injection
- XSS vulnerabilities
- Mass assignment
- CSRF protection
- Authentication/authorization
- Sensitive data exposure

### Performance
- N+1 queries
- Missing indexes
- Unnecessary queries
- Cache opportunities
- Chunking for large datasets

### Code Quality
- SOLID principles
- DRY violations
- Method length (>20 lines)
- Class responsibility
- Error handling

### Laravel Best Practices
- Use of facades vs injection
- Form request validation
- Resource controllers
- Eloquent relationships
- Event-driven architecture
