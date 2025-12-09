---
description: "Setup authentication and authorization for your Laravel app"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /auth:setup - Authentication & Authorization Setup Wizard

Interactive wizard to configure authentication and authorization.

## Input
$ARGUMENTS = `[preset]`

Presets:
- `/auth:setup` - Interactive wizard
- `/auth:setup api` - API-only with Sanctum
- `/auth:setup spa` - SPA with Sanctum
- `/auth:setup oauth` - OAuth2 server with Passport
- `/auth:setup social` - Social login with Socialite
- `/auth:setup full` - Full setup with all options

## Process

1. **Check Installed Packages**
   ```bash
   composer show laravel/sanctum 2>/dev/null && echo "SANCTUM=yes" || echo "SANCTUM=no"
   composer show laravel/passport 2>/dev/null && echo "PASSPORT=yes" || echo "PASSPORT=no"
   composer show laravel/fortify 2>/dev/null && echo "FORTIFY=yes" || echo "FORTIFY=no"
   composer show santigarcor/laratrust 2>/dev/null && echo "LARATRUST=yes" || echo "LARATRUST=no"
   composer show spatie/laravel-permission 2>/dev/null && echo "SPATIE=yes" || echo "SPATIE=no"
   composer show socialiteproviders/manager 2>/dev/null && echo "SOCIALITE=yes" || echo "SOCIALITE=no"
   ```

2. **Authentication Type**
   ```
   What type of authentication do you need?
   - Web: Session-based (Breeze/Fortify)
   - API: Token-based (Sanctum)
   - OAuth2: Full OAuth2 server (Passport)
   - SPA: Single Page App (Sanctum + CSRF)
   ```

3. **Authorization System**
   ```
   How do you want to handle authorization?
   - Laratrust: Teams + Roles + Permissions (complex)
   - Spatie Permission: Roles + Permissions (simple)
   - Policies Only: Laravel built-in policies
   ```

4. **Social Login**
   ```
   Enable social login?
   - Yes: Configure providers (Google, GitHub, etc.)
   - No: Skip social authentication
   ```

5. **Two-Factor Authentication**
   ```
   Enable 2FA?
   - Yes: Setup with Fortify
   - No: Skip 2FA
   ```

6. **Invoke Auth Agent**

   Use Task tool with subagent_type `laravel-auth`:
   ```
   Setup authentication:

   Action: setup
   AuthType: <web|api|oauth|spa>
   Authorization: <laratrust|spatie|policies>
   SocialProviders: [google, github, apple] or []
   Enable2FA: <yes|no>
   ```

7. **Report Results**
   ```markdown
   ## Authentication Configured

   ### Type
   [Web | API | OAuth2 | SPA]

   ### Packages Installed/Configured
   - [ ] laravel/sanctum
   - [ ] laravel/passport
   - [ ] laravel/fortify
   - [ ] spatie/laravel-permission
   - [ ] socialiteproviders/manager

   ### Routes Added
   - POST /login
   - POST /logout
   - POST /register
   - GET /auth/{provider} (social)

   ### Roles Created
   - super-admin
   - admin
   - user

   ### Permissions
   Run: `php artisan db:seed --class=RolesAndPermissionsSeeder`

   ### Next Steps
   1. Configure .env with API keys
   2. Run migrations: `php artisan migrate`
   3. Seed permissions: `php artisan db:seed`
   ```

## Quick Presets

### API Setup (`/auth:setup api`)
- Installs Sanctum if not present
- Configures token authentication
- Creates API auth controller
- Adds auth routes

### SPA Setup (`/auth:setup spa`)
- Sanctum with CSRF protection
- Cookie-based sessions
- Proper CORS configuration

### OAuth2 Setup (`/auth:setup oauth`)
- Laravel Passport installation
- Client credentials grant
- Password grant
- Authorization code grant

### Social Setup (`/auth:setup social`)
- Socialite providers
- Social auth controller
- Database migration for provider fields
