# Laravel Queue Retries, Failure Handling & Testing Reference

Testing queued jobs, retry/backoff/timeout configuration, failure handling, common pitfalls, and best practices.

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
