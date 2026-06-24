# Signature Verification Middleware

## Stripe Signature Verification

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

## GitHub Signature Verification

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

## Generic HMAC-SHA256 Verification

```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class VerifyHmacSignature
{
    public function handle(Request $request, Closure $next): Response
    {
        $signature = $request->header('X-Signature');
        $secret = config('services.webhook.secret');

        if (!$signature || !$secret) {
            abort(401);
        }

        $computed = hash_hmac('sha256', $request->getContent(), $secret);

        if (!hash_equals($computed, $signature)) {
            abort(401);
        }

        return $next($request);
    }
}
```
