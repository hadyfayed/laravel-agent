# Laravel Package Structure

## Standard Directory Layout

```
packages/<vendor>/<package-name>/
├── src/
│   ├── <PackageName>ServiceProvider.php
│   ├── Facades/
│   │   └── <PackageName>.php
│   ├── Commands/
│   ├── Contracts/
│   ├── Exceptions/
│   ├── Http/
│   │   ├── Controllers/
│   │   └── Middleware/
│   ├── Models/
│   ├── Services/
│   └── helpers.php
├── config/
│   └── <package-name>.php
├── database/
│   ├── migrations/
│   └── factories/
├── resources/
│   └── views/
├── routes/
│   └── web.php
├── tests/
│   ├── Feature/
│   ├── Unit/
│   └── TestCase.php
├── .github/
│   └── workflows/
│       └── tests.yml
├── composer.json
├── LICENSE.md
├── README.md
├── CHANGELOG.md
└── phpunit.xml
```

## Key Principles

- Use PSR-4 autoloading with `Vendor\PackageName` namespace
- Separate concerns: Contracts/Interfaces, Services, Facades
- Config files publishable via `php artisan vendor:publish`
- Include test boilerplate (TestCase, Pest setup)
- GitHub Actions for CI/CD (PHP 8.2, 8.3; Laravel 10, 11)
