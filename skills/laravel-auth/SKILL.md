---
name: laravel-auth
description: Laravel authentication & authorization — login, register, guards, policies, gates, roles & permissions, API tokens (Sanctum), OAuth2 (Passport), social login (Socialite), 2FA. Use when wiring up auth, access control, or tokens.
---

# Laravel Auth Skill

Apply Laravel authentication and authorization conventions when building login/register, access control, policies, gates, roles/permissions, API tokens, OAuth2, or social login.

## When to Use

- Setting up user authentication (login, register, logout)
- Role-based access control and permissions
- Creating authorization policies and gates
- API token authentication (Sanctum) for SPAs/mobile
- Full OAuth2 server (Passport) for third-party integrations
- Social login (Socialite) with Google, GitHub, Facebook, etc.
- Two-factor authentication (Fortify)
- Multi-guard authentication

## Conventions Checklist

### Authentication
- [ ] Hash passwords via the `hashed` cast or `Hash::make()` — never plain
- [ ] Rate limit login endpoints (`throttle`)
- [ ] Regenerate the session after login to prevent session fixation
- [ ] Implement proper logout (revoke tokens, invalidate session)
- [ ] Use HTTPS in production

### Guards
- [ ] Use `web` (session) guard for browser, `sanctum`/`api` for tokens
- [ ] Define guards and providers explicitly in `config/auth.php`
- [ ] For Passport, set `api` driver to `passport`

### Authorization — Policies
- [ ] Use policies for model-level authorization
- [ ] Implement `before()` for super-admin short-circuit (return `null` to fall through)
- [ ] Use `authorizeResource()` for automatic controller authorization
- [ ] Auto-discovered at `App\Policies\{Model}Policy` (Laravel 10+) or register manually

### Authorization — Gates
- [ ] Use gates for non-model abilities (`access-admin`, `manage-team`)
- [ ] Define in `AuthServiceProvider`/`AppServiceProvider::boot()`
- [ ] Check via `Gate::allows()` / `$this->authorize()` / `@can`

### Roles & Permissions
- [ ] Permission naming: `<action>-<resource>` (`read-orders`, `approve-orders`)
- [ ] Seed roles and permissions in a `RolesAndPermissionsSeeder`
- [ ] **Spatie** for simpler setups; **Laratrust** for team/multi-tenant permissions
- [ ] Scope routes with `role:` / `permission:` middleware

### API Tokens (Sanctum)
- [ ] Add `HasApiTokens` trait to User
- [ ] Grant scoped abilities (`createToken('name', ['posts:read'])`)
- [ ] Check abilities with `$user->tokenCan('ability')` or `ability:`/`abilities:` middleware
- [ ] Revoke tokens on password change and logout
- [ ] For SPAs: CSRF cookie → session login; set `SANCTUM_STATEFUL_DOMAINS` + `supports_credentials`

### OAuth2 (Passport)
- [ ] Use Authorization Code + PKCE for SPAs/mobile (never expose client secrets)
- [ ] Use Client Credentials for machine-to-machine
- [ ] Never use Password Grant for third-party apps (deprecated)
- [ ] Define scopes via `Passport::tokensCan()`; enforce with `scope:`/`scopes:` middleware
- [ ] Set token lifetimes; prune revoked tokens (`passport:purge`)
- [ ] HTTPS required in production

### Social Login (Socialite)
- [ ] Validate provider names against an allowlist
- [ ] Handle email conflicts across providers
- [ ] Encrypt `provider_token` / `provider_refresh_token` (use `encrypted` cast)
- [ ] Use `->stateless()` for API/token flows
- [ ] Exact-match redirect URIs (HTTPS in production)

## Common Pitfalls

1. **Storing plain passwords** — always hash
2. **Missing policy registration** — register or follow auto-discovery naming
3. **Unprotected routes** — guard with `auth` + scopes/abilities
4. **Token exposure** — never log tokens; client secrets never reach the frontend
5. **No rate limiting** — throttle auth endpoints
6. **Session fixation** — regenerate session after login
7. **Wrong HasApiTokens** — Passport vs Sanctum trait must match the guard

## Package Choice

- **laravel/sanctum** — API/SPA token auth (first-party)
- **laravel/passport** — full OAuth2 server (third-party)
- **spatie/laravel-permission** — roles & permissions (simple)
- **santigarcor/laratrust** — roles & permissions (teams/multi-tenant)
- **laravel/socialite** — social login
- **laravel/fortify** — auth backend + 2FA

## Related Commands

- `/laravel-agent:auth:setup` — scaffold authentication and authorization

## Related Skills

- `laravel-security` — security audits and hardening

## Additional references

- Core auth: guards, policies, gates, roles/permissions, 2FA → [references/core-auth.md](references/core-auth.md)
- API/SPA token authentication (Sanctum) → [references/sanctum.md](references/sanctum.md)
- Full OAuth2 server (Passport) → [references/passport.md](references/passport.md)
- Social login (Socialite) → [references/socialite.md](references/socialite.md)
