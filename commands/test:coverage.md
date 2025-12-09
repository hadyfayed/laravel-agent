---
description: "Run tests with coverage report"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /test:coverage - Test Coverage Report

Run tests and generate coverage report.

## Input
$ARGUMENTS = `[min-coverage] [format]`

Examples:
- `/test:coverage` - Run with default 80% minimum
- `/test:coverage 90` - Require 90% coverage
- `/test:coverage 80 html` - Generate HTML report

## Process

1. **Check Requirements**
   ```bash
   php -m | grep xdebug && echo "XDEBUG=yes" || echo "XDEBUG=no"
   php -m | grep pcov && echo "PCOV=yes" || echo "PCOV=no"
   ```

2. **Run Tests with Coverage**
   ```bash
   # Pest
   vendor/bin/pest --coverage --min=80

   # PHPUnit
   vendor/bin/phpunit --coverage-text --coverage-html=coverage
   ```

3. **Report Results**
   ```markdown
   ## Coverage Report

   ### Summary
   - Lines: 85.3%
   - Functions: 92.1%
   - Classes: 88.0%

   ### Uncovered Files
   | File | Coverage |
   |------|----------|
   | app/Services/PaymentService.php | 45% |
   | app/Actions/ProcessOrder.php | 62% |

   ### Recommendations
   1. Add tests for PaymentService::refund()
   2. Cover edge cases in ProcessOrder
   ```

## Coverage Drivers

### PCOV (Recommended)
Faster than Xdebug for coverage-only:
```bash
composer require --dev pcov/clobber
```

### Xdebug
Full debugging + coverage:
```ini
xdebug.mode=coverage
```
