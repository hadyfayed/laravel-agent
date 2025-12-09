# SaaS Starter Template

A production-ready SaaS application template with multi-tenancy, subscription billing, and team management.

## Features

- **Multi-Tenancy**: Team-based isolation with `created_for_id` pattern
- **Subscription Billing**: Stripe integration via Laravel Cashier
- **Authentication**: Fortify + Sanctum with 2FA support
- **Authorization**: Spatie Permission with roles/permissions
- **Admin Panel**: Filament 3 with Shield for RBAC
- **API**: Versioned RESTful API with rate limiting
- **Queue Management**: Laravel Horizon dashboard
- **Activity Logging**: Spatie Activitylog for audit trail

## Quick Start

```bash
# Create new project
laravel new my-saas --git

# Install dependencies
composer require \
    laravel/cashier \
    laravel/fortify \
    laravel/sanctum \
    laravel/horizon \
    filament/filament \
    spatie/laravel-permission \
    spatie/laravel-activitylog \
    bezhansalleh/filament-shield

# Run the setup command
/project:init saas
```

## Directory Structure

```
app/
├── Features/
│   ├── Billing/           # Subscription management
│   ├── Teams/             # Team/organization management
│   └── Settings/          # User & team settings
├── Modules/
│   └── Tenancy/           # Multi-tenant core
├── Http/
│   └── Middleware/
│       └── EnsureTeamSelected.php
└── Support/
    └── Tenancy/
        └── Concerns/
            └── BelongsToTeam.php
```

## Configuration

### Environment Variables

```env
# Stripe
STRIPE_KEY=pk_test_xxx
STRIPE_SECRET=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

# Billing Plans
STRIPE_PRICE_MONTHLY=price_xxx
STRIPE_PRICE_YEARLY=price_xxx

# Features
FEATURE_TEAMS=true
FEATURE_BILLING=true
FEATURE_2FA=true
```

### Database Migrations

```bash
php artisan migrate
php artisan db:seed --class=RolesAndPermissionsSeeder
```

## Usage

### Creating a Team

```php
$team = Team::create([
    'name' => 'My Company',
    'owner_id' => auth()->id(),
]);

// Add members
$team->users()->attach($userId, ['role' => 'member']);
```

### Billing

```php
// Subscribe user to plan
$user->newSubscription('default', $priceId)->create($paymentMethod);

// Check subscription
if ($user->subscribed('default')) {
    // Has active subscription
}

// Feature gating
if ($user->subscription('default')->hasFeature('advanced-reports')) {
    // Can access advanced reports
}
```

### Multi-tenant Queries

```php
// Models automatically scoped to current team
$orders = Order::all(); // Only current team's orders

// Manual team query
$orders = Order::forTeam($teamId)->get();
```

## Slash Commands

- `/feature:make Invoices` - Create new feature
- `/billing:setup` - Configure subscription plans
- `/team:create` - Set up team management
- `/deploy:setup vapor` - Deploy to Laravel Vapor

## Recommended Packages

| Package | Purpose |
|---------|---------|
| laravel/cashier | Stripe billing |
| laravel/fortify | Authentication |
| laravel/horizon | Queue dashboard |
| filament/filament | Admin panel |
| spatie/laravel-permission | Roles/permissions |
| spatie/laravel-activitylog | Audit logging |
| spatie/laravel-backup | Database backups |
