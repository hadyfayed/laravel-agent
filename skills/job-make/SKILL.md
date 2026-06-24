---
name: job-make
description: Generate a queued job with retries/backoff/middleware; when creating async jobs.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Read Write Edit
argument-hint: "<Name> [job|event|listener|notification|all]"
---

## Task

Generate a queue-based job, event, listener, or notification component with retry strategies and middleware support.

## Input

- **Name:** Component name in Pascal case (e.g., `ProcessOrder`, `SendInvoice`, `UserRegistered`)
- **Type:** Component type (default: `job`)
  - `job` — Queued job with handle logic
  - `event` — Broadcast-able event (optionally with listeners)
  - `listener` — Event listener that performs work
  - `notification` — Multi-channel notification (mail, SMS, Slack)
  - `all` — Event + Listener + Notification combo

## Steps

1. **Create the base component(s)**:
   ```bash
   php artisan make:job <Name>          # Queued job
   php artisan make:event <Name>        # Event
   php artisan make:listener <Name>     # Event listener
   php artisan make:notification <Name> # Notification
   ```

2. **Configure retries and backoff** (for jobs and listeners):
   ```php
   public $tries = 3;
   public $backoff = [10, 60, 300]; // seconds: 10s, 1m, 5m
   public $timeout = 120;
   ```

3. **Add middleware** (if needed for rate limiting, unique constraints):
   ```php
   public function middleware(): array
   {
       return [new WithoutOverlapping($this->orderId)];
   }
   ```

4. **Implement handle() or handle(EventName $event)** with the business logic.

5. **Wire event listener** to your event (in `app/Providers/EventServiceProvider.php`):
   ```php
   protected $listen = [
       \App\Events\OrderCreated::class => [
           \App\Listeners\SendOrderConfirmation::class,
       ],
   ];
   ```

6. **Dispatch the job/event**:
   ```php
   // Direct job dispatch
   ProcessOrder::dispatch($order);

   // Event with listeners
   event(new OrderCreated($order));

   // Queued job from event listener
   ProcessOrder::dispatch($order)->delay(now()->addMinutes(5));
   ```

## Reference

For advanced queue patterns (batches, chains, broadcasting, job chaining, dead-letter handling), see the `laravel-queue` reference skill in the plugin.

## Queue configuration (.env)

```env
QUEUE_CONNECTION=database
QUEUE_FAILED_TABLE=failed_jobs
```

For high-throughput: use `redis` or `sqs`.

## Key queue features

- **Retries:** Auto-retry failed jobs with exponential backoff
- **Middleware:** Prevent job overlaps, rate limiting, unique constraints
- **Batches:** Dispatch and track multiple jobs as one unit
- **Chains:** Execute jobs in sequence, pass output between jobs
- **Delays:** Schedule jobs for future execution
- **Broadcasting:** Send real-time updates to clients
- **Timeouts:** Prevent hung jobs from blocking the queue

## Testing queue jobs

```php
it('processes order', function () {
    Queue::fake();

    ProcessOrder::dispatch($order);

    Queue::assertPushed(ProcessOrder::class, function ($job) use ($order) {
        return $job->order->id === $order->id;
    });
});
```
