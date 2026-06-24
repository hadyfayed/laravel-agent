---
name: laravel-security
description: Laravel security conventions and OWASP best practices — XSS, SQL injection, CSRF, mass assignment, auth/authorization checks, security headers, rate limiting, encrypted attributes; when hardening code, reviewing for vulnerabilities (NOT for running a specific audit; use security-audit).
---

# Laravel Security Skill

Apply Laravel security best practices when writing controllers, reviewing code
for vulnerabilities, configuring headers, or hardening authentication and
authorization.

## When to Use

- Reviewing code for security vulnerabilities (OWASP Top 10)
- Adding authorization checks, policies, or gates
- Hardening authentication, sessions, and passwords
- Configuring security headers / CSP, rate limiting
- Encrypting sensitive model attributes or audit logging

## Security Checklist

### Mass Assignment
- [ ] Declare `$fillable` explicitly — never set `$guarded = []`
- [ ] Validate all request input with `$request->validate()` or Form Requests
- [ ] Use `$request->validated()` (not `$request->all()`) when mass-assigning

### Authorization
- [ ] Call `$this->authorize(...)` (or a policy method) on every mutating action
- [ ] Prefer Policies for resource authorization; Gates for ad-hoc checks
- [ ] Authorize on the resolved model, not on the route parameter alone

### SQL Injection
- [ ] Use Eloquent / Query Builder — never interpolate variables into SQL
- [ ] Bind parameters for raw queries: `DB::select('... WHERE email = ?', [$email])`
- [ ] Treat `DB::statement`, `whereRaw`, and `selectRaw` input as user data — bind it

### XSS / Output
- [ ] Rely on Blade auto-escaping (`{{ }}`) — never `{!! !!}` with user input
- [ ] Sanitize/whitelist HTML before rendering trusted rich text

### CSRF / Sessions
- [ ] Include `@csrf` in every POST/PUT/DELETE form
- [ ] Sessions: `secure => true`, `http_only => true`, `same_site` (lax/strict)
- [ ] Disable `debug` and `APP_DEBUG` in production

### Auth & Passwords
- [ ] Use `Hash::make()`/`Hash::check()` — never store plaintext or MD5
- [ ] Apply `Illuminate\Validation\Rules\Password` (min length, mixed case, `->uncompromised()`)
- [ ] Set `Password::defaults()` per environment

### Security Headers & CSP
- [ ] Send `X-Content-Type-Options`, `X-Frame-Options`, HSTS, `Referrer-Policy`
- [ ] Define a `Content-Security-Policy` (`default-src 'self'`, `frame-ancestors 'none'`)
- [ ] Add a `SecurityHeaders` middleware to the web stack

### Rate Limiting
- [ ] Throttle login and sensitive endpoints (`throttle:5,1`)
- [ ] Define `RateLimiter::for(...)` keyed by user id or IP

### Secrets & Encryption
- [ ] Secrets in `.env` only — never in code, logs, or error messages
- [ ] Encrypt PII/sensitive columns (`encrypted` cast or `Crypt::` attribute)
- [ ] Scrub sensitive fields from log context (log `card_last4`, never the full PAN)

### Dependencies
- [ ] Run `composer audit` regularly; keep packages updated

## OWASP Top 10 Quick Map

| Risk | Laravel defense |
|------|-----------------|
| Injection | Eloquent, Query Builder, validation, bound params |
| Broken Auth | Built-in auth, bcrypt/argon hashing, session hardening |
| XSS | Blade auto-escaping |
| CSRF | `@csrf` token |
| Broken Access Control | Gates, Policies, `$this->authorize()` |
| Security Misconfiguration | `.env`, config caching, debug off |
| Sensitive Data Exposure | Encryption, HTTPS, HSTS |
| Vulnerable Components | `composer audit` |
| Logging Failures | Dedicated `security` log channel, audit events |

## Related Skills

- `laravel-auth` — authentication and authorization setup (includes Sanctum/Passport references)
- `laravel-passport` — OAuth2 auth (folded into the `laravel-auth` skill)

## Additional references

- Secure coding patterns (auth, authz, validation, injection, XSS, CSRF, headers, rate limiting, password rules, common pitfalls) → [references/secure-patterns.md](references/secure-patterns.md)
- OWASP Top 10 coverage, security-headers/CSP middleware, encrypted attributes, audit logging → [references/owasp-top-10.md](references/owasp-top-10.md)
