# Gradual Rollout Strategy

## Phased Rollout Approach

Roll out a feature in phases: internal → beta → percentage.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;
use Illuminate\Support\Lottery;

final class NewPaymentSystem
{
    private const ROLLOUT_PERCENTAGE = 25; // Increase over time

    public function resolve(User $user): bool
    {
        // Phase 1: Internal users
        if ($user->email && str_ends_with($user->email, '@yourcompany.com')) {
            return true;
        }

        // Phase 2: Beta testers
        if ($user->is_beta_tester) {
            return true;
        }

        // Phase 3: Percentage rollout
        return Lottery::odds(self::ROLLOUT_PERCENTAGE, 100)->choose();
    }
}
```

## Scheduled Rollout

Increase rollout percentage over time via a scheduler.

```php
// In app/Console/Kernel.php
$schedule->call(function () {
    // Increase rollout by 10% weekly
    $currentPercentage = cache()->get('new-payment-rollout', 10);
    $newPercentage = min(100, $currentPercentage + 10);
    cache()->put('new-payment-rollout', $newPercentage);

    Log::info("Feature rollout increased to {$newPercentage}%");
})->weekly();
```

Then use the cache value in your feature:

```php
public function resolve(User $user): bool
{
    $percentage = cache()->get('new-payment-rollout', 10);
    return Lottery::odds($percentage, 100)->choose();
}
```

## Common Rollout Timeline

- **Week 1:** 10% rollout
- **Week 2:** 25% rollout
- **Week 3:** 50% rollout
- **Week 4:** 100% rollout (full release)

## Monitoring & Safety

Always include logging and metrics:

```php
Log::info("Feature active for user", [
    'user_id' => $user->id,
    'feature' => NewPaymentSystem::class,
    'active' => true,
]);
```

## Fallback Behavior

Always provide fallback behavior when a feature is off:

```php
// In controller or view
Feature::when(
    NewPaymentSystem::class,
    fn () => $this->newPayment(),
    fn () => $this->legacyPayment(),
);
```
