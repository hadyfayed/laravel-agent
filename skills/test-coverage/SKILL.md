---
name: test-coverage
description: Run and report test coverage (Pest/PHPUnit), identify gaps, enforce thresholds; when checking coverage.
disable-model-invocation: true
allowed-tools: Bash(vendor/bin/pest *) Bash(php artisan test *) Read
argument-hint: "[min-coverage] [format]"
---

## Current coverage

!`vendor/bin/pest --coverage 2>&1 | tail -20 || php artisan test --coverage 2>&1 | tail -20 || echo "Coverage driver not configured"`

## Task

Run tests with coverage analysis and report results.

1. **Check environment**
   - Verify Xdebug or PCOV is available
   - Confirm `vendor/bin/pest` or `vendor/bin/phpunit` exists

2. **Run tests with coverage**

   **Pest (preferred):**
   ```bash
   vendor/bin/pest --coverage --min=$ARGUMENTS[0] --coverage-html=storage/coverage
   ```

   **PHPUnit:**
   ```bash
   vendor/bin/phpunit --coverage-text --coverage-html=storage/coverage
   ```

3. **Analyze results**
   - Extract summary (Lines, Functions, Classes coverage %)
   - Identify uncovered files below threshold
   - Extract recommendations for missing tests

4. **Report**

   ```markdown
   ## Coverage Report

   ### Summary
   - Lines: X%
   - Functions: Y%
   - Classes: Z%

   ### Uncovered Files
   | File | Coverage | Gap |
   |------|----------|-----|
   | ... | ... | ... |

   ### Recommendations
   - List top priority gaps
   - Suggest tests for critical paths
   ```

5. **Set threshold** (default 80%)
   - Pass `[min-coverage]` argument to enforce stricter standard
   - Fail CI if below threshold

## See also

- `laravel-testing` reference skill for test patterns
- PCOV installation: `composer require --dev pcov/clobber`
- Xdebug config: `xdebug.mode=coverage`
