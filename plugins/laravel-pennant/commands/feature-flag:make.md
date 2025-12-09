---
description: "Create a feature flag with Pennant"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /feature-flag:make - Create Feature Flag

Generate a feature flag class with Laravel Pennant.

## Input
$ARGUMENTS = `<FeatureName> [type] [specification]`

Examples:
- `/feature-flag:make NewDashboard` - Simple boolean
- `/feature-flag:make PricingVariant ab-test` - A/B test with variants
- `/feature-flag:make BetaFeatures segment beta-users` - User segment
- `/feature-flag:make GradualRollout percentage 25` - 25% rollout

## Types
- `boolean` - Simple on/off (default)
- `ab-test` - Multiple variants (A/B/C testing)
- `percentage` - Gradual percentage rollout
- `segment` - User/team segment based
- `subscription` - Based on subscription plan

## Process

1. **Check Pennant Installation**
   ```bash
   composer show laravel/pennant 2>/dev/null && echo "PENNANT=yes" || echo "PENNANT=no"
   ```

2. **Parse Arguments**
   - Feature name
   - Type of feature
   - Additional specification

3. **Invoke Pennant Agent**
   ```
   Create feature flag:

   Action: create
   Name: <FeatureName>
   Type: <boolean|ab-test|percentage|segment|subscription>
   Spec: <additional details>
   ```

4. **Files Created**
   - app/Features/<FeatureName>.php

5. **Report Results**
   ```markdown
   ## Feature Flag Created: <FeatureName>

   ### Location
   app/Features/<FeatureName>.php

   ### Type
   <description of resolution logic>

   ### Usage
   ```php
   // Controller
   if (Feature::active(<FeatureName>::class)) {
       // Feature enabled
   }

   // Blade
   @feature(App\Features\<FeatureName>::class)
       <!-- Feature content -->
   @endfeature
   ```

   ### Management
   ```php
   // Activate for everyone
   Feature::activateForEveryone(<FeatureName>::class);

   // Activate for specific user
   Feature::for($user)->activate(<FeatureName>::class);
   ```

   ### Test
   ```bash
   vendor/bin/pest --filter=<FeatureName>
   ```
   ```

## Examples

| Command | Type | Resolution |
|---------|------|------------|
| `/feature-flag:make NewUI` | boolean | Always true/false |
| `/feature-flag:make PricingPage ab-test` | A/B | Random variant |
| `/feature-flag:make NewCheckout percentage 10` | Percentage | 10% of users |
| `/feature-flag:make ProFeatures subscription pro` | Subscription | Pro plan users |
