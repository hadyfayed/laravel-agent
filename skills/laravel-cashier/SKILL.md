---
name: laravel-cashier
description: Laravel Cashier billing — Stripe/Paddle subscriptions, trials, invoices, webhooks, payment methods, single charges, and customer portal. Use when implementing subscriptions, recurring billing, Stripe or Paddle integration, checkout flows, or payment webhook handling. Triggers: "cashier", "stripe", "paddle", "subscription", "billing", "payment", "invoice", "checkout", "pricing", "recurring payment", "payment method", "webhook".
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

```bash
# Stripe (most popular)
composer require laravel/cashier
php artisan cashier:install
php artisan migrate

# Paddle
composer require laravel/cashier-paddle
php artisan vendor:publish --tag="cashier-migrations"
php artisan migrate
```

## Conventions Checklist

### Setup
- [ ] Add the `Billable` trait to the billable model (Stripe: `Laravel\Cashier\Billable`; Paddle: `Laravel\Paddle\Billable`)
- [ ] Cast `trial_ends_at` to `datetime`
- [ ] Use Stripe price IDs (`price_xxx`), not deprecated plan IDs (`plan_xxx`)
- [ ] Store all amounts in cents (Cashier expects cents)

### Subscriptions
- [ ] Name subscriptions (`newSubscription('default', $priceId)`) and check with `subscribed('default')`
- [ ] Apply trials via `->trialDays(14)`
- [ ] Check status: `subscribed()`, `onTrial()`, `onGracePeriod()`, `pastDue()`, `incomplete()`
- [ ] Handle multiple subscriptions by name (`'default'`, `'premium'`)
- [ ] Handle `IncompletePayment` — redirect to `cashier.payment` confirmation

### Payment Methods
- [ ] Use `createSetupIntent()` + Stripe.js for secure card collection
- [ ] `addPaymentMethod()`, `updateDefaultPaymentMethod()`, `removePaymentMethod()`
- [ ] Never collect or store raw card numbers server-side

### Webhooks
- [ ] Use Cashier's `WebhookController` (verifies signatures) — never a raw route
- [ ] Set `STRIPE_WEBHOOK_SECRET`
- [ ] Bypass CSRF on the webhook route (`withoutMiddleware(VerifyCsrfToken)`)
- [ ] Implement handlers: `subscription.created/updated/deleted`, `invoice.payment_succeeded/failed`

## Common Pitfalls

1. **Unverified webhooks** — use Cashier's controller + webhook secret; never process without verification
2. **Missing webhook CSRF exception** — webhook route must bypass CSRF
3. **Hardcoded price IDs** — use config/env for price IDs (`price_xxx`, not `plan_xxx`)
4. **Not handling `IncompletePayment`** — redirect to payment confirmation
5. **Wrong currency format** — Cashier expects cents (`9999` = $99.99, not `99.99`)
6. **Not syncing Stripe customer** — create the customer before the subscription
7. **Ignoring grace periods** — allow access until period end; offer resume
8. **Missing failed-payment handling** — implement `handleInvoicePaymentFailed`
9. **Testing with live keys** — always use test keys in development

## Best Practices

- Always use Stripe Checkout or Elements for PCI compliance
- Set up webhook forwarding (`stripe listen`) during development
- Send notifications for failed payments and provisioning events
- Provide a customer portal for self-service
- Use trial periods to increase conversions
- Handle incomplete subscriptions gracefully
- Log all webhook events and use metadata for tracking
- Implement proration for plan changes

## Related Commands

- `/laravel-agent:webhook:make` — create webhook handler skeletons

## Related Skills

- `laravel-api` — Build billing APIs
- `laravel-queue` — Process payments asynchronously
- `laravel-testing` — Test payment flows
- `laravel-security` — Secure payment endpoints

## Additional references

- Install / config / Billable model / subscriptions / single charges / payment methods → [references/subscriptions.md](references/subscriptions.md)
- Webhooks, invoices, checkout sessions, customer portal, Stripe CLI testing, Pest tests → [references/webhooks-and-invoices.md](references/webhooks-and-invoices.md)
- Paddle setup, config, model variant, CSRF exception → [references/paddle.md](references/paddle.md)
