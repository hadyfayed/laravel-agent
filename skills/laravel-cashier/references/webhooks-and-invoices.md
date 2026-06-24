# Laravel Cashier Webhooks and Invoices Reference

Webhook handling, invoices, checkout sessions, and Stripe CLI testing for Laravel Cashier (Stripe). These handlers also fire notifications provisioned in the subscription flow.

## Contents

- [Invoices and Receipts](#invoices-and-receipts)
- [Checkout Sessions (Stripe)](#checkout-sessions-stripe)
- [Webhooks Handling](#webhooks-handling)
- [Webhook Handler (with Notifications and Provisioning)](#webhook-handler-with-notifications-and-provisioning)
- [Stripe Checkout (with Customer Portal)](#stripe-checkout-with-customer-portal)
- [Subscription Plans View](#subscription-plans-view)
- [Routes](#routes)
- [Subscription Middleware](#subscription-middleware)
- [Testing with Stripe CLI](#testing-with-stripe-cli)
- [Pest Tests](#pest-tests)

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

## Webhook Handler (with Notifications and Provisioning)

A fuller webhook controller that provisions resources and sends notifications on key billing events:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Laravel\Cashier\Http\Controllers\WebhookController as CashierController;

final class StripeWebhookController extends CashierController
{
    /**
     * Handle customer subscription created.
     */
    protected function handleCustomerSubscriptionCreated(array $payload): void
    {
        parent::handleCustomerSubscriptionCreated($payload);

        $user = $this->getUserByStripeId($payload['data']['object']['customer']);

        if ($user) {
            // Send welcome email, provision resources, etc.
            $user->notify(new SubscriptionCreated());
        }
    }

    /**
     * Handle customer subscription updated.
     */
    protected function handleCustomerSubscriptionUpdated(array $payload): void
    {
        parent::handleCustomerSubscriptionUpdated($payload);

        $subscription = $payload['data']['object'];
        $user = $this->getUserByStripeId($subscription['customer']);

        if ($user && $subscription['cancel_at_period_end']) {
            $user->notify(new SubscriptionCancelling(
                $subscription['current_period_end']
            ));
        }
    }

    /**
     * Handle invoice payment succeeded.
     */
    protected function handleInvoicePaymentSucceeded(array $payload): void
    {
        $user = $this->getUserByStripeId($payload['data']['object']['customer']);

        if ($user) {
            $user->notify(new PaymentSucceeded(
                $payload['data']['object']['amount_paid'] / 100
            ));
        }
    }

    /**
     * Handle invoice payment failed.
     */
    protected function handleInvoicePaymentFailed(array $payload): void
    {
        $user = $this->getUserByStripeId($payload['data']['object']['customer']);

        if ($user) {
            Log::warning('Payment failed', [
                'user_id' => $user->id,
                'invoice' => $payload['data']['object']['id'],
            ]);

            $user->notify(new PaymentFailed());
        }
    }

    /**
     * Get user by Stripe customer ID.
     */
    protected function getUserByStripeId(string $stripeId): ?User
    {
        return User::where('stripe_id', $stripeId)->first();
    }
}
```

## Stripe Checkout (with Customer Portal)

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

final class CheckoutController extends Controller
{
    /**
     * Create Stripe Checkout session.
     */
    public function checkout(Request $request)
    {
        $request->validate([
            'plan' => 'required|in:monthly,yearly',
        ]);

        $priceId = config("cashier.prices.{$request->plan}");

        return $request->user()
            ->newSubscription('default', $priceId)
            ->trialDays(14)
            ->checkout([
                'success_url' => route('dashboard') . '?checkout=success',
                'cancel_url' => route('pricing') . '?checkout=cancelled',
                'billing_address_collection' => 'required',
                'allow_promotion_codes' => true,
            ]);
    }

    /**
     * Redirect to Customer Portal.
     */
    public function portal(Request $request)
    {
        return $request->user()->redirectToBillingPortal(route('dashboard'));
    }
}
```

## Subscription Plans View

```blade
{{-- resources/views/subscription/plans.blade.php --}}
<div class="grid md:grid-cols-2 gap-8">
    @foreach(['monthly' => 'Monthly', 'yearly' => 'Yearly'] as $plan => $label)
        <div class="border rounded-lg p-6">
            <h3 class="text-xl font-bold">{{ $label }}</h3>
            <p class="text-3xl font-bold my-4">
                ${{ $plan === 'monthly' ? '9.99' : '99' }}/{{ $plan === 'monthly' ? 'mo' : 'yr' }}
            </p>

            @if(auth()->user()->subscribed('default'))
                <form action="{{ route('subscription.update') }}" method="POST">
                    @csrf
                    @method('PUT')
                    <input type="hidden" name="plan" value="{{ $plan }}">
                    <button type="submit" class="btn btn-primary w-full">
                        Switch to {{ $label }}
                    </button>
                </form>
            @else
                <form action="{{ route('checkout') }}" method="POST">
                    @csrf
                    <input type="hidden" name="plan" value="{{ $plan }}">
                    <button type="submit" class="btn btn-primary w-full">
                        Start 14-Day Trial
                    </button>
                </form>
            @endif
        </div>
    @endforeach
</div>

@if(auth()->user()->subscribed('default'))
    <div class="mt-8">
        <a href="{{ route('billing-portal') }}" class="btn btn-secondary">
            Manage Billing
        </a>
    </div>
@endif
```

## Routes

```php
<?php

use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\StripeWebhookController;
use App\Http\Controllers\SubscriptionController;

// Subscription routes
Route::middleware('auth')->group(function () {
    Route::get('/subscription', [SubscriptionController::class, 'index'])->name('subscription.index');
    Route::post('/subscription', [SubscriptionController::class, 'store'])->name('subscription.store');
    Route::put('/subscription', [SubscriptionController::class, 'update'])->name('subscription.update');
    Route::delete('/subscription', [SubscriptionController::class, 'destroy'])->name('subscription.destroy');
    Route::post('/subscription/resume', [SubscriptionController::class, 'resume'])->name('subscription.resume');

    // Checkout
    Route::post('/checkout', [CheckoutController::class, 'checkout'])->name('checkout');
    Route::get('/billing-portal', [CheckoutController::class, 'portal'])->name('billing-portal');
});

// Webhook (no auth, no CSRF)
Route::post('/stripe/webhook', [StripeWebhookController::class, 'handleWebhook'])
    ->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]);
```

## Subscription Middleware

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class EnsureSubscribed
{
    public function handle(Request $request, Closure $next, string $plan = 'default'): Response
    {
        if (!$request->user()?->subscribed($plan)) {
            return redirect()->route('subscription.index')
                ->with('error', 'You need an active subscription to access this feature.');
        }

        return $next($request);
    }
}

// Register in bootstrap/app.php or Kernel.php
// 'subscribed' => \App\Http\Middleware\EnsureSubscribed::class,

// Usage in routes:
// Route::middleware('subscribed')->group(function () {
//     Route::get('/premium', PremiumController::class);
// });
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

## Pest Tests

```php
<?php

use App\Models\User;
use Laravel\Cashier\Subscription;

describe('Subscriptions', function () {
    it('can create subscription', function () {
        $user = User::factory()->create();

        $user->createAsStripeCustomer();

        $paymentMethod = $user->updateDefaultPaymentMethod('pm_card_visa');

        $user->newSubscription('default', config('cashier.prices.monthly'))
            ->create('pm_card_visa');

        expect($user->subscribed('default'))->toBeTrue();
    });

    it('can check subscription status', function () {
        $user = User::factory()->create();

        Subscription::factory()->create([
            'user_id' => $user->id,
            'name' => 'default',
            'stripe_status' => 'active',
        ]);

        expect($user->subscribed('default'))->toBeTrue();
        expect($user->hasActiveSubscription())->toBeTrue();
    });

    it('prevents access without subscription', function () {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/premium')
            ->assertRedirect(route('subscription.index'));
    });
});
```
