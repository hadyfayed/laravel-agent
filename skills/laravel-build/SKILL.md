---
name: laravel-build
description: Run the full Laravel build and quality pipeline—Pint, PHPStan/Larastan, tests, asset build, optimization—as a one-shot quality gate before commit or deploy.
disable-model-invocation: true
allowed-tools: Bash(vendor/bin/*) Bash(php artisan *) Bash(npm *) Bash(composer *) Read
argument-hint: "[--no-test] [--no-assets]"
---

## Current build status

!`composer show > /dev/null 2>&1 && echo "Composer deps: installed" || echo "Composer deps: NOT installed"`
!`[ -d vendor ] && echo "Vendor: present" || echo "Vendor: NOT present"`
!`[ -f package.json ] && echo "Node deps: configured" || echo "Node deps: NOT configured"`

## Task

Execute the full build and quality pipeline in sequence:

1. **Composer Install** (if needed)
   ```bash
   composer install --no-interaction
   ```

2. **Code Format (Pint)**
   ```bash
   vendor/bin/pint
   ```
   Fix any style violations automatically.

3. **Static Analysis (PHPStan/Larastan)**
   ```bash
   vendor/bin/phpstan analyse
   ```
   Report any type or logic errors; do NOT proceed if this fails.

4. **Run Tests** (unless `--no-test` is passed)
   ```bash
   vendor/bin/pest
   ```
   All tests must pass. If failures occur, report them and stop.

5. **Asset Build** (if `package.json` exists and `--no-assets` not passed)
   ```bash
   npm install
   npm run build
   ```

6. **Optimization** (if Laravel app)
   ```bash
   php artisan optimize
   php artisan config:cache
   php artisan route:cache
   ```

## Success criteria

- All format checks pass (Pint clean)
- All static analysis passes (PHPStan clean)
- All tests pass (100% green)
- Assets built successfully (if applicable)
- Laravel caches updated

Report the final status and exit code.
