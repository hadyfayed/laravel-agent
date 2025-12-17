---
name: laravel-queue
description: >
  Implement background jobs, queues, events, and notifications in Laravel. Use when
  the user needs async processing, background tasks, event handling, or notifications.
  Triggers: "queue", "job", "background", "async", "event", "listener", "notification",
  "email", "dispatch", "worker", "Horizon".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Queue Skill

Implement asynchronous processing with Laravel queues.

## When to Use

- Background job processing
- Sending emails asynchronously
- Event-driven architecture
- Notification systems
- Long-running tasks

## Quick Start

```bash
/laravel-agent:job:make <JobName>
```

## Job Structure

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

final class ProcessOrder implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;
    public int $timeout = 120;

    public function __construct(
        public readonly Order $order
    ) {}

    public function handle(): void
    {
        // Process the order
        $this->order->process();
    }

    public function failed(\Throwable $e): void
    {
        // Handle failure
        Log::error('Order processing failed', [
            'order_id' => $this->order->id,
            'error' => $e->getMessage(),
        ]);
    }
}
```

## Dispatching Jobs

```php
// Dispatch immediately to queue
ProcessOrder::dispatch($order);

// Dispatch with delay
ProcessOrder::dispatch($order)->delay(now()->addMinutes(10));

// Dispatch to specific queue
ProcessOrder::dispatch($order)->onQueue('orders');

// Dispatch synchronously (for testing)
ProcessOrder::dispatchSync($order);

// Chain jobs
Bus::chain([
    new ProcessOrder($order),
    new SendInvoice($order),
    new NotifyCustomer($order),
])->dispatch();
```

## Events & Listeners

```php
// Event
final class OrderShipped
{
    public function __construct(
        public readonly Order $order
    ) {}
}

// Listener (queued)
final class SendShipmentNotification implements ShouldQueue
{
    public function handle(OrderShipped $event): void
    {
        $event->order->user->notify(new OrderShippedNotification($event->order));
    }
}

// Dispatch event
event(new OrderShipped($order));
// Or
OrderShipped::dispatch($order);
```

## Notifications

```php
<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

final class OrderConfirmation extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly Order $order
    ) {}

    public function via($notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toMail($notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Order Confirmed')
            ->line("Your order #{$this->order->id} has been confirmed.")
            ->action('View Order', url("/orders/{$this->order->id}"));
    }

    public function toArray($notifiable): array
    {
        return [
            'order_id' => $this->order->id,
            'message' => 'Order confirmed',
        ];
    }
}

// Send notification
$user->notify(new OrderConfirmation($order));
```

## Queue Configuration

```env
QUEUE_CONNECTION=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
```

## Running Workers

```bash
# Basic worker
php artisan queue:work

# Specific queue
php artisan queue:work --queue=high,default,low

# With options
php artisan queue:work redis --sleep=3 --tries=3 --max-time=3600

# Laravel Horizon (Redis)
php artisan horizon
```

## Laravel Horizon

```bash
composer require laravel/horizon
php artisan horizon:install
```

```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'maxProcesses' => 10,
            'balanceMaxShift' => 1,
            'balanceCooldown' => 3,
        ],
    ],
],
```

## Supervisor Configuration

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=4
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/worker.log
```

## Job Batching

```php
use Illuminate\Bus\Batch;
use Illuminate\Support\Facades\Bus;

$batch = Bus::batch([
    new ProcessOrder($order1),
    new ProcessOrder($order2),
    new ProcessOrder($order3),
])->then(function (Batch $batch) {
    // All jobs completed
})->catch(function (Batch $batch, Throwable $e) {
    // First failure
})->finally(function (Batch $batch) {
    // Batch finished
})->dispatch();

// Check status
$batch->progress(); // Percentage complete
$batch->finished(); // Boolean
```

## Unique Jobs

```php
use Illuminate\Contracts\Queue\ShouldBeUnique;

final class ProcessOrder implements ShouldQueue, ShouldBeUnique
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public readonly Order $order
    ) {}

    // Unique based on order ID
    public function uniqueId(): string
    {
        return (string) $this->order->id;
    }

    // Lock expires after 60 seconds
    public int $uniqueFor = 60;

    public function handle(): void
    {
        // Process order
    }
}
```

