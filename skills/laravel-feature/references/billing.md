# Billing & Subscriptions (Delegated to laravel-cashier)

Subscription management, billing cycles, payment processing, and invoice generation are owned by the **laravel-cashier** skill. This keeps billing domain knowledge centralized and prevents duplication.

## When Your Feature Needs Billing

If you are building a feature that involves:
- Subscription tiers or plans
- Recurring billing/payment collection
- Invoice generation
- Payment method management
- Refunds or charge adjustments

**Do this:**

1. **Scaffold the core feature here** in laravel-feature using this skill — models, database migrations, business logic for the feature itself.
2. **Run the laravel-cashier skill** (use the skill dropdown or `/laravel-agent:cashier-setup`) to add Cashier integration:
   - Subscription models and relationships
   - Payment handling via Stripe, Paddle, etc.
   - Invoice tracking
   - Webhook handlers for payment events

3. **Connect them** — for example, when a feature is "activated", trigger subscription creation via Cashier's API.

## Example: Premium Feature Flag

```php
// Your feature model (built in laravel-feature)
class PremiumFeature extends Model
{
    public function subscriptions()
    {
        return $this->hasManyThrough(Subscription::class, User::class);
    }

    public function isAvailableFor(User $user): bool
    {
        return $user->hasActiveSubscription('premium_plan');
    }
}

// The subscription itself (managed by laravel-cashier)
// $user->newSubscription('premium_plan', 'price_xxx')->create($paymentMethod);
```

## Why Delegate?

The laravel-cashier skill has specialized knowledge of:
- Stripe/Paddle API integration
- Subscription lifecycle management
- Webhook and webhook signature validation
- Tax calculation and compliance
- Proration and plan changes
- Invoice PDF generation and storage

Keeping billing separate prevents your feature code from becoming coupled to payment logic.

---

**For detailed billing integration patterns, consult the laravel-cashier skill.**
