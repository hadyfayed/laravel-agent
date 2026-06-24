# Feature Flag Types & Patterns

## Simple Boolean Feature

Used for on/off features with no scoping.

```php
<?php

declare(strict_types=1);

namespace App\Features;

final class NewDashboard
{
    /**
     * Resolve the feature's initial value.
     */
    public function resolve(mixed $scope): bool
    {
        // Always enabled
        return true;

        // Always disabled
        return false;

        // Percentage rollout
        return Lottery::odds(1, 10)->choose(); // 10%
    }
}
```

## User-Based Feature

Conditional logic based on a User scope.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;

final class BetaFeatures
{
    public function resolve(User $user): bool
    {
        // Beta users only
        return $user->is_beta_tester;
    }
}
```

## Subscription-Based Feature

Restrict to subscription tier.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;

final class AdvancedReports
{
    public function resolve(User $user): bool
    {
        // Premium subscribers only
        return $user->subscribed('premium');
    }
}
```

## Team-Based Feature

Conditional logic on a Team or organization scope.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\Team;

final class TeamAnalytics
{
    public function resolve(Team $team): bool
    {
        // Enterprise teams only
        return $team->plan === 'enterprise';
    }
}
```

## Percentage Rollout

Gradual rollout to a percentage of users.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;
use Illuminate\Support\Lottery;

final class NewCheckoutFlow
{
    public function resolve(User $user): bool
    {
        // Gradual rollout: 25% of users
        return Lottery::odds(25, 100)->choose();
    }
}
```

## Rich Feature Values (A/B Testing)

Return a variant string for A/B or multi-variant testing.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;
use Illuminate\Support\Arr;

final class PricingPageVariant
{
    public function resolve(User $user): string
    {
        // A/B/C test with weighted distribution
        return Arr::random([
            'control',    // 50%
            'control',
            'variant-a',  // 25%
            'variant-b',  // 25%
        ]);
    }
}
```

## Multi-Condition Segment

Complex segment logic with multiple conditions.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;

final class EarlyAccess
{
    public function resolve(User $user): bool
    {
        // Multiple conditions
        return match (true) {
            $user->is_admin => true,
            $user->is_beta_tester => true,
            $user->created_at->lt(now()->subYear()) => true, // Early adopters
            $user->referral_count > 10 => true, // Power referrers
            default => false,
        };
    }
}
```
