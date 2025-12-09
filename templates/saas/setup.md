---
description: "Initialize a SaaS starter project"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /project:init saas - SaaS Starter Setup

Initialize a production-ready SaaS application.

## Process

1. **Install Required Packages**
   ```bash
   composer require \
       laravel/cashier \
       laravel/fortify \
       laravel/sanctum \
       laravel/horizon \
       filament/filament:^3.0 \
       spatie/laravel-permission \
       spatie/laravel-activitylog \
       bezhansalleh/filament-shield \
       spatie/laravel-backup

   composer require --dev \
       pestphp/pest \
       pestphp/pest-plugin-laravel \
       larastan/larastan \
       laravel/pint
   ```

2. **Publish Configurations**
   ```bash
   php artisan vendor:publish --tag=fortify-config
   php artisan vendor:publish --tag=sanctum-config
   php artisan vendor:publish --tag=horizon-config
   php artisan vendor:publish --tag=permission-config
   php artisan filament:install --panels
   php artisan shield:install
   ```

3. **Create Core Structure**
   - `app/Features/Billing/` - Subscription management
   - `app/Features/Teams/` - Team management
   - `app/Features/Settings/` - User settings
   - `app/Modules/Tenancy/` - Multi-tenant core
   - `app/Support/Tenancy/` - Tenant traits/concerns

4. **Database Setup**
   - Teams migration
   - Team-user pivot migration
   - Add `team_id` to relevant tables
   - Subscription tables (Cashier)
   - Activity log table

5. **Create Seeders**
   - RolesAndPermissionsSeeder
   - PlansSeeder (subscription plans)
   - AdminUserSeeder

6. **Configure Filament**
   - Create AdminPanelProvider
   - Register Shield plugin
   - Create dashboard widgets
   - Setup team switching

7. **Setup CI/CD**
   ```bash
   /cicd:setup github
   ```

8. **Report Results**
   ```markdown
   ## SaaS Project Initialized

   ### Features Installed
   - [x] Multi-tenant team structure
   - [x] Stripe subscription billing
   - [x] Fortify authentication with 2FA
   - [x] Sanctum API tokens
   - [x] Filament admin panel
   - [x] Roles and permissions
   - [x] Activity logging
   - [x] Horizon queue dashboard

   ### Next Steps
   1. Configure Stripe keys in .env
   2. Create subscription plans in Stripe
   3. Update PlansSeeder with plan IDs
   4. Run: `php artisan migrate`
   5. Run: `php artisan db:seed`
   6. Access admin: /admin
   7. Access app: /dashboard

   ### Commands Available
   - `/feature:make <Name>` - Create new feature
   - `/billing:webhook` - Setup Stripe webhook
   - `/deploy:setup vapor` - Deploy to Vapor
   ```
