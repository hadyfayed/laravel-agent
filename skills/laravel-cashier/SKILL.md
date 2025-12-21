---
name: laravel-cashier
description: >
  Implement subscription billing with Laravel Cashier. Use when the user needs payments,
  subscriptions, Stripe integration, Paddle integration, or billing features.
  Triggers: "cashier", "stripe", "paddle", "subscription", "billing", "payment",
  "invoice", "checkout", "pricing", "recurring payment", "payment method", "webhook".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Cashier Skill

Implement subscription billing and payments with Laravel Cashier for Stripe or Paddle.

## When to Use

- Setting up subscription billing
- Processing one-time payments
- Managing payment methods
- Creating pricing plans
- Handling invoices and receipts
- Managing customer portals
- Processing webhooks from Stripe/Paddle
- Implementing metered billing
- Building checkout flows

## Quick Start

### Choose Your Provider

**Stripe (Most Popular)**
```bash
composer require laravel/cashier
php artisan cashier:install
php artisan migrate
```

**Paddle**
```bash
composer require laravel/cashier-paddle
php artisan vendor:publish --tag="cashier-migrations"
php artisan migrate
```

## Installation and Configuration

### Stripe Setup

```bash
# Install Cashier for Stripe
composer require laravel/cashier

# Publish migrations
php artisan vendor:publish --tag="cashier-migrations"

# Run migrations
php artisan migrate

# Install Cashier webhooks
php artisan cashier:install
```

### Environment Variables (Stripe)

```env
STRIPE_KEY=pk_test_...
STRIPE_SECRET=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
CASHIER_CURRENCY=usd
CASHIER_CURRENCY_LOCALE=en
```

### Paddle Setup

```bash
# Install Cashier for Paddle
composer require laravel/cashier-paddle

# Publish config
php artisan vendor:publish --tag="cashier-config"

# Publish migrations
php artisan vendor:publish --tag="cashier-migrations"

# Run migrations
php artisan migrate
```

### Environment Variables (Paddle)

```env
PADDLE_VENDOR_ID=your-vendor-id
PADDLE_VENDOR_AUTH_CODE=your-auth-code
PADDLE_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----..."
PADDLE_SANDBOX=true
```

## Billable Model Setup

### Add Billable Trait (Stripe)

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Cashier\Billable;

class User extends Authenticatable
{
    use Billable;

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'trial_ends_at' => 'datetime',
    ];

    /**
     * Get the customer name for invoices.
     */
    public function customerName(): string
    {
        return $this->name;
    }

    /**
     * Get the customer email for invoices.
     */
    public function customerEmail(): string
    {
        return $this->email;
    }

    /**
     * Determine if the user has an active subscription.
     */
    public function hasActiveSubscription(): bool
    {
        return $this->subscribed('default');
    }

    /**
     * Determine if the user is on a trial.
     */
    public function onTrial(): bool
    {
        return $this->onGenericTrial();
    }
}
```

### Add Billable Trait (Paddle)

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Paddle\Billable;

class User extends Authenticatable
{
    use Billable;

    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'trial_ends_at' => 'datetime',
    ];
}
```

## Subscriptions

### Creating Subscriptions (Stripe)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

final class SubscriptionController extends Controller
{
    public function index(Request $request): View
    {
        return view('billing.index', [
            'user' => $request->user(),
            'subscriptions' => $request->user()->subscriptions,
            'paymentMethods' => $request->user()->paymentMethods(),
            'defaultPaymentMethod' => $request->user()->defaultPaymentMethod(),
            'upcomingInvoice' => $request->user()->upcomingInvoice(),
        ]);
    }

