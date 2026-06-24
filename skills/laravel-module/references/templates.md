# Laravel Module Templates

## Package Structure (spatie/laravel-package-tools)

```
packages/<vendor>/<package-name>/
├── src/
│   ├── <PackageName>ServiceProvider.php
│   ├── Facades/<PackageName>.php
│   ├── Commands/<PackageName>Command.php
│   ├── <PackageName>.php (Main class)
│   └── ... (your module files)
├── config/<package-name>.php
├── database/migrations/
├── resources/views/
├── routes/web.php
├── tests/
│   ├── TestCase.php
│   └── ExampleTest.php
├── composer.json
├── LICENSE.md
└── README.md
```

## Service Provider with Package Tools

```php
<?php

namespace Vendor\PackageName;

use Spatie\LaravelPackageTools\Package;
use Spatie\LaravelPackageTools\PackageServiceProvider;
use Spatie\LaravelPackageTools\Commands\InstallCommand;

class PackageNameServiceProvider extends PackageServiceProvider
{
    public function configurePackage(Package $package): void
    {
        $package
            ->name('package-name')
            ->hasConfigFile()
            ->hasViews()
            ->hasMigration('create_package_table')
            ->hasCommand(PackageNameCommand::class)
            ->hasInstallCommand(function (InstallCommand $command) {
                $command
                    ->publishConfigFile()
                    ->publishMigrations()
                    ->askToRunMigrations()
                    ->copyAndRegisterServiceProviderInApp()
                    ->askToStarRepoOnGitHub('vendor/package-name');
            });
    }

    public function packageRegistered(): void
    {
        // Bind services
        $this->app->singleton('package-name', fn () => new PackageName());
    }

    public function packageBooted(): void
    {
        // Register routes, events, etc.
    }
}
```

## Package composer.json

```json
{
    "name": "vendor/package-name",
    "description": "Your package description",
    "keywords": ["laravel", "your-keywords"],
    "license": "MIT",
    "require": {
        "php": "^8.1",
        "spatie/laravel-package-tools": "^1.14",
        "illuminate/contracts": "^10.0|^11.0"
    },
    "require-dev": {
        "orchestra/testbench": "^8.0|^9.0",
        "pestphp/pest": "^2.0"
    },
    "autoload": {
        "psr-4": {
            "Vendor\\PackageName\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Vendor\\PackageName\\Tests\\": "tests/"
        }
    },
    "extra": {
        "laravel": {
            "providers": [
                "Vendor\\PackageName\\PackageNameServiceProvider"
            ],
            "aliases": {
                "PackageName": "Vendor\\PackageName\\Facades\\PackageName"
            }
        }
    },
    "minimum-stability": "dev",
    "prefer-stable": true
}
```

## Package TestCase

```php
<?php

namespace Vendor\PackageName\Tests;

use Orchestra\Testbench\TestCase as Orchestra;
use Vendor\PackageName\PackageNameServiceProvider;

class TestCase extends Orchestra
{
    protected function getPackageProviders($app): array
    {
        return [PackageNameServiceProvider::class];
    }

    protected function defineEnvironment($app): void
    {
        $app['config']->set('database.default', 'testing');
    }
}
```

## Contract

```php
<?php

declare(strict_types=1);

namespace App\Modules\<Name>\Contracts;

interface <Name>ServiceInterface
{
    // Define public API
}
```

## Service

```php
<?php

declare(strict_types=1);

namespace App\Modules\<Name>\Services;

use App\Modules\<Name>\Contracts\<Name>ServiceInterface;

final class <Name>Service implements <Name>ServiceInterface
{
    public function __construct(
        // Inject dependencies
    ) {}

    // Implement interface
    // Keep methods < 20 lines
}
```

## DTO

```php
<?php

declare(strict_types=1);

namespace App\Modules\<Name>\DTOs;

final readonly class <Name>Data
{
    public function __construct(
        public string $field1,
        public int $field2,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            field1: $data['field1'],
            field2: $data['field2'],
        );
    }

    public function toArray(): array
    {
        return [
            'field1' => $this->field1,
            'field2' => $this->field2,
        ];
    }
}
```

## Strategy Pattern

```php
// Interface
interface <Strategy>Interface
{
    public function execute(mixed $input): mixed;
}

// Concrete
final class Concrete<Strategy> implements <Strategy>Interface
{
    public function execute(mixed $input): mixed
    {
        // Implementation
    }
}
```

## ServiceProvider

```php
<?php

declare(strict_types=1);

namespace App\Modules\<Name>;

use App\Modules\<Name>\Contracts\<Name>ServiceInterface;
use App\Modules\<Name>\Services\<Name>Service;
use Illuminate\Support\ServiceProvider;

final class <Name>ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(<Name>ServiceInterface::class, <Name>Service::class);
    }
}
```

## Pest Tests

```php
<?php

use App\Modules\<Name>\Contracts\<Name>ServiceInterface;

describe('<Name> Module', function () {
    beforeEach(fn () => $this->service = app(<Name>ServiceInterface::class));

    it('performs core operation', function () {
        $result = $this->service->method($input);
        expect($result)->toBe($expected);
    });

    it('handles edge cases', function () {
        // Test boundaries
    });

    it('throws on invalid input', function () {
        expect(fn () => $this->service->method(null))
            ->toThrow(InvalidArgumentException::class);
    });
});
```
