# Webhook Controller Templates

## Stripe Webhook Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Webhooks;

use App\Http\Controllers\Controller;
use App\Events\StripeWebhookReceived;
use App\Webhooks\Stripe\PaymentIntentSucceededHandler;
use App\Webhooks\Stripe\CustomerSubscriptionCreatedHandler;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

final class StripeWebhookController extends Controller
{
    private array $handlers = [
        'payment_intent.succeeded' => PaymentIntentSucceededHandler::class,
        'customer.subscription.created' => CustomerSubscriptionCreatedHandler::class,
    ];

    public function __invoke(Request $request): Response
    {
        $payload = $request->all();
        $eventType = $payload['type'] ?? null;

        Log::info('Stripe webhook received', [
            'type' => $eventType,
            'id' => $payload['id'] ?? null,
        ]);

        event(new StripeWebhookReceived($eventType, $payload));

        if (isset($this->handlers[$eventType])) {
            try {
                $handler = app($this->handlers[$eventType]);
                $handler->handle($payload);
            } catch (\Exception $e) {
                Log::error('Stripe webhook handler failed', [
                    'type' => $eventType,
                    'error' => $e->getMessage(),
                ]);

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
        return $e instanceof \Illuminate\Database\QueryException
            || $e instanceof \Illuminate\Http\Client\ConnectionException;
    }
}
```

## GitHub Webhook Controller

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
        // Handle push event
    }

    private function handlePullRequest(array $payload): void
    {
        $action = $payload['action'];
        $pr = $payload['pull_request'];
        // Handle PR event
    }

    private function handleIssues(array $payload): void
    {
        $action = $payload['action'];
        $issue = $payload['issue'];
        // Handle issue event
    }
}
```