## Rate Limiting Jobs

```php
use Illuminate\Queue\Middleware\RateLimited;
use Illuminate\Support\Facades\RateLimiter;

// Define rate limiter
RateLimiter::for('payments', function (object $job) {
    return Limit::perMinute(10);
});

// Apply to job
final class ProcessPayment implements ShouldQueue
{
    public function middleware(): array
    {
        return [new RateLimited('payments')];
    }

    public function handle(): void
    {
        // Process payment
    }
}
```

## Job Middleware

```php
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\Middleware\ThrottlesExceptions;

final class ImportProducts implements ShouldQueue
{
    public function middleware(): array
    {
        return [
            // Prevent overlapping jobs for same user
            new WithoutOverlapping($this->userId),

            // Throttle if job keeps failing
            (new ThrottlesExceptions(5, 10))->backoff(5),
        ];
    }
}
```

## Broadcast Queue Events

```php
// Event with custom broadcast queue
final class OrderShipped implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Order $order
    ) {}

    public function broadcastQueue(): string
    {
        return 'broadcasts'; // Custom queue for broadcasts
    }
}
```

## Testing Jobs

```php
use Illuminate\Support\Facades\Queue;

it('dispatches order processing job', function () {
    Queue::fake();

    $order = Order::factory()->create();

    ProcessOrder::dispatch($order);

    Queue::assertPushed(ProcessOrder::class, function ($job) use ($order) {
        return $job->order->id === $order->id;
    });
});

it('handles job with specific queue', function () {
    Queue::fake();

    ProcessOrder::dispatch($order)->onQueue('orders');

    Queue::assertPushedOn('orders', ProcessOrder::class);
});
```

## Common Pitfalls

1. **Not Serializing Properly** - Models must use SerializesModels
   ```php
   // Bad - serializes entire model data
   public function __construct(public array $orderData) {}

   // Good - only serializes model ID
   use SerializesModels;
   public function __construct(public Order $order) {}
   ```

2. **Missing Failed Job Handler**
   ```php
   public function failed(\Throwable $e): void
   {
       Log::error('Job failed', [
           'order_id' => $this->order->id,
           'error' => $e->getMessage(),
       ]);

       // Notify admin
       Notification::route('slack', config('services.slack.webhook'))
           ->notify(new JobFailedNotification($this, $e));
   }
   ```

3. **Not Setting Appropriate Timeouts**
   ```php
   // Job will timeout after 30 seconds (default: 60)
   public int $timeout = 30;

   // Prevent job from being released back to queue
   public bool $failOnTimeout = true;
   ```

4. **Infinite Retry Loops**
   ```php
   // Limit retries
   public int $tries = 3;

   // Or use exponential backoff
   public array $backoff = [10, 60, 300]; // 10s, 1m, 5m
   ```

5. **Heavy Data in Queued Jobs**
   ```php
   // Bad - stores large data
   ProcessCsv::dispatch($csvContent);

   // Good - store file path
   ProcessCsv::dispatch($filePath);
   ```

6. **Not Restarting Workers After Deploy**
   ```bash
   # Workers cache code - always restart
   php artisan queue:restart
   ```

7. **Missing Supervisor Configuration**
   ```ini
   # Jobs will die without supervisor
   [program:laravel-worker]
   numprocs=4
   autostart=true
   autorestart=true
   ```

## Best Practices

- Use specific queues for different priorities
- Set appropriate timeouts and retry limits
- Handle failures gracefully
- Monitor queue length and worker health
- Use Horizon for Redis queue monitoring
- Serialize only what's needed
- Use unique jobs to prevent duplicates
- Test job dispatch and handling
- Implement dead letter queues for failed jobs

## Related Commands

- `/laravel-agent:job:make` - Create queued jobs, events, listeners

## Related Agents

- `laravel-queue` - Queue and job specialist
