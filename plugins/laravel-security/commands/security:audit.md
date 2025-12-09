---
description: "Run security audit on your Laravel application"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /security:audit - Security Audit

Audit your Laravel application for security vulnerabilities.

## Input
$ARGUMENTS = `[target] [focus]`

Options:
- `/security:audit` - Full audit
- `/security:audit auth` - Focus on authentication
- `/security:audit injection` - Focus on SQL/command injection
- `/security:audit xss` - Focus on XSS vulnerabilities
- `/security:audit app/Http/Controllers` - Audit specific path

## Process

1. **Check Environment**
   ```bash
   composer show spatie/laravel-csp 2>/dev/null && echo "CSP=yes" || echo "CSP=no"
   composer show enlightn/enlightn 2>/dev/null && echo "ENLIGHTN=yes" || echo "ENLIGHTN=no"
   composer audit
   ```

2. **Invoke Security Agent**

   Use Task tool with subagent_type `laravel-security`:
   ```
   Perform security audit:

   Action: audit
   Target: <path or 'all'>
   Focus: <injection|xss|csrf|auth|headers|all>
   ```

3. **Report Results**
   ```markdown
   ## Security Audit Results

   ### Summary
   - Critical: X
   - High: X
   - Medium: X
   - Low: X

   ### Vulnerabilities
   | Severity | Type | Location | Fix |
   |----------|------|----------|-----|
   | Critical | SQL Injection | file:line | Use parameterized query |
   | ... | ... | ... | ... |

   ### Dependency Vulnerabilities
   <output from composer audit>

   ### Configuration Issues
   - [ ] APP_DEBUG enabled in production
   - [ ] Secure cookies not configured
   - ...

   ### Recommendations
   1. ...
   2. ...
   ```

## Focus Areas

### Authentication (`/security:audit auth`)
- Password hashing
- Session configuration
- Rate limiting on login
- Token expiration
- 2FA implementation

### Injection (`/security:audit injection`)
- SQL injection in queries
- Command injection in exec/shell
- LDAP injection
- NoSQL injection

### XSS (`/security:audit xss`)
- Unescaped Blade output
- JavaScript injection
- DOM-based XSS
- Stored XSS in database

### Headers (`/security:audit headers`)
- Security headers configuration
- CORS settings
- CSP policy
- HSTS configuration
