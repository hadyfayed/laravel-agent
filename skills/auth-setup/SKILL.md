---
name: auth-setup
description: SET UP Laravel authentication with Sanctum/Fortify/Breeze, guards, roles & permissions, policies, social login, 2FA; when initializing auth in a new project (NOT for reference questions).
disable-model-invocation: true
allowed-tools: Bash(composer require) Bash(composer show *) Bash(php artisan *) Read Write Edit
argument-hint: "[api|spa|oauth|social|web|full] [--authz=spatie|laratrust|policies]"
---

## Environment

- Installed packages: !`composer show laravel/sanctum 2>/dev/null && echo "sanctum=yes" || echo "sanctum=no"; composer show laravel/passport 2>/dev/null && echo "passport=yes" || echo "passport=no"; composer show laravel/fortify 2>/dev/null && echo "fortify=yes" || echo "fortify=no"; composer show spatie/laravel-permission 2>/dev/null && echo "spatie=yes" || echo "spatie=no"; composer show santigarcor/laratrust 2>/dev/null && echo "laratrust=yes" || echo "laratrust=no"`

## Task

Wire up authentication and authorization. `$ARGUMENTS` carries the preset (`api`, `spa`, `oauth`, `social`, `web`, `full`) and optional `--authz=` flag.

## Presets

| Preset | Auth type | Packages |
| :--- | :--- | :--- |
| `api` | Token API | laravel/sanctum |
| `spa` | Cookie/CSRF SPA | laravel/sanctum |
| `oauth` | OAuth2 server | laravel/passport |
| `social` | Social login | laravel/socialite (+ socialiteproviders |
| `web` | Session (Breeze/Fortify) | laravel/breeze or laravel/fortify |
| `full` | All of the above | per option |

Authorization choices: `spatie` (roles+permissions, simple), `laratrust` (teams+roles+permissions, complex), `policies` (Laravel built-in only).

## Steps

1. **Install missing packages** for the chosen preset (use the environment output above to skip what is already present):
   ```bash
   composer require laravel/sanctum      # api / spa
   composer require laravel/passport     # oauth
   composer require laravel/breeze       # web (then: php artisan breeze:install)
   composer require spatie/laravel-permission  # authz=spatie
   composer require santigarcor/laratrust      # authz=laratrust
   ```

2. **Publish vendor config / migrations** as each package requires:
   ```bash
   php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
   php artisan passport:install           # oauth — client keys + personal-access client
   php artisan laratrust:setup             # authz=laratrust — config + migration
   ```

3. **Configure `config/auth.php`** guards and providers:
   - `web` (session) for browser flows.
   - `sanctum` (or `api`) for tokens; `passport` driver for OAuth2.
   - Define the user provider explicitly.

4. **Add routes** under `routes/api.php` and/or `routes/web.php`:
   - `POST /login`, `POST /logout`, `POST /register`.
   - Sanctum SPA: `GET /sanctum/csrf-cookie`, guarded user endpoint.
   - Social: `GET /auth/{provider}/redirect`, `GET /auth/{provider}/callback`.

5. **Authorization** — follow the conventions in the `laravel-auth` skill for policies, gates, roles, and permission seeding rather than duplicating them here. Seeders should create roles (e.g. `super-admin`, `admin`, `user`) and attach permissions.

6. **Optional extras** when requested:
   - **2FA** — enable via Fortify two-factor-challenge configuration.
   - **Rate limiting** — apply `throttle` to login/register routes.

7. **Run migrations and seed** authorization data:
   ```bash
   php artisan migrate
   php artisan db:seed --class=RolesAndPermissionsSeeder
   ```

8. **Report** installed packages, routes added, roles/permissions created, and the `.env` keys still required (e.g. provider API keys for social, `PASSPORT_PRIVATE_KEY`).

## Security guardrails

- Hash passwords via the `hashed` cast or `Hash::make()` — never plain.
- Regenerate the session after login; revoke tokens on logout.
- Require HTTPS in production; never log credentials or tokens.

## Reference

Deep auth patterns — guards, policies, gates, Sanctum/Passport/Socialite integration, 2FA — live in the **laravel-auth** reference skill. Apply those conventions when implementing the wiring above.
