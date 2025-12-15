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

## Best Practices

- Use specific queues for different priorities
- Set appropriate timeouts and retry limits
- Handle failures gracefully
- Monitor queue length and worker health
- Use Horizon for Redis queue monitoring
- Serialize only what's needed
