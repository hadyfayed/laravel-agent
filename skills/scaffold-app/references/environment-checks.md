# Environment Checks & Package-Specific Guidance

## Phase 0: Environment Check

```bash
# Check for Laravel Boost MCP
composer show laravel/boost 2>/dev/null && echo "BOOST=yes" || echo "BOOST=no"

# Check for key packages - Architecture & Structure
composer show nwidart/laravel-modules 2>/dev/null && echo "NWIDART_MODULES=yes" || echo "NWIDART_MODULES=no"
composer show lorisleiva/laravel-actions 2>/dev/null && echo "LARAVEL_ACTIONS=yes" || echo "LARAVEL_ACTIONS=no"
composer show spatie/laravel-package-tools 2>/dev/null && echo "PACKAGE_TOOLS=yes" || echo "PACKAGE_TOOLS=no"

# Check for key packages - Performance & Development
composer show laravel/octane 2>/dev/null && echo "OCTANE=yes" || echo "OCTANE=no"
composer show barryvdh/laravel-ide-helper 2>/dev/null && echo "IDE_HELPER=yes" || echo "IDE_HELPER=no"
composer show barryvdh/laravel-debugbar 2>/dev/null && echo "DEBUGBAR=yes" || echo "DEBUGBAR=no"
composer show laravel/tinker 2>/dev/null && echo "TINKER=yes" || echo "TINKER=no"

# Check for key packages - Database & Code Quality
composer show kitloong/laravel-migrations-generator 2>/dev/null && echo "MIGRATIONS_GENERATOR=yes" || echo "MIGRATIONS_GENERATOR=no"
composer show laravel/pint 2>/dev/null && echo "PINT=yes" || echo "PINT=no"

# Check Laravel version for prompts support (10.17+)
php artisan --version 2>/dev/null

# Check project structure
ls -la app/ 2>/dev/null
ls -la app/Features/ 2>/dev/null || echo "No Features dir"
ls -la app/Modules/ 2>/dev/null || echo "No Modules dir"
ls -la Modules/ 2>/dev/null || echo "No nwidart Modules dir"
ls -la packages/ 2>/dev/null || echo "No packages dir"
ls -la .ai/patterns/registry.json 2>/dev/null || echo "No pattern registry"
```

## nwidart/laravel-modules Package

Use the nwidart module structure instead of app/Modules/:

```
Modules/<ModuleName>/
├── Config/
├── Database/Migrations/, Factories/, Seeders/
├── Entities/ (Models)
├── Http/Controllers/, Middleware/, Requests/
├── Providers/<ModuleName>ServiceProvider.php
├── Resources/views/
├── Routes/web.php, api.php
├── Tests/
└── module.json
```

**Commands available:**
```bash
php artisan module:make <Name>
php artisan module:make-controller
php artisan module:make-model
php artisan module:migrate
```

## lorisleiva/laravel-actions Package

Use the AsAction pattern for single-purpose operations:

```php
use Lorisleiva\Actions\Concerns\AsAction;

class CreateOrder
{
    use AsAction;

    public function handle(User $user, array $data): Order
    {
        return Order::create([...]);
    }

    // Can also run as controller, job, listener, command
    public function asController(Request $request): Order
    {
        return $this->handle($request->user(), $request->validated());
    }
}
```

## laravel/octane Package

If `laravel/octane` is installed, apply Octane-safe practices:
- Avoid static state that persists between requests
- Don't store request-specific data in singletons
- Use `Octane::concurrently()` for parallel operations
- Be careful with `app()` resolved singletons

## laravel/tinker Package

Use for quick prototyping and debugging:

```bash
php artisan tinker
>>> User::factory()->create()
>>> Order::with('products')->find(1)
>>> app(OrderService::class)->process($order)
```

## spatie/laravel-package-tools Package

Available for creating distributable packages with:
- Automatic config publishing
- Migration management
- View registration
- Command registration
- Install command with GitHub star prompt

## laravel/prompts Package

If `laravel/prompts` is installed (Laravel 10.17+), use beautiful CLI prompts:

```php
use function Laravel\Prompts\{select, confirm, progress, spin};
```

## spatie/laravel-health Package

Set up application health monitoring:

```php
// app/Providers/HealthServiceProvider.php
use Spatie\Health\Facades\Health;
use Spatie\Health\Checks\Checks\{
    DatabaseCheck,
    CacheCheck,
    UsedDiskSpaceCheck,
    QueueCheck,
    RedisCheck,
    ScheduleCheck,
};

Health::checks([
    UsedDiskSpaceCheck::new()
        ->warnWhenUsedSpaceIsAbovePercentage(70)
        ->failWhenUsedSpaceIsAbovePercentage(90),
    DatabaseCheck::new(),
    CacheCheck::new(),
    QueueCheck::new(),
    RedisCheck::new(),
    ScheduleCheck::new()->heartbeatMaxAgeInMinutes(5),
]);
```

## bref/laravel-bridge Package (Serverless)

Deploy Laravel to AWS Lambda:

