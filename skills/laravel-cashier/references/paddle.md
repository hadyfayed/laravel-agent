# Laravel Cashier Paddle Reference

Paddle-specific installation, configuration, Billable model, and webhook handling for Laravel Cashier.

## Installation

```bash
# Cashier for Paddle
composer require laravel/cashier-paddle
php artisan vendor:publish --tag="cashier-paddle-migrations"
php artisan migrate
```

## Environment Variables (Paddle)

```env
PADDLE_VENDOR_ID=your-vendor-id
PADDLE_VENDOR_AUTH_CODE=your-auth-code
PADDLE_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----..."
PADDLE_SANDBOX=true
```

## Billable Model Setup (Paddle)

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Cashier\Billable;

final class User extends Authenticatable
{
    use Billable;

    /**
     * Get the Stripe customer email.
     */
    public function stripeEmail(): ?string
    {
        return $this->email;
    }

    /**
     * Get the Stripe customer name.
     */
    public function stripeName(): ?string
    {
        return $this->name;
    }

    /**
     * Check if user has active subscription.
     */
    public function hasActiveSubscription(): bool
    {
        return $this->subscribed('default');
    }

    /**
     * Check if user is on trial.
     */
    public function isOnTrial(): bool
    {
        return $this->subscription('default')?->onTrial() ?? false;
    }

    /**
     * Get current plan name.
     */
    public function currentPlan(): ?string
    {
        $subscription = $this->subscription('default');

        if (!$subscription) {
            return null;
        }

        return match ($subscription->stripe_price) {
            config('cashier.prices.monthly') => 'Monthly',
            config('cashier.prices.yearly') => 'Yearly',
            default => 'Custom',
        };
    }
}
```

## Configuration

```php
<?php

// config/cashier.php
return [
    'key' => env('STRIPE_KEY'),
    'secret' => env('STRIPE_SECRET'),
    'webhook' => [
        'secret' => env('STRIPE_WEBHOOK_SECRET'),
        'tolerance' => env('STRIPE_WEBHOOK_TOLERANCE', 300),
    ],
    'currency' => 'usd',
    'currency_locale' => 'en',
    'logger' => env('CASHIER_LOGGER'),

    // Custom: Price IDs
    'prices' => [
        'monthly' => env('STRIPE_PRICE_MONTHLY'),
        'yearly' => env('STRIPE_PRICE_YEARLY'),
    ],
];
```

## CSRF Exception for Webhooks

Paddle webhooks, like Stripe webhooks, must bypass CSRF verification:

```php
// app/Http/Middleware/VerifyCsrfToken.php
protected $except = [
    'stripe/webhook',
    'paddle/webhook',
];
```
