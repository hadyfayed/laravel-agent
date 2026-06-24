# Laravel Queue Jobs & Dispatching Reference

Queued job structure, dispatching, uniqueness, rate limiting, middleware, queue configuration, and workers.

## Structure

```
app/
├── Jobs/
│   └── Process<Name>Job.php
├── Events/
│   └── <Name>Event.php
├── Listeners/
│   └── <Name>Listener.php
├── Notifications/
│   └── <Name>Notification.php
└── Broadcasting/
    └── <Name>Channel.php
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

### Dispatching Jobs (agent)

```php
// Basic dispatch
ProcessOrderJob::dispatch($order);

// With delay
ProcessOrderJob::dispatch($order)->delay(now()->addMinutes(5));

// On specific queue
ProcessOrderJob::dispatch($order)->onQueue('high');

// On specific connection
ProcessOrderJob::dispatch($order)->onConnection('redis');

// After response sent
ProcessOrderJob::dispatchAfterResponse($order);

// Conditionally
ProcessOrderJob::dispatchIf($condition, $order);
ProcessOrderJob::dispatchUnless($condition, $order);

// Synchronously (for testing)
ProcessOrderJob::dispatchSync($order);
```

## Richer Queued Job (ProcessOrderJob, agent)

```php
<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\Middleware\RateLimited;
use Illuminate\Support\Facades\Log;
use Throwable;

final class ProcessOrderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Number of times the job may be attempted.
     */
    public int $tries = 3;

    /**
     * Number of seconds to wait before retrying.
     */
    public array $backoff = [10, 60, 300]; // 10s, 1m, 5m

    /**
     * Maximum exceptions before failing.
     */
    public int $maxExceptions = 2;

    /**
     * Timeout in seconds.
     */
    public int $timeout = 120;

    /**
     * Unique job lock duration.
     */
    public int $uniqueFor = 3600; // 1 hour

    public function __construct(
        public readonly Order $order,
        public readonly array $options = [],
    ) {}

    /**
     * Job middleware.
     */
    public function middleware(): array
    {
        return [
            new WithoutOverlapping($this->order->id),
            new RateLimited('orders'),
        ];
    }

    /**
     * Unique ID for preventing duplicates.
     */
    public function uniqueId(): string
    {
        return (string) $this->order->id;
    }

    public function handle(): void
    {
        Log::info('Processing order', ['order_id' => $this->order->id]);

        // Process the order
        $this->order->process();

        // Dispatch follow-up events
        event(new OrderProcessedEvent($this->order));
    }

    /**
     * Handle job failure.
     */
    public function failed(?Throwable $exception): void
    {
        Log::error('Order processing failed', [
            'order_id' => $this->order->id,
            'error' => $exception?->getMessage(),
        ]);

        // Notify admins
        $this->order->update(['status' => 'failed']);

        // Send notification
        $this->order->customer->notify(
            new OrderFailedNotification($this->order, $exception)
        );
    }

    /**
     * Determine if job should be unique.
     */
    public function shouldBeUnique(): bool
    {
        return true;
    }

    /**
     * Tags for Horizon.
     */
    public function tags(): array
    {
        return [
            'order',
            'order:' . $this->order->id,
            'customer:' . $this->order->customer_id,
        ];
    }
}
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

### Rate Limiting (agent)

```php
// AppServiceProvider
RateLimiter::for('orders', function ($job) {
    return Limit::perMinute(100);
});

// In job middleware
public function middleware(): array
{
    return [new RateLimited('orders')];
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
