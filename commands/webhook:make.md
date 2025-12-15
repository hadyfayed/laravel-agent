---
description: "Create webhook handler for incoming webhooks (Stripe, GitHub, etc.)"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /webhook:make - Create Webhook Handler

Generate secure webhook handlers for processing incoming webhooks from external services.

## Input
$ARGUMENTS = `<ServiceName> [--events=<event1,event2>]`

Examples:
- `/webhook:make Stripe`
- `/webhook:make GitHub --events=push,pull_request`
- `/webhook:make Paddle`
- `/webhook:make Custom`

## Supported Services (Pre-configured)

| Service | Verification | Events |
|---------|--------------|--------|
| Stripe | Signature | payment_intent.succeeded, customer.subscription.*, invoice.* |
| Paddle | Signature | subscription.created, payment.completed |
| GitHub | Signature | push, pull_request, issues |
| GitLab | Token | push, merge_request |
| Twilio | Signature | message.received |
| SendGrid | Signature | email.delivered, email.bounced |
| Custom | Configurable | User-defined |

## Process

1. **Create Webhook Structure**
   ```
   app/
   ├── Http/
   │   ├── Controllers/Webhooks/
   │   │   └── <Service>WebhookController.php
   │   └── Middleware/
   │       └── Verify<Service>Signature.php
   ├── Webhooks/
   │   └── <Service>/
   │       ├── <Event>Handler.php
   │       └── ...
   └── Events/
       └── <Service>WebhookReceived.php
   ```

2. **Configure Routes**
   - Exempt from CSRF
   - Add signature verification middleware

3. **Generate Event Handlers**

4. **Add Environment Variables**

## Templates

### Webhook Controller
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Webhooks;

use App\Http\Controllers\Controller;
use App\Events\StripeWebhookReceived;
use App\Webhooks\Stripe\PaymentIntentSucceededHandler;
use App\Webhooks\Stripe\CustomerSubscriptionCreatedHandler;
use App\Webhooks\Stripe\CustomerSubscriptionDeletedHandler;
use App\Webhooks\Stripe\InvoicePaidHandler;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

final class StripeWebhookController extends Controller
{
    private array $handlers = [
        'payment_intent.succeeded' => PaymentIntentSucceededHandler::class,
        'customer.subscription.created' => CustomerSubscriptionCreatedHandler::class,
        'customer.subscription.deleted' => CustomerSubscriptionDeletedHandler::class,
        'customer.subscription.updated' => CustomerSubscriptionUpdatedHandler::class,
        'invoice.paid' => InvoicePaidHandler::class,
        'invoice.payment_failed' => InvoicePaymentFailedHandler::class,
    ];

    public function __invoke(Request $request): Response
    {
        $payload = $request->all();
        $eventType = $payload['type'] ?? null;

        Log::info('Stripe webhook received', [
            'type' => $eventType,
            'id' => $payload['id'] ?? null,
        ]);

        // Dispatch event for logging/auditing
        event(new StripeWebhookReceived($eventType, $payload));

        // Handle the event
        if (isset($this->handlers[$eventType])) {
            try {
                $handler = app($this->handlers[$eventType]);
                $handler->handle($payload);
            } catch (\Exception $e) {
                Log::error('Stripe webhook handler failed', [
                    'type' => $eventType,
                    'error' => $e->getMessage(),
                ]);

                // Return 200 to prevent retries for handled errors
                // Return 500 for unexpected errors to trigger retry
                if ($this->shouldRetry($e)) {
                    return response('', 500);
                }
            }
        } else {
            Log::info('Unhandled Stripe webhook event', ['type' => $eventType]);
        }

        return response('', 200);
    }

    private function shouldRetry(\Exception $e): bool
    {
        // Retry on transient errors (database, network)
        return $e instanceof \Illuminate\Database\QueryException
            || $e instanceof \Illuminate\Http\Client\ConnectionException;
    }
}
```

### Signature Verification Middleware
```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Stripe\Webhook;
use Stripe\Exception\SignatureVerificationException;

final class VerifyStripeSignature
{
    public function handle(Request $request, Closure $next): Response
    {
        $signature = $request->header('Stripe-Signature');
        $secret = config('services.stripe.webhook_secret');

        if (!$signature || !$secret) {
            abort(401, 'Missing signature or secret');
        }

        try {
            Webhook::constructEvent(
                $request->getContent(),
                $signature,
                $secret
            );
        } catch (SignatureVerificationException $e) {
            abort(401, 'Invalid signature');
        }

        return $next($request);
    }
}
```

### Event Handler
```php
<?php

declare(strict_types=1);

namespace App\Webhooks\Stripe;

use App\Models\Order;
use App\Models\Payment;
use Illuminate\Support\Facades\Log;

