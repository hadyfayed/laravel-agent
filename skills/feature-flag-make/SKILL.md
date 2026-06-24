---
name: feature-flag-make
description: Define a Laravel Pennant feature flag (class-based or simple), with scoping and rollout; when adding feature flags / A-B tests.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(php artisan *) Read Write Edit
argument-hint: "<FeatureName> [type] [specification]"
---

## Current context

!`ls -la app/Features/ 2>/dev/null || echo "No Features dir yet"`

## Task

Generate a Laravel Pennant feature flag class with the requested type and scoping.

## Input

- **FeatureName:** PascalCase class name (e.g., `NewDashboard`, `CheckoutVariant`)
- **Type:** Feature flag resolution logic (default: `boolean`)
  - `boolean` — Simple on/off
  - `ab-test` — Multiple variants (A/B/C testing with weighted distribution)
  - `percentage` — Gradual percentage rollout (e.g., 25% of users)
  - `segment` — User/team/subscription segment (conditional logic)
  - `subscription` — Subscription plan-based feature gating

- **Specification:** Scoping details (e.g., percentage value, segment condition, subscription tier)

## Steps

1. **Verify Pennant is installed:**
   ```bash
   composer show laravel/pennant 2>/dev/null || {
     echo "Pennant not found. Install with: composer require laravel/pennant"
     exit 1
   }
   ```

2. **Create app/Features directory if missing:**
   ```bash
   mkdir -p app/Features
   ```

3. **Generate the feature flag class** in `app/Features/<FeatureName>.php`:
   - Use the patterns in `${CLAUDE_SKILL_DIR}/references/feature-types.md`
   - **For `boolean`:** Simple true/false in `resolve(mixed $scope): bool`
   - **For `ab-test`:** Weighted variants using `Arr::random()` or lottery, return string variant name
   - **For `percentage`:** Use `Lottery::odds($percent, 100)->choose()` for gradual rollout
   - **For `segment`:** Match pattern on scope (User, Team, etc.), multiple conditions in `resolve()`
   - **For `subscription`:** Check subscription status on User scope

4. **Test the feature:**
   ```bash
   php artisan tinker
   ```
   Then in Tinker:
   ```php
   Feature::active(App\Features\<FeatureName>::class)
   ```

5. **Verify the class was created:**
   ```bash
   cat app/Features/<FeatureName>.php
   ```

## Reference material

For feature class patterns and rollout strategies, see:
- `${CLAUDE_SKILL_DIR}/references/feature-types.md` — class-based examples for each type
- `${CLAUDE_SKILL_DIR}/references/testing.md` — test patterns with Pennant
- `${CLAUDE_SKILL_DIR}/references/rollout-strategy.md` — phased & scheduled rollouts
