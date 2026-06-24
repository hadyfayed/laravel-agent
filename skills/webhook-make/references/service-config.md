# Webhook Service Configuration

## Pre-Configured Services

### Stripe
- Signature verification: HMAC-SHA256
- Secret header: Stripe-Signature
- Sample events: payment_intent.succeeded, customer.subscription.*, invoice.*
- Environment: STRIPE_WEBHOOK_SECRET

### Paddle
- Signature verification: HMAC-SHA256
- Secret header: Paddle-Signature
- Sample events: subscription.created, payment.completed
- Environment: PADDLE_WEBHOOK_SECRET

### GitHub
- Signature verification: HMAC-SHA256
- Secret header: X-Hub-Signature-256
- Sample events: push, pull_request, issues
- Environment: GITHUB_WEBHOOK_SECRET

### GitLab
- Signature verification: Token
- Secret header: X-Gitlab-Token
- Sample events: push, merge_request
- Environment: GITLAB_WEBHOOK_TOKEN

### Twilio
- Signature verification: Twilio signature
- Secret header: X-Twilio-Signature
- Sample events: message.received
- Environment: TWILIO_AUTH_TOKEN

### SendGrid
- Signature verification: ED25519
- Secret header: X-SendGrid-Signature
- Sample events: email.delivered, email.bounced
- Environment: SENDGRID_WEBHOOK_SECRET

### Custom
- Use custom verification logic
- Accept any signature method
- Implement in middleware

## Example: Stripe Handler

```php
<?php

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
            Log::warning('Payment intent without order_id');
            return;
        }

        $order = Order::find($orderId);
        if (!$order) {
            Log::error('Order not found for payment intent');
            return;
        }

        Payment::create([
            'order_id' => $order->id,
            'stripe_payment_intent_id' => $paymentIntent['id'],
            'amount_cents' => $paymentIntent['amount'],
            'currency' => $paymentIntent['currency'],
            'status' => 'succeeded',
        ]);

        $order->update([
            'payment_status' => 'paid',
            'paid_at' => now(),
        ]);

        event(new \App\Events\OrderPaid($order));
        Log::info('Payment processed successfully', ['order_id' => $order->id]);
    }
}
```

## Retry Logic

```php
private function shouldRetry(\Exception $e): bool
{
    return $e instanceof \Illuminate\Database\QueryException
        || $e instanceof \Illuminate\Http\Client\ConnectionException;
}
```

- Return 200 to prevent retries (handled successfully)
- Return 500 for transient errors (service will retry)
