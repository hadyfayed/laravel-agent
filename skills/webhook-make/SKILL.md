---
name: webhook-make
description: Scaffold webhook infrastructure with receiver endpoints, signature verification, dispatch/retry, and event handling; when integrating webhooks.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Read Write Edit
argument-hint: "<ServiceName> [--events=<event1,event2>]"
---

## Task

Create a secure webhook handler with signature verification and event dispatching.

## Input

- **ServiceName:** Service name (e.g., `Stripe`, `GitHub`, `Paddle`, `Custom`)
- **events:** Comma-separated event list (e.g., `payment_intent.succeeded,customer.subscription.created`)

## Steps

1. **Create webhook structure**:
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
   
   routes/
   └── webhooks.php
   ```

2. **Generate webhook controller** in `app/Http/Controllers/Webhooks/<Service>WebhookController.php`:
   - Accept POST request
   - Dispatch Laravel event for logging/auditing
   - Route event to appropriate handler
   - Handle errors and retries

3. **Generate signature verification middleware** in `app/Http/Middleware/Verify<Service>Signature.php`:
   - Verify request signature with configured secret
   - Abort with 401 on invalid signature

4. **Generate event handlers** in `app/Webhooks/<Service>/<Event>Handler.php`:
   - Handle specific webhook events
   - Update models, trigger jobs, etc.

5. **Create webhook event** in `app/Events/<Service>WebhookReceived.php`:
   - Log webhook receipt for auditing

6. **Register routes** in `routes/webhooks.php`:
   - POST /webhooks/<service>
   - Exempt from CSRF
   - Apply signature verification middleware

## Supported Services

See `${CLAUDE_SKILL_DIR}/references/service-config.md` for pre-configured services:
Stripe, Paddle, GitHub, GitLab, Twilio, SendGrid, and custom.

## Output

```markdown
## Webhook Handler: <Service>

### Files Created
- app/Http/Controllers/Webhooks/<Service>WebhookController.php
- app/Http/Middleware/Verify<Service>Signature.php
- app/Webhooks/<Service>/
  - <Event>Handler.php (for each event)
- app/Events/<Service>WebhookReceived.php
- routes/webhooks.php

### Environment Variables
Add to .env:
- <SERVICE>_WEBHOOK_SECRET=

### Webhook URL
https://yoursite.com/webhooks/<service>

### Events Handled
| Event | Handler |
|-------|---------|
| event_type | <Event>Handler |

### Testing
For Stripe: `stripe listen --forward-to localhost:8000/webhooks/stripe`
For GitHub: Configure in repository settings and test delivery
```
