# Service Provider and Publishing

## Service Provider Template

```php
<?php

declare(strict_types=1);

namespace Vendor\PackageName;

use Illuminate\Support\ServiceProvider;

final class PackageNameServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Merge config
        $this->mergeConfigFrom(
            __DIR__ . '/../config/package-name.php',
            'package-name'
        );

        // Register bindings
        $this->app->singleton('package-name', function ($app) {
            return new PackageNameManager(
                $app['config']['package-name']
            );
        });

        // Register commands
        if ($this->app->runningInConsole()) {
            $this->commands([
                Commands\InstallCommand::class,
                Commands\PublishCommand::class,
            ]);
        }
    }

    public function boot(): void
    {
        // Publish config
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__ . '/../config/package-name.php' => config_path('package-name.php'),
            ], 'package-name-config');

            // Publish migrations
            $this->publishes([
                __DIR__ . '/../database/migrations' => database_path('migrations'),
            ], 'package-name-migrations');

            // Publish views
            $this->publishes([
                __DIR__ . '/../resources/views' => resource_path('views/vendor/package-name'),
            ], 'package-name-views');
        }

        // Load migrations
        $this->loadMigrationsFrom(__DIR__ . '/../database/migrations');

        // Load routes
        $this->loadRoutesFrom(__DIR__ . '/../routes/web.php');

        // Load views
        $this->loadViewsFrom(__DIR__ . '/../resources/views', 'package-name');

        // Register helpers
        if (file_exists(__DIR__ . '/helpers.php')) {
            require __DIR__ . '/helpers.php';
        }
    }
}
```

## Facade Pattern

```php
<?php

declare(strict_types=1);

namespace Vendor\PackageName\Facades;

use Illuminate\Support\Facades\Facade;

/**
 * @method static mixed doSomething(string $param)
 * @method static void configure(array $options)
 *
 * @see \Vendor\PackageName\PackageNameManager
 */
final class PackageName extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return 'package-name';
    }
}
```

## Publishing Steps

Registered via `php artisan vendor:publish`:

- `--tag="package-name-config"` — publishes config file
- `--tag="package-name-migrations"` — publishes database migrations
- `--tag="package-name-views"` — publishes Blade templates
