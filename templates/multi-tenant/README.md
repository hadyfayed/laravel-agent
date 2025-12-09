# Multi-Tenant SaaS Template

A full multi-tenant SaaS application using Stancl Tenancy with database-per-tenant isolation.

## Features

- **Database-per-Tenant**: Complete data isolation
- **Domain-based Routing**: tenant.yourapp.com
- **Central Admin**: Manage all tenants from one dashboard
- **Subscription Billing**: Stripe with Laravel Cashier
- **Tenant Onboarding**: Self-service tenant registration
- **Feature Flags**: Per-tenant feature access with Pennant

## Quick Start

```bash
# Create new project
laravel new my-saas --git

# Install dependencies
composer require \
    stancl/tenancy \
    laravel/cashier \
    filament/filament:^3.0 \
    spatie/laravel-permission \
    laravel/pennant

# Run the setup command
/project:init multi-tenant
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Central App                        │
│  ┌───────────┐  ┌───────────┐  ┌───────────────┐   │
│  │  Tenants  │  │   Plans   │  │  Central DB   │   │
│  │ Management│  │  Billing  │  │  (shared)     │   │
│  └───────────┘  └───────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Tenant A   │  │  Tenant B   │  │  Tenant C   │
│  Database   │  │  Database   │  │  Database   │
│  (isolated) │  │  (isolated) │  │  (isolated) │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Directory Structure

```
app/
├── Models/
│   ├── Tenant.php          # Central
│   ├── Domain.php          # Central
│   └── User.php            # Tenant
├── Http/
│   ├── Controllers/
│   │   ├── Central/        # Admin dashboard
│   │   └── Tenant/         # Tenant app
│   └── Middleware/
│       └── InitializeTenancy.php
├── Filament/
│   ├── Admin/              # Central admin panel
│   └── App/                # Tenant admin panel
routes/
├── web.php                 # Central routes
├── tenant.php              # Tenant routes
└── api.php                 # API routes
config/
├── tenancy.php
└── plans.php
```

## Tenant Model

```php
<?php

use Stancl\Tenancy\Database\Models\Tenant as BaseTenant;
use Stancl\Tenancy\Contracts\TenantWithDatabase;
use Stancl\Tenancy\Database\Concerns\HasDatabase;
use Stancl\Tenancy\Database\Concerns\HasDomains;
use Laravel\Cashier\Billable;

class Tenant extends BaseTenant implements TenantWithDatabase
{
    use HasDatabase, HasDomains, Billable;

    public static function getCustomColumns(): array
    {
        return [
            'id',
            'name',
            'email',
            'plan',
            'stripe_id',
            'pm_type',
            'pm_last_four',
            'trial_ends_at',
        ];
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function onPlan(string $plan): bool
    {
        return $this->plan === $plan;
    }

    public function hasFeature(string $feature): bool
    {
        return in_array($feature, config("plans.{$this->plan}.features", []));
    }
}
```

## Plans Configuration

```php
// config/plans.php
return [
    'free' => [
        'name' => 'Free',
        'price' => 0,
        'features' => ['basic_features'],
        'limits' => [
            'users' => 3,
            'storage_mb' => 100,
        ],
    ],
    'pro' => [
        'name' => 'Pro',
        'price' => 29,
        'stripe_price_id' => env('STRIPE_PRO_PRICE_ID'),
        'features' => ['basic_features', 'advanced_reports', 'api_access'],
        'limits' => [
            'users' => 10,
            'storage_mb' => 1000,
        ],
    ],
    'enterprise' => [
        'name' => 'Enterprise',
        'price' => 99,
        'stripe_price_id' => env('STRIPE_ENTERPRISE_PRICE_ID'),
        'features' => ['basic_features', 'advanced_reports', 'api_access', 'white_label', 'priority_support'],
        'limits' => [
            'users' => -1, // unlimited
            'storage_mb' => 10000,
        ],
    ],
];
```

## Tenant Onboarding

```php
class TenantRegistrationController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'company' => 'required|string|max:255',
            'subdomain' => 'required|alpha_dash|unique:tenants,id',
            'name' => 'required|string|max:255',
            'email' => 'required|email',
            'password' => 'required|min:8|confirmed',
            'plan' => 'required|in:free,pro,enterprise',
        ]);

        $tenant = Tenant::create([
            'id' => $validated['subdomain'],
            'name' => $validated['company'],
            'email' => $validated['email'],
            'plan' => $validated['plan'],
        ]);

        $tenant->domains()->create([
            'domain' => $validated['subdomain'] . '.' . config('app.domain'),
        ]);

        // Run tenant migrations
        $tenant->run(function () use ($validated) {
            User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'role' => 'admin',
            ]);
        });

        // Subscribe to plan if paid
        if ($validated['plan'] !== 'free') {
            return redirect()->route('checkout', ['tenant' => $tenant->id]);
        }

        return redirect("https://{$tenant->id}." . config('app.domain') . "/login");
    }
}
```

## Feature Flags per Tenant

```php
// app/Features/AdvancedReports.php
class AdvancedReports
{
    public function resolve(Tenant $tenant): bool
    {
        return $tenant->hasFeature('advanced_reports');
    }
}

// Usage
if (Feature::for(tenant())->active(AdvancedReports::class)) {
    // Show advanced reports
}
```

## Central Admin (Filament)

```php
// app/Filament/Admin/Resources/TenantResource.php
class TenantResource extends Resource
{
    protected static ?string $model = Tenant::class;

    public static function form(Form $form): Form
    {
        return $form->schema([
            TextInput::make('id')->label('Subdomain')->required(),
            TextInput::make('name')->required(),
            TextInput::make('email')->email()->required(),
            Select::make('plan')
                ->options(collect(config('plans'))->pluck('name', 'key'))
                ->required(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table->columns([
            TextColumn::make('id')->label('Subdomain'),
            TextColumn::make('name'),
            TextColumn::make('plan')->badge(),
            TextColumn::make('created_at')->dateTime(),
        ])->actions([
            Action::make('impersonate')
                ->url(fn (Tenant $tenant) => "https://{$tenant->id}." . config('app.domain'))
                ->openUrlInNewTab(),
        ]);
    }
}
```

## Tenant Context Helpers

```php
// Get current tenant
$tenant = tenant();

// Run in tenant context
tenancy()->initialize($tenant);

// Run code for a specific tenant
$tenant->run(function () {
    // This runs in tenant's database context
    User::create([...]);
});

// Run for all tenants
Tenant::all()->runForEach(function () {
    // Runs for each tenant
});
```

## Artisan Commands

```bash
# Create tenant
php artisan tenants:create acme --domain=acme.yourapp.com

# Run migrations for all tenants
php artisan tenants:migrate

# Run migrations for specific tenant
php artisan tenants:migrate --tenants=acme

# Seed all tenants
php artisan tenants:seed

# Run artisan command for tenant
php artisan tenants:run cache:clear --tenants=acme
```

## Slash Commands

- `/tenant:create` - Create new tenant
- `/tenant:migrate` - Run tenant migrations
- `/feature:make TenantFeature` - Create tenant-scoped feature
- `/billing:setup` - Configure Stripe billing
