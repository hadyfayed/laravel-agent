---
name: package-make
description: Scaffold a reusable Laravel package with proper structure, service provider, config/facade publishing, tests, and Packagist release setup—when building a distributable Laravel package.
disable-model-invocation: true
allowed-tools: Bash(composer *) Read Write Edit
argument-hint: "<VendorName>/<PackageName> [--with-migrations] [--with-commands]"
---

## Task

Scaffold a complete, production-ready Laravel package skeleton using the Spatie package standards.

Input format:
```
Vendor: <vendor-name>
Package: <package-name>
Spec: <description of what the package does>
Options: --with-migrations, --with-commands
```

## Steps

1. **Create base directory structure**
   ```bash
   mkdir -p packages/<vendor>/<package-name>/{src,config,database/{migrations,factories},resources/views,routes,tests/{Feature,Unit},.github/workflows}
   ```

2. **Generate `composer.json`**
   - Set `type: library`, autoload PSR-4 to `Vendor\PackageName\src`
   - Require: `php ^8.2`, `illuminate/support ^10.0|^11.0`
   - Require-dev: `orchestra/testbench`, `pestphp/pest`, `phpstan/phpstan`, `laravel/pint`
   - Add script aliases: `test`, `test:coverage`, `analyse`, `format`

3. **Create ServiceProvider** (`src/<PackageName>ServiceProvider.php`)
   - Register config merging, singleton bindings, console commands (if applicable)
   - Boot: publish config, migrations, views; load all assets
   - See: `${CLAUDE_SKILL_DIR}/references/service-provider-and-publishing.md`

4. **Create Facade** (`src/Facades/<PackageName>.php`)
   - Proxy to singleton registered in ServiceProvider

5. **Create config file** (`config/<package-name>.php`)
   - Return associative array with sensible defaults

6. **Add TestCase base class** (`tests/TestCase.php`)
   - Extend `Orchestra\Testbench\TestCase`
   - Include package providers, aliases, environment setup
   - See: `${CLAUDE_SKILL_DIR}/references/testing-and-release.md`

7. **Create GitHub Actions workflow** (if `--with-migrations`)
   - Test matrix: PHP 8.2/8.3, Laravel 10/11
   - Jobs: tests, code-style (Pint), static-analysis (PHPStan)
   - See: `${CLAUDE_SKILL_DIR}/references/testing-and-release.md`

8. **Add database skeleton** (if `--with-migrations`)
   - Create sample migration in `database/migrations/`
   - Create factory boilerplate in `database/factories/`

9. **Add command scaffold** (if `--with-commands`)
   - Create `src/Commands/` directory with example InstallCommand

10. **Generate README.md**, `LICENSE.md`, `CHANGELOG.md`
    - Installation via Composer, publishing assets
    - Usage example via Facade or service binding
    - Testing and development workflow

## Structure Reference

See `${CLAUDE_SKILL_DIR}/references/package-structure.md` for the complete directory tree.

## Testing and CI

Follow `${CLAUDE_SKILL_DIR}/references/testing-and-release.md` for:
- Testbench configuration
- Pest test patterns
- GitHub Actions setup
- Packagist release workflow

## Success Criteria

- All files created with no stubs
- ServiceProvider auto-discovered in `composer.json` extra
- Tests runnable via `composer test`
- Code passes `composer analyse` and `composer format`
- README includes installation and usage examples