```yaml
# serverless.yml
service: laravel-app

provider:
    name: aws
    region: us-east-1
    runtime: provided.al2

plugins:
    - ./vendor/bref/bref

functions:
    web:
        handler: public/index.php
        runtime: php-83-fpm
        timeout: 28
        events:
            - httpApi: '*'
    artisan:
        handler: artisan
        runtime: php-83-console
        timeout: 720

package:
    patterns:
        - '!node_modules/**'
        - '!tests/**'
```

**Bref Considerations:**
- Use S3 for file storage (local filesystem is ephemeral)
- Use SQS for queues instead of database/Redis
- Use DynamoDB or RDS for sessions
- Cold starts: keep functions warm or use provisioned concurrency

## laravel/cashier Package

Available for Stripe subscription billing with:
- Subscription management (create, swap, cancel, resume)
- Invoice generation and PDF downloads
- Webhook handling
- Stripe Checkout integration

## spatie/laravel-backup Package

Configure automated backups:

```php
// config/backup.php
return [
    'backup' => [
        'name' => env('APP_NAME', 'laravel-backup'),
        'source' => [
            'files' => [
                'include' => [base_path()],
                'exclude' => [
                    base_path('vendor'),
                    base_path('node_modules'),
                    storage_path(),
                ],
            ],
            'databases' => ['mysql'],
        ],
        'destination' => [
            'disks' => ['s3'], // or 'local' for development
        ],
    ],
    'notifications' => [
        'notifications' => [
            \Spatie\Backup\Notifications\Notifications\BackupHasFailed::class => ['mail', 'slack'],
            \Spatie\Backup\Notifications\Notifications\BackupWasSuccessful::class => ['slack'],
        ],
        'notifiable' => \Spatie\Backup\Notifications\Notifiable::class,
        'mail' => ['to' => 'admin@example.com'],
        'slack' => ['webhook_url' => env('SLACK_WEBHOOK_URL')],
    ],
    'monitor_backups' => [
        ['name' => env('APP_NAME'), 'disks' => ['s3'], 'health_checks' => [
            \Spatie\Backup\Tasks\Monitor\HealthChecks\MaximumAgeInDays::class => 1,
            \Spatie\Backup\Tasks\Monitor\HealthChecks\MaximumStorageInMegabytes::class => 5000,
        ]],
    ],
];
```

**Backup Commands:**
```bash
php artisan backup:run
php artisan backup:run --only-db
php artisan backup:clean
php artisan backup:monitor
php artisan backup:list
```

**Schedule in Kernel:**
```php
// app/Console/Kernel.php
protected function schedule(Schedule $schedule)
{
    $schedule->command('backup:clean')->daily()->at('01:00');
    $schedule->command('backup:run')->daily()->at('02:00');
    $schedule->command('backup:monitor')->daily()->at('03:00');
}
```

## laravel/telescope Package

Debugging and introspection dashboard:
- Requests, queries, models, events, mail, notifications
- Jobs, cache, dumps, logs, scheduled tasks
- Gate checks, HTTP client requests

```php
// Authorize dashboard access
Telescope::auth(function ($request) {
    return $request->user()?->hasRole('admin') ?? false;
});
```

## stancl/tenancy Package (Multi-Tenancy)

Full multi-tenant application support:

```php
// config/tenancy.php
'tenant_model' => \App\Models\Tenant::class,
'id_generator' => Stancl\Tenancy\UUIDGenerator::class,

'central_domains' => [
    'admin.' . env('APP_DOMAIN'),
    env('APP_DOMAIN'),
],
```

**Tenant Model:**
```php
use Stancl\Tenancy\Database\Models\Tenant as BaseTenant;
use Stancl\Tenancy\Contracts\TenantWithDatabase;
use Stancl\Tenancy\Database\Concerns\HasDatabase;
use Stancl\Tenancy\Database\Concerns\HasDomains;

class Tenant extends BaseTenant implements TenantWithDatabase
{
    use HasDatabase, HasDomains;

    public static function getCustomColumns(): array
    {
        return ['id', 'name', 'email', 'plan'];
    }
}
```

**Tenant Routes:**
```php
// routes/tenant.php
Route::middleware(['web', 'tenant'])->group(function () {
    Route::get('/dashboard', DashboardController::class);
});
```

**Run Tenant Commands:**
```bash
php artisan tenants:create acme --domain=acme.yourapp.com
php artisan tenants:migrate
php artisan tenants:seed
```

## spatie/laravel-translatable Package (Localization)

Multi-language content support:

```php
use Spatie\Translatable\HasTranslations;

class Product extends Model
{
    use HasTranslations;

    public array $translatable = ['name', 'description'];
}

// Usage
$product->setTranslation('name', 'en', 'Product Name');
$product->setTranslation('name', 'ar', 'اسم المنتج');
$product->save();

// Get translation
$product->getTranslation('name', 'ar'); // اسم المنتج
app()->setLocale('ar');
$product->name; // اسم المنتج
```
