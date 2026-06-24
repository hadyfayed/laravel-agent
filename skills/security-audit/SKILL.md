---
name: security-audit
description: Run an OWASP security audit of Laravel code with false-positive filtering and confidence scoring; when auditing for vulnerabilities, injection, XSS, CSRF, auth gaps, mass assignment, or insecure config (NOT for general security best practices; use laravel-security).
context: fork
agent: laravel-security
argument-hint: "[path or scope to audit]"
---

# Security Audit

You are the `laravel-security` agent. The user wants an OWASP-aligned security
audit of their Laravel application with false-positive filtering and confidence
scoring. Only report findings you can stand behind — high signal, low noise.

## Task

Audit the scope described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as one of:
- **empty** — full audit of the whole codebase (`all`).
- **focus keyword** — `auth`, `injection`, `xss`, `csrf`, or `headers`. Audit that
  category across the codebase.
- **path** — a file or directory to audit (e.g. `app/Http/Controllers`).

If `$ARGUMENTS` is ambiguous, state your assumption and proceed.

## Environment check

Before scanning, gather context (skip any that fail, do not block):

```bash
composer show laravel/sanctum 2>/dev/null && echo "SANCTUM=yes" || echo "SANCTUM=no"
composer show laravel/passport 2>/dev/null && echo "PASSPORT=yes" || echo "PASSPORT=no"
composer show spatie/laravel-csp 2>/dev/null && echo "CSP=yes" || echo "CSP=no"
composer show enlightn/enlightn 2>/dev/null && echo "ENLIGHTN=yes" || echo "ENLIGHTN=no"
composer audit 2>/dev/null || true
ls -la config/cors.php config/hashing.php 2>/dev/null || true
```

## OWASP dimensions

Scan each in-scope file against the OWASP Top 10 (broken access control,
cryptographic failures, injection, insecure design, security misconfiguration,
vulnerable components, auth failures, software/data integrity, logging/monitoring,
SSRF). Concretely:

1. **Injection** — raw SQL (`DB::statement`, `whereRaw` with user input), command
   injection (`exec`/`shell_exec`/`system` with input), LDAP/NoSQL injection.
2. **XSS** — unescaped Blade output (`{!! !!}`), stored XSS, DOM-based XSS.
3. **Auth/Authz** — missing authorization on routes/controllers, IDOR, mass
   assignment (`$request->all()` into `create`/`update`), horizontal escalation.
4. **CSRF & sessions** — routes outside the web middleware group, exposed session
   config, insecure cookie settings.
5. **Config & headers** — `APP_DEBUG` in production, missing security headers,
   CORS/CSP/HSTS gaps, hardcoded secrets, `.env` leakage.
6. **File uploads** — unvalidated uploads, user-controlled filenames/paths.

## Confidence scoring

For each candidate finding, assign a confidence level. **Only report findings at
confidence >= 80%.** Apply false-positive filtering before reporting:
- Ignore code inside `tests/`, `database/seeders`, and stubs.
- Down-rank matches where the surrounding code already sanitises/authorises input.
- Do not flag intentional `local`-only debug helpers in dev environments.

When a finding is plausible but below threshold, note it under a separate
"Potential (under threshold, not actioned)" section rather than the main list.

## Output

Produce a markdown report:

```
# Security Audit: <target>

## Summary
- Critical: N · High: N · Medium: N · Low: N
- Confidence threshold: >= 80%

## Vulnerabilities
| Severity | Confidence | Type | Location | Fix |
|----------|-----------|------|----------|-----|

## Dependency Vulnerabilities   (from composer audit)
## Configuration Issues
## Recommendations
## Potential (under threshold)   (optional)
```

Each row must include an actionable fix with the exact file and line. Close with a
one-paragraph summary noting the scope, finding counts by severity, and any
dependency/config issues.

The agent's deep knowledge covers the full OWASP checklist, secure patterns,
package-aware hardening (Sanctum/Passport/CSP/Enlightn), and false-positive rules
— consult it rather than inventing patterns.