    public function create(): View
    {
        return view('billing.create', [
            'intent' => auth()->user()->createSetupIntent(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'plan' => 'required|in:price_monthly,price_yearly',
            'payment_method' => 'required|string',
        ]);

        try {
            $request->user()
                ->newSubscription('default', $request->plan)
                ->trialDays(14)
                ->create($request->payment_method, [
                    'email' => $request->user()->email,
                ]);

            return redirect()->route('billing.index')
                ->with('success', 'Subscription created successfully!');
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }

    public function swap(Request $request): RedirectResponse
    {
        $request->validate([
            'plan' => 'required|in:price_monthly,price_yearly',
        ]);

        $subscription = $request->user()->subscription('default');

        if (!$subscription) {
            return back()->withErrors(['error' => 'No active subscription found.']);
        }

        $subscription->swap($request->plan);

        return back()->with('success', 'Plan updated successfully!');
    }

    public function cancel(Request $request): RedirectResponse
    {
        $subscription = $request->user()->subscription('default');

        if (!$subscription) {
            return back()->withErrors(['error' => 'No active subscription found.']);
        }

        $subscription->cancel();

        return back()->with('success', 'Subscription will be cancelled at period end.');
    }

    public function cancelNow(Request $request): RedirectResponse
    {
        $subscription = $request->user()->subscription('default');

        if (!$subscription) {
            return back()->withErrors(['error' => 'No active subscription found.']);
        }

        $subscription->cancelNow();

        return back()->with('success', 'Subscription cancelled immediately.');
    }

    public function resume(Request $request): RedirectResponse
    {
        $subscription = $request->user()->subscription('default');

        if (!$subscription || !$subscription->onGracePeriod()) {
            return back()->withErrors(['error' => 'Cannot resume subscription.']);
        }

        $subscription->resume();

        return back()->with('success', 'Subscription resumed successfully!');
    }
}
```

### Checking Subscription Status

```php
// Check if user has any subscription
if ($user->subscribed('default')) {
    // User has active subscription
}

// Check for specific plan
if ($user->subscribedToPrice('price_monthly', 'default')) {
    // User is on monthly plan
}

// Check if user is on trial
if ($user->onTrial('default')) {
    // User is on trial
}

// Check if subscription is cancelled but still active
if ($user->subscription('default')->onGracePeriod()) {
    // Subscription cancelled but valid until period end
}

// Check if subscription is past due
if ($user->subscription('default')->pastDue()) {
    // Payment failed, subscription past due
}

// Check if subscription is incomplete
if ($user->subscription('default')->incomplete()) {
    // Initial payment failed
}
```

### Multiple Subscriptions

```php
// Create multiple subscriptions
$user->newSubscription('default', 'price_monthly')->create($paymentMethod);
$user->newSubscription('premium', 'price_premium')->create($paymentMethod);

// Check specific subscription
if ($user->subscribed('premium')) {
    // User has premium subscription
}

// Cancel specific subscription
$user->subscription('premium')->cancel();
```

## Single Charges (Stripe)

### One-Time Payments

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

final class PaymentController extends Controller
{
    public function charge(Request $request): RedirectResponse
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'payment_method' => 'required|string',
        ]);

        try {
            $user = $request->user();

            // Charge the customer
            $payment = $user->charge(
                $request->amount * 100, // Amount in cents
                $request->payment_method,
                [
                    'description' => 'One-time payment',
                    'metadata' => [
                        'user_id' => $user->id,
                        'order_id' => $request->order_id,
                    ],
                ]
            );

            return redirect()->route('payment.success')
                ->with('success', 'Payment successful!');
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }

    public function refund(Request $request, string $paymentIntentId): RedirectResponse
    {
        try {
            $user = $request->user();
            $user->refund($paymentIntentId);

            return back()->with('success', 'Payment refunded successfully!');
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }
}
```

### Invoicing for Single Charges

```php
// Create invoice item
$user->tab('Setup Fee', 9999); // $99.99 in cents

// Create multiple items
$user->tab('Consulting Hour', 15000);
$user->tab('Additional Services', 5000);

// Invoice the customer
$invoice = $user->invoice();

// Invoice with custom options
$invoice = $user->invoiceFor('Custom Service', 10000, [
    'metadata' => [
        'service_type' => 'consulting',
    ],
]);
```

## Payment Methods

### Managing Payment Methods (Stripe)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

final class PaymentMethodController extends Controller
{
    public function index(Request $request): View
    {
        return view('billing.payment-methods', [
            'paymentMethods' => $request->user()->paymentMethods(),
            'defaultPaymentMethod' => $request->user()->defaultPaymentMethod(),
            'intent' => $request->user()->createSetupIntent(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'payment_method' => 'required|string',
        ]);

        try {
            $request->user()->addPaymentMethod($request->payment_method);

            return back()->with('success', 'Payment method added successfully!');
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }

    public function setDefault(Request $request, string $paymentMethodId): RedirectResponse
    {
        try {
            $request->user()->updateDefaultPaymentMethod($paymentMethodId);

            return back()->with('success', 'Default payment method updated!');
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }

    public function destroy(Request $request, string $paymentMethodId): RedirectResponse
    {
        try {
            $request->user()->removePaymentMethod($paymentMethodId);

            return back()->with('success', 'Payment method removed successfully!');
        } catch (\Exception $e) {
            return back()->withErrors(['error' => $e->getMessage()]);
        }
    }
}
```

### Payment Method View (Stripe.js)

```blade
{{-- resources/views/billing/payment-methods.blade.php --}}
<x-app-layout>
    <div class="max-w-4xl mx-auto py-8">
        <h1 class="text-2xl font-bold mb-6">Payment Methods</h1>

        @if (session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
                {{ session('success') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {{ $errors->first() }}
            </div>
        @endif

        {{-- Existing Payment Methods --}}
        <div class="bg-white rounded-lg shadow p-6 mb-6">
            <h2 class="text-lg font-semibold mb-4">Saved Payment Methods</h2>

            @forelse ($paymentMethods as $method)
                <div class="flex items-center justify-between border-b py-3 last:border-0">
                    <div class="flex items-center space-x-3">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M20 4H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V6c0-1.11-.89-2-2-2zm0 14H4v-6h16v6zm0-10H4V6h16v2z"/>
                        </svg>
                        <div>
                            <p class="font-medium">•••• {{ $method->card->last4 }}</p>
                            <p class="text-sm text-gray-600">Expires {{ $method->card->exp_month }}/{{ $method->card->exp_year }}</p>
                        </div>
                        @if ($defaultPaymentMethod && $method->id === $defaultPaymentMethod->id)
                            <span class="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">Default</span>
                        @endif
                    </div>

                    <div class="flex space-x-2">
                        @if (!$defaultPaymentMethod || $method->id !== $defaultPaymentMethod->id)
                            <form method="POST" action="{{ route('billing.payment-methods.default', $method->id) }}">
                                @csrf
                                @method('PUT')
                                <button type="submit" class="text-blue-600 hover:text-blue-800">
                                    Set Default
                                </button>
                            </form>
                        @endif

                        <form method="POST" action="{{ route('billing.payment-methods.destroy', $method->id) }}">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="text-red-600 hover:text-red-800">
                                Remove
                            </button>
                        </form>
                    </div>
                </div>
            @empty
                <p class="text-gray-600">No payment methods saved.</p>
            @endforelse
        </div>

        {{-- Add New Payment Method --}}
        <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Add Payment Method</h2>

            <form id="payment-form" method="POST" action="{{ route('billing.payment-methods.store') }}">
                @csrf

                <div id="card-element" class="border rounded p-3 mb-4"></div>
                <div id="card-errors" class="text-red-600 text-sm mb-4"></div>

                <input type="hidden" name="payment_method" id="payment-method">

                <button type="submit" id="card-button" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">
                    Add Payment Method
                </button>
            </form>
        </div>
    </div>

    @push('scripts')
    <script src="https://js.stripe.com/v3/"></script>
    <script>
        const stripe = Stripe('{{ config('cashier.key') }}');
        const elements = stripe.elements();
        const cardElement = elements.create('card');
        cardElement.mount('#card-element');

        const form = document.getElementById('payment-form');
        const cardButton = document.getElementById('card-button');
        const cardErrors = document.getElementById('card-errors');

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            cardButton.disabled = true;

            const { setupIntent, error } = await stripe.confirmCardSetup(
                '{{ $intent->client_secret }}',
                {
                    payment_method: {
                        card: cardElement,
                        billing_details: {
                            name: '{{ auth()->user()->name }}',
                            email: '{{ auth()->user()->email }}',
                        }
                    }
                }
            );

            if (error) {
                cardErrors.textContent = error.message;
                cardButton.disabled = false;
            } else {
                document.getElementById('payment-method').value = setupIntent.payment_method;
                form.submit();
            }
        });
    </script>
    @endpush
</x-app-layout>
```

## Invoices and Receipts

### Accessing Invoices (Stripe)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\View\View;

final class InvoiceController extends Controller
{
    public function index(Request $request): View
    {
        return view('billing.invoices', [
            'invoices' => $request->user()->invoices(),
        ]);
    }

    public function show(Request $request, string $invoiceId): Response
    {
        return $request->user()->downloadInvoice($invoiceId, [
            'vendor' => config('app.name'),
            'product' => 'Subscription',
        ]);
    }

    public function download(Request $request, string $invoiceId): Response
    {
        return $request->user()->downloadInvoice($invoiceId, [
            'vendor' => config('app.name'),
            'product' => 'Subscription',
            'street' => '123 Main Street',
            'location' => 'San Francisco, CA 94102',
        ]);
    }
}
```

### Invoice View

```blade
{{-- resources/views/billing/invoices.blade.php --}}
<x-app-layout>
    <div class="max-w-4xl mx-auto py-8">
        <h1 class="text-2xl font-bold mb-6">Invoices</h1>

        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    @forelse ($invoices as $invoice)
                        <tr>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {{ $invoice->date()->toFormattedDateString() }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                {{ $invoice->total() }}
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                @if ($invoice->paid)
                                    <span class="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">Paid</span>
                                @else
                                    <span class="px-2 py-1 text-xs bg-red-100 text-red-800 rounded">Unpaid</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right">
                                <a href="{{ route('billing.invoices.download', $invoice->id) }}"
                                   class="text-blue-600 hover:text-blue-800">
                                    Download
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                                No invoices found.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</x-app-layout>
```

## Checkout Sessions (Stripe)

### Creating Checkout Sessions

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

final class CheckoutController extends Controller
{
    public function show(): View
    {
        return view('billing.checkout');
    }

    public function create(Request $request): RedirectResponse
    {
        $request->validate([
            'plan' => 'required|in:price_monthly,price_yearly',
        ]);

        return $request->user()
            ->newSubscription('default', $request->plan)
            ->trialDays(14)
            ->checkout([
                'success_url' => route('billing.success'),
                'cancel_url' => route('billing.checkout'),
            ]);
    }

    public function success(): View
    {
        return view('billing.success');
    }
}
```

### Checkout for Single Charge

```php
public function checkout(Request $request): RedirectResponse
{
    return $request->user()->checkout([
        'line_items' => [
            [
                'price' => 'price_premium_feature',
                'quantity' => 1,
            ],
        ],
        'success_url' => route('purchase.success'),
        'cancel_url' => route('purchase.cancelled'),
    ]);
}
```

## Webhooks Handling

### Webhook Controller (Stripe)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Laravel\Cashier\Http\Controllers\WebhookController as CashierController;

final class StripeWebhookController extends CashierController
{
    /**
     * Handle customer subscription created.
     */
    public function handleCustomerSubscriptionCreated(array $payload): void
    {
        // Custom logic when subscription is created
        $subscription = $payload['data']['object'];

        \Log::info('Subscription created', [
            'subscription_id' => $subscription['id'],
            'customer' => $subscription['customer'],
        ]);

        // Send notification to admin
        // \Notification::route('mail', 'admin@example.com')
        //     ->notify(new SubscriptionCreated($subscription));
    }

    /**
     * Handle customer subscription updated.
     */
    public function handleCustomerSubscriptionUpdated(array $payload): void
    {
        $subscription = $payload['data']['object'];

        \Log::info('Subscription updated', [
            'subscription_id' => $subscription['id'],
            'status' => $subscription['status'],
        ]);
    }

    /**
     * Handle customer subscription deleted.
     */
    public function handleCustomerSubscriptionDeleted(array $payload): void
    {
        $subscription = $payload['data']['object'];

        \Log::info('Subscription deleted', [
            'subscription_id' => $subscription['id'],
            'customer' => $subscription['customer'],
        ]);

        // Send cancellation email
        // $user = User::where('stripe_id', $subscription['customer'])->first();
        // $user->notify(new SubscriptionCancelled());
    }

    /**
     * Handle invoice payment succeeded.
     */
    public function handleInvoicePaymentSucceeded(array $payload): void
    {
        $invoice = $payload['data']['object'];

        \Log::info('Invoice payment succeeded', [
            'invoice_id' => $invoice['id'],
            'amount' => $invoice['amount_paid'],
        ]);
    }

    /**
     * Handle invoice payment failed.
     */
    public function handleInvoicePaymentFailed(array $payload): void
    {
        $invoice = $payload['data']['object'];

        \Log::warning('Invoice payment failed', [
            'invoice_id' => $invoice['id'],
            'customer' => $invoice['customer'],
        ]);

        // Send payment failed notification
        // $user = User::where('stripe_id', $invoice['customer'])->first();
        // $user->notify(new PaymentFailed($invoice));
    }

    /**
     * Handle customer updated.
     */
    public function handleCustomerUpdated(array $payload): void
    {
        // Sync customer data from Stripe
    }

    /**
     * Handle payment method attached.
     */
    public function handlePaymentMethodAttached(array $payload): void
    {
        // Handle payment method added
    }
}
```

### Webhook Routes

```php
// routes/web.php
use App\Http\Controllers\StripeWebhookController;

Route::post(
    'stripe/webhook',
    [StripeWebhookController::class, 'handleWebhook']
)->name('cashier.webhook');
```

### Verify Webhooks are Working

```bash
# Register webhook in Stripe Dashboard
# https://dashboard.stripe.com/webhooks

# Set webhook URL: https://yourdomain.com/stripe/webhook

# Select events to listen for:
# - customer.subscription.created
# - customer.subscription.updated
# - customer.subscription.deleted
# - invoice.payment_succeeded
# - invoice.payment_failed
# - customer.updated
```

## Testing with Stripe CLI

### Install Stripe CLI

```bash
# Install Stripe CLI (macOS)
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Forward webhooks to local app
stripe listen --forward-to localhost:8000/stripe/webhook

# Get webhook signing secret
stripe listen --print-secret
# Add to .env as STRIPE_WEBHOOK_SECRET
```

### Trigger Test Events

```bash
# Trigger subscription created
stripe trigger customer.subscription.created

# Trigger payment succeeded
stripe trigger payment_intent.succeeded

# Trigger payment failed
stripe trigger payment_intent.payment_failed

# Trigger subscription cancelled
stripe trigger customer.subscription.deleted

# View webhook events
stripe events list --limit 10
```

### Testing Subscriptions

```bash
# Create test subscription
stripe subscriptions create \
  --customer cus_test123 \
  --items '[{"price":"price_test123"}]'

# Cancel subscription
stripe subscriptions cancel sub_test123

# Update subscription
stripe subscriptions update sub_test123 \
  --items '[{"price":"price_new123"}]'
```

### Test Card Numbers

```
# Successful payment
4242 4242 4242 4242

# Requires authentication (3D Secure)
4000 0027 6000 3184

# Declined card
4000 0000 0000 0002

# Insufficient funds
4000 0000 0000 9995

# Expired card
4000 0000 0000 0069

# Processing error
4000 0000 0000 0119
```

## Common Pitfalls

1. **Not Verifying Webhook Signatures**
   ```php
   // Wrong - no verification
   Route::post('webhook', function (Request $request) {
       // Process without verification
   });

   // Right - use Cashier's webhook controller
   Route::post('stripe/webhook', [WebhookController::class, 'handleWebhook']);
   ```

2. **Forgetting to Set Webhook Secret**
   ```env
   # Required for webhook verification
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

3. **Not Handling Failed Payments**
   ```php
   // Always implement handleInvoicePaymentFailed
   public function handleInvoicePaymentFailed(array $payload): void
   {
       $user = User::where('stripe_id', $payload['data']['object']['customer'])->first();
       $user->notify(new PaymentFailedNotification());
   }
   ```

4. **Using Wrong Currency Format**
   ```php
   // Wrong - Cashier expects cents
   $user->charge(99.99, $paymentMethod); // Charges $0.99

   // Right - use cents
   $user->charge(9999, $paymentMethod); // Charges $99.99
   ```

5. **Not Handling Incomplete Subscriptions**
   ```php
   // Check for incomplete subscriptions
   if ($user->subscription('default')->incomplete()) {
       return redirect()->route('billing.confirm-payment');
   }
   ```

6. **Missing Customer Data on Stripe**
   ```php
   // Add customer metadata
   $user->newSubscription('default', $plan)
       ->create($paymentMethod, [
           'email' => $user->email,
           'name' => $user->name,
           'metadata' => [
               'user_id' => $user->id,
           ],
       ]);
   ```

7. **Not Testing Webhooks Locally**
   ```bash
   # Always test webhooks during development
   stripe listen --forward-to localhost:8000/stripe/webhook
   ```

8. **Ignoring Grace Periods**
   ```php
   // Check if subscription is cancelled but still valid
   if ($user->subscription('default')->onGracePeriod()) {
       // Allow access until period ends
       // Show option to resume subscription
   }
   ```

9. **Not Syncing Prices from Stripe**
   ```php
   // Create prices in Stripe Dashboard or via API
   // Use price IDs (price_xxx) not plan IDs (plan_xxx)
   $user->newSubscription('default', 'price_monthly')
   ```

10. **Missing CSRF Exception for Webhooks**
    ```php
    // app/Http/Middleware/VerifyCsrfToken.php
    protected $except = [
        'stripe/webhook',
        'paddle/webhook',
    ];
    ```

## Best Practices

- Always use Stripe's price IDs (not deprecated plan IDs)
- Set up webhook forwarding during development
- Store currency amounts in cents
- Implement comprehensive webhook handlers
- Send notifications for failed payments
- Provide customer portal for self-service
- Use trial periods to increase conversions
- Handle incomplete subscriptions gracefully
- Test with Stripe test cards
- Monitor subscription metrics in Stripe Dashboard
- Implement proper error handling
- Log all webhook events
- Use metadata for tracking
- Provide clear cancellation flow
- Send receipt emails for all charges
- Keep Cashier package updated
- Use environment-specific Stripe keys
- Implement proration for plan changes
- Handle edge cases (expired cards, declined payments)
- Provide invoice history to customers

## Related Commands

```bash
# Install Cashier
composer require laravel/cashier

# Publish Cashier migrations
php artisan vendor:publish --tag="cashier-migrations"

# Run migrations
php artisan migrate

# Install Cashier assets and routes
php artisan cashier:install

# Create subscription model events
php artisan make:observer SubscriptionObserver --model=Subscription
```

## Related Skills

- `laravel-api` - Build billing APIs
- `laravel-queue` - Process payments asynchronously
- `laravel-testing` - Test payment flows
- `laravel-security` - Secure payment endpoints