final class PaymentIntentSucceededHandler
{
    public function handle(array $payload): void
    {
        $paymentIntent = $payload['data']['object'];
        $orderId = $paymentIntent['metadata']['order_id'] ?? null;

        if (!$orderId) {
            Log::warning('Payment intent without order_id', [
                'payment_intent_id' => $paymentIntent['id'],
            ]);
            return;
        }

        $order = Order::find($orderId);

        if (!$order) {
            Log::error('Order not found for payment intent', [
                'order_id' => $orderId,
                'payment_intent_id' => $paymentIntent['id'],
            ]);
            return;
        }

        // Record payment
        $payment = Payment::create([
            'order_id' => $order->id,
            'stripe_payment_intent_id' => $paymentIntent['id'],
            'amount_cents' => $paymentIntent['amount'],
            'currency' => $paymentIntent['currency'],
            'status' => 'succeeded',
        ]);

        // Update order status
        $order->update([
            'payment_status' => 'paid',
            'paid_at' => now(),
        ]);

        // Dispatch follow-up events
        event(new \App\Events\OrderPaid($order));

        Log::info('Payment processed successfully', [
            'order_id' => $order->id,
            'payment_id' => $payment->id,
        ]);
    }
}
```

### GitHub Webhook Controller
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Webhooks;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class GitHubWebhookController extends Controller
{
    public function __invoke(Request $request): Response
    {
        $event = $request->header('X-GitHub-Event');
        $payload = $request->all();

        match ($event) {
            'push' => $this->handlePush($payload),
            'pull_request' => $this->handlePullRequest($payload),
            'issues' => $this->handleIssues($payload),
            default => null,
        };

        return response('', 200);
    }

    private function handlePush(array $payload): void
    {
        $ref = $payload['ref'];
        $commits = $payload['commits'] ?? [];
        $repository = $payload['repository']['full_name'];

        // Trigger deployment, notify team, etc.
    }

    private function handlePullRequest(array $payload): void
    {
        $action = $payload['action'];
        $pr = $payload['pull_request'];

        // Handle opened, closed, merged, etc.
    }

    private function handleIssues(array $payload): void
    {
        $action = $payload['action'];
        $issue = $payload['issue'];

        // Handle opened, closed, labeled, etc.
    }
}
```

### GitHub Signature Middleware
```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class VerifyGitHubSignature
{
    public function handle(Request $request, Closure $next): Response
    {
        $signature = $request->header('X-Hub-Signature-256');
        $secret = config('services.github.webhook_secret');

        if (!$signature || !$secret) {
            abort(401);
        }

        $expectedSignature = 'sha256=' . hash_hmac(
            'sha256',
            $request->getContent(),
            $secret
        );

        if (!hash_equals($expectedSignature, $signature)) {
            abort(401, 'Invalid signature');
        }

        return $next($request);
    }
}
```

### Routes Configuration
```php
// routes/webhooks.php
use App\Http\Controllers\Webhooks\StripeWebhookController;
use App\Http\Controllers\Webhooks\GitHubWebhookController;
use App\Http\Middleware\VerifyStripeSignature;
use App\Http\Middleware\VerifyGitHubSignature;

Route::post('/webhooks/stripe', StripeWebhookController::class)
    ->middleware(VerifyStripeSignature::class)
    ->name('webhooks.stripe');

Route::post('/webhooks/github', GitHubWebhookController::class)
    ->middleware(VerifyGitHubSignature::class)
    ->name('webhooks.github');
```

```php
// bootstrap/app.php or app/Http/Kernel.php
// Exempt webhook routes from CSRF
->withMiddleware(function (Middleware $middleware) {
    $middleware->validateCsrfTokens(except: [
        'webhooks/*',
    ]);
})
```

### Environment Variables
```env
# Stripe
STRIPE_WEBHOOK_SECRET=whsec_...

# GitHub
GITHUB_WEBHOOK_SECRET=your-secret

# Paddle
PADDLE_WEBHOOK_SECRET=pdl_...
```

## Interactive Prompts

When run without arguments, prompt user for:

1. **Which service?**
   - Stripe
   - Paddle
   - GitHub
   - GitLab
   - Twilio
   - SendGrid
   - Custom

2. **Which events to handle?** (based on service)
   - [x] payment_intent.succeeded
   - [x] customer.subscription.created
   - [ ] customer.subscription.deleted
   - ...

3. **Signature verification?**
   - Yes (recommended)
   - No

4. **Event dispatching?**
   - Yes (fire Laravel event for each webhook)
   - No

## Output

```markdown
## Webhook Handler: <Service>

### Files Created
- app/Http/Controllers/Webhooks/<Service>WebhookController.php
- app/Http/Middleware/Verify<Service>Signature.php
- app/Webhooks/<Service>/
  - PaymentIntentSucceededHandler.php
  - CustomerSubscriptionCreatedHandler.php
  - ...
- app/Events/<Service>WebhookReceived.php
- routes/webhooks.php

### Environment Variables
```env
<SERVICE>_WEBHOOK_SECRET=
```

### Webhook URL
```
https://yoursite.com/webhooks/<service>
```

### Events Handled
| Event | Handler |
|-------|---------|
| payment_intent.succeeded | PaymentIntentSucceededHandler |
| customer.subscription.created | CustomerSubscriptionCreatedHandler |

### Testing
```bash
# Use Stripe CLI for local testing
stripe listen --forward-to localhost:8000/webhooks/stripe

# Trigger test event
stripe trigger payment_intent.succeeded
```

### Next Steps
1. Add webhook secret to .env
2. Configure webhook URL in service dashboard
3. Test with CLI or service's testing tools
4. Monitor logs for webhook events
```
