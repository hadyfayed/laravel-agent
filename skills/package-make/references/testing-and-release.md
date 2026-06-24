# Testing and Release

## Testbench Setup

```php
<?php

declare(strict_types=1);

namespace Vendor\PackageName\Tests;

use Orchestra\Testbench\TestCase as Orchestra;
use Vendor\PackageName\PackageNameServiceProvider;

abstract class TestCase extends Orchestra
{
    protected function setUp(): void
    {
        parent::setUp();

        // Run migrations
        $this->loadMigrationsFrom(__DIR__ . '/../database/migrations');
    }

    protected function getPackageProviders($app): array
    {
        return [
            PackageNameServiceProvider::class,
        ];
    }

    protected function getPackageAliases($app): array
    {
        return [
            'PackageName' => \Vendor\PackageName\Facades\PackageName::class,
        ];
    }

    protected function defineEnvironment($app): void
    {
        $app['config']->set('database.default', 'testing');
        $app['config']->set('database.connections.testing', [
            'driver' => 'sqlite',
            'database' => ':memory:',
            'prefix' => '',
        ]);

        // Set package config
        $app['config']->set('package-name.option', 'value');
    }

    protected function defineDatabaseMigrations(): void
    {
        $this->loadMigrationsFrom(__DIR__ . '/../database/migrations');
    }
}
```

## Pest Test Example

```php
<?php

declare(strict_types=1);

use Vendor\PackageName\Facades\PackageName;

it('can do something', function () {
    $result = PackageName::doSomething('test');

    expect($result)->toBe('expected');
});

it('has correct config', function () {
    expect(config('package-name.option'))->toBe('value');
});

it('registers the facade', function () {
    expect(app('package-name'))->toBeInstanceOf(
        \Vendor\PackageName\PackageNameManager::class
    );
});
```

## GitHub Actions Workflow

```yaml
# .github/workflows/tests.yml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        php: [8.2, 8.3]
        laravel: [10.*, 11.*]
        include:
          - laravel: 10.*
            testbench: 8.*
          - laravel: 11.*
            testbench: 9.*

    name: P${{ matrix.php }} - L${{ matrix.laravel }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: dom, curl, libxml, mbstring, zip, pcntl, pdo, sqlite, pdo_sqlite
          coverage: none

      - name: Install dependencies
        run: |
          composer require "laravel/framework:${{ matrix.laravel }}" "orchestra/testbench:${{ matrix.testbench }}" --no-interaction --no-update
          composer update --prefer-stable --prefer-dist --no-interaction

      - name: Run tests
        run: vendor/bin/pest

  code-style:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: 8.3

      - name: Install dependencies
        run: composer install --no-interaction

      - name: Check code style
        run: vendor/bin/pint --test

  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: 8.3

      - name: Install dependencies
        run: composer install --no-interaction

      - name: Run PHPStan
        run: vendor/bin/phpstan analyse
```

## Publishing to Packagist

1. Create a public GitHub repository
2. Push code with initial commit and tag (`v1.0.0`)
3. Register at https://packagist.org/packages/submit with GitHub repo URL
4. Packagist provides webhook URL; add to GitHub repo settings for auto-updates
5. Future tags trigger automatic updates on Packagist
