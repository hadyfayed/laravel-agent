# Testing Feature Flags with Pennant

## Unit Tests

Test feature activation and deactivation.

```php
<?php

use App\Features\NewDashboard;
use App\Models\User;
use Laravel\Pennant\Feature;

it('shows new dashboard when feature is active', function () {
    $user = User::factory()->create();

    Feature::for($user)->activate(NewDashboard::class);

    $this->actingAs($user)
        ->get('/dashboard')
        ->assertViewIs('dashboard.new');
});

it('shows old dashboard when feature is inactive', function () {
    $user = User::factory()->create();

    Feature::for($user)->deactivate(NewDashboard::class);

    $this->actingAs($user)
        ->get('/dashboard')
        ->assertViewIs('dashboard.index');
});

it('activates feature for beta users', function () {
    $betaUser = User::factory()->create(['is_beta_tester' => true]);
    $normalUser = User::factory()->create(['is_beta_tester' => false]);

    expect(Feature::for($betaUser)->active(BetaFeatures::class))->toBeTrue();
    expect(Feature::for($normalUser)->active(BetaFeatures::class))->toBeFalse();
});
```

## Array Driver for Tests

Use the array driver in test config to avoid database pollution.

```php
// In phpunit.xml or test configuration
'default' => env('PENNANT_STORE', 'array'),
```

## Feature Factory

Define test features inline.

```php
beforeEach(function () {
    Feature::define('test-feature', fn () => true);
    Feature::define('disabled-feature', fn () => false);
});
```

## Running Tests

```bash
vendor/bin/pest --filter=NewDashboard
vendor/bin/phpunit tests/Feature/DashboardTest.php
```
