# Laravel Queue Batches, Chains, Events, Notifications & Horizon Reference

Job batching, chains, events/listeners, notifications (multi-channel), broadcasting, scheduled tasks, Laravel Prompts artisan commands, and Horizon.

## Contents

- [Job Batching](#job-batching)
- [Job Chains](#job-chains)
- [Events & Listeners](#events--listeners)
- [Notifications](#notifications)
- [Laravel Notification Channels](#laravel-notification-channels)
- [Broadcast Queue Events](#broadcast-queue-events)
- [Broadcasting (WebSockets)](#broadcasting-websockets)
- [Scheduled Tasks](#scheduled-tasks)
- [Artisan Commands with Laravel Prompts](#artisan-commands-with-laravel-prompts)
- [Laravel Horizon (Queue Dashboard)](#laravel-horizon-queue-dashboard)

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

### Job Batches (agent)

```php
use Illuminate\Bus\Batch;
use Illuminate\Support\Facades\Bus;

$batch = Bus::batch([
    new ProcessOrderJob($order1),
    new ProcessOrderJob($order2),
    new ProcessOrderJob($order3),
])
->then(function (Batch $batch) {
    // All jobs completed successfully
    Log::info('Batch completed', ['batch_id' => $batch->id]);
})
->catch(function (Batch $batch, Throwable $e) {
    // First job failure
    Log::error('Batch failed', ['batch_id' => $batch->id, 'error' => $e->getMessage()]);
})
->finally(function (Batch $batch) {
    // Batch finished (success or failure)
})
->allowFailures()
->name('Process Orders')
->onQueue('batches')
->dispatch();

// Check batch status
$batch = Bus::findBatch($batchId);
$batch->progress(); // 0-100
$batch->finished();
$batch->cancelled();
```

## Job Chains

```php
Bus::chain([
    new ValidateOrderJob($order),
    new ProcessPaymentJob($order),
    new FulfillOrderJob($order),
    new SendConfirmationJob($order),
])
->onQueue('orders')
->catch(function (Throwable $e) {
    // Handle chain failure
})
->dispatch();
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

### Event (OrderCreatedEvent, ShouldBroadcast, agent)

```php
<?php

declare(strict_types=1);

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

final class OrderCreatedEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Order $order,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('orders.' . $this->order->customer_id),
            new PrivateChannel('admin.orders'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'order.created';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->order->id,
            'total' => $this->order->total_formatted,
            'status' => $this->order->status,
        ];
    }
}
```

### Listener (queued, agent)

```php
<?php

declare(strict_types=1);

namespace App\Listeners;

use App\Events\OrderCreatedEvent;
use App\Notifications\NewOrderNotification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;

final class SendOrderNotificationListener implements ShouldQueue
{
    use InteractsWithQueue;

    public string $queue = 'notifications';

    public function handle(OrderCreatedEvent $event): void
    {
        // Notify customer
        $event->order->customer->notify(
            new NewOrderNotification($event->order)
        );

        // Notify admins
        $admins = User::role('admin')->get();
        Notification::send($admins, new NewOrderNotification($event->order));
    }

    public function shouldQueue(OrderCreatedEvent $event): bool
    {
        return $event->order->total_cents > 10000; // Only for orders > $100
    }

    public function viaQueue(): string
    {
        return 'notifications';
    }

    public function failed(OrderCreatedEvent $event, Throwable $exception): void
    {
        Log::error('Failed to send order notification', [
            'order_id' => $event->order->id,
            'error' => $exception->getMessage(),
        ]);
    }
}
```

### Registration

```php
// EventServiceProvider or bootstrap/app.php
protected $listen = [
    OrderCreatedEvent::class => [
        SendOrderNotificationListener::class,
        UpdateInventoryListener::class,
        LogOrderListener::class,
    ],
];

// Or auto-discovery
// Listeners in App\Listeners with handle(EventClass $event)
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

## Laravel Notification Channels

55+ notification channels available at https://laravel-notification-channels.com/

### Popular Channels
| Channel | Package | Use Case |
|---------|---------|----------|
| Telegram | laravel-notification-channels/telegram | Bot alerts |
| Discord | laravel-notification-channels/discord | Team notifications |
| Twilio | laravel-notification-channels/twilio | SMS |
| Slack | Built-in | Team notifications |
| FCM | laravel-notification-channels/fcm | Mobile push |
| WebPush | laravel-notification-channels/webpush | Browser push |
| Teams | laravel-notification-channels/microsoft-teams | Enterprise |

### Install Channel
```bash
composer require laravel-notification-channels/telegram
composer require laravel-notification-channels/discord
composer require laravel-notification-channels/twilio
```

### Multi-channel Notification (agent)

```php
<?php

declare(strict_types=1);

namespace App\Notifications;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\VonageMessage;
use Illuminate\Notifications\Notification;
use NotificationChannels\Telegram\TelegramMessage;
use NotificationChannels\Discord\DiscordMessage;
use NotificationChannels\Twilio\TwilioSmsMessage;

final class OrderShippedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly Order $order,
    ) {}

    public function via(object $notifiable): array
    {
        $channels = ['mail', 'database'];

        if ($notifiable->phone) {
            $channels[] = 'vonage'; // SMS
        }

        if ($notifiable->prefers_push) {
            $channels[] = 'broadcast';
        }

        return $channels;
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Your Order Has Shipped!')
            ->greeting('Hello ' . $notifiable->name . '!')
            ->line('Great news! Your order #' . $this->order->number . ' has shipped.')
            ->line('Tracking number: ' . $this->order->tracking_number)
            ->action('Track Order', url('/orders/' . $this->order->id))
            ->line('Thank you for shopping with us!');
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'order_id' => $this->order->id,
            'message' => 'Your order #' . $this->order->number . ' has shipped.',
            'tracking_number' => $this->order->tracking_number,
        ];
    }

    public function toBroadcast(object $notifiable): BroadcastMessage
    {
        return new BroadcastMessage([
            'order_id' => $this->order->id,
            'message' => 'Your order has shipped!',
        ]);
    }

    public function toVonage(object $notifiable): VonageMessage
    {
        return (new VonageMessage)
            ->content('Your order #' . $this->order->number . ' has shipped! Track: ' . $this->order->tracking_url);
    }

    /**
     * Telegram notification (laravel-notification-channels/telegram)
     */
    public function toTelegram(object $notifiable): TelegramMessage
    {
        return TelegramMessage::create()
            ->to($notifiable->telegram_chat_id)
            ->content("*Order Shipped!*\n\nYour order #{$this->order->number} has shipped.")
            ->button('Track Order', $this->order->tracking_url);
    }

    /**
     * Discord notification (laravel-notification-channels/discord)
     */
    public function toDiscord(object $notifiable): DiscordMessage
    {
        return DiscordMessage::create()
            ->body("Order #{$this->order->number} has shipped!")
            ->embed([
                'title' => 'Order Details',
                'description' => "Tracking: {$this->order->tracking_number}",
                'color' => 0x00FF00,
                'fields' => [
                    ['name' => 'Customer', 'value' => $notifiable->name, 'inline' => true],
                    ['name' => 'Total', 'value' => $this->order->total_formatted, 'inline' => true],
                ],
            ]);
    }

    /**
     * Twilio SMS notification (laravel-notification-channels/twilio)
     */
    public function toTwilio(object $notifiable): TwilioSmsMessage
    {
        return (new TwilioSmsMessage)
            ->content("Your order #{$this->order->number} has shipped! Track: {$this->order->tracking_url}");
    }

    public function shouldSend(object $notifiable, string $channel): bool
    {
        return $notifiable->notification_preferences[$channel] ?? true;
    }
}
```

### User Model for Notification Channels

Add routing methods to User model for each channel:

```php
class User extends Authenticatable
{
    use Notifiable;

    /**
     * Route for Telegram notifications.
     */
    public function routeNotificationForTelegram(): ?string
    {
        return $this->telegram_chat_id;
    }

    /**
     * Route for Discord notifications.
     */
    public function routeNotificationForDiscord(): ?string
    {
        return $this->discord_webhook_url ?? config('services.discord.webhook');
    }

    /**
     * Route for Twilio SMS notifications.
     */
    public function routeNotificationForTwilio(): ?string
    {
        return $this->phone;
    }

    /**
     * Route for Vonage SMS notifications.
     */
    public function routeNotificationForVonage(): ?string
    {
        return $this->phone;
    }
}
```

### Sending Notifications

```php
// To single user
$user->notify(new OrderShippedNotification($order));

// To multiple users
Notification::send($users, new OrderShippedNotification($order));

// On-demand (no user model)
Notification::route('mail', 'guest@example.com')
    ->route('vonage', '5551234567')
    ->notify(new OrderShippedNotification($order));
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

## Broadcasting (WebSockets)

### Channel Authorization
```php
// routes/channels.php
Broadcast::channel('orders.{customerId}', function ($user, $customerId) {
    return $user->id === (int) $customerId;
});

Broadcast::channel('admin.orders', function ($user) {
    return $user->hasRole('admin');
});

// Presence channel
Broadcast::channel('chat.{roomId}', function ($user, $roomId) {
    if ($user->canJoinRoom($roomId)) {
        return ['id' => $user->id, 'name' => $user->name];
    }
});
```

### Frontend (Echo)
```javascript
// Listen to private channel
Echo.private(`orders.${userId}`)
    .listen('.order.created', (e) => {
        console.log('New order:', e);
    });

// Presence channel
Echo.join(`chat.${roomId}`)
    .here((users) => {
        // Initial users
    })
    .joining((user) => {
        // User joined
    })
    .leaving((user) => {
        // User left
    })
    .listen('MessageSent', (e) => {
        // New message
    });
```

## Scheduled Tasks

```php
// app/Console/Kernel.php or bootstrap/app.php
$schedule->job(new ProcessPendingOrdersJob)->everyFiveMinutes();
$schedule->job(new CleanupExpiredCartsJob)->daily();
$schedule->job(new SendWeeklyReportJob)->weekly()->mondays()->at('9:00');

// With conditions
$schedule->job(new BackupDatabaseJob)
    ->daily()
    ->environments(['production'])
    ->onOneServer()
    ->runInBackground();

// Custom command
$schedule->command('orders:process-pending')
    ->everyMinute()
    ->withoutOverlapping()
    ->appendOutputTo(storage_path('logs/orders.log'));
```

## Artisan Commands with Laravel Prompts

If `laravel/prompts` is available (Laravel 10.17+), use beautiful CLI interfaces:

```php
<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Jobs\ProcessOrderJob;
use Illuminate\Console\Command;
use function Laravel\Prompts\confirm;
use function Laravel\Prompts\info;
use function Laravel\Prompts\multiselect;
use function Laravel\Prompts\progress;
use function Laravel\Prompts\select;
use function Laravel\Prompts\spin;
use function Laravel\Prompts\table;
use function Laravel\Prompts\warning;

final class ProcessOrdersCommand extends Command
{
    protected $signature = 'orders:process {--all : Process all pending orders}';
    protected $description = 'Process pending orders with interactive prompts';

    public function handle(): int
    {
        // Select queue
        $queue = select(
            label: 'Which queue should jobs be dispatched to?',
            options: ['default', 'high', 'low'],
            default: 'default'
        );

        // Multi-select statuses
        $statuses = multiselect(
            label: 'Which order statuses should be processed?',
            options: ['pending', 'processing', 'failed'],
            default: ['pending'],
            required: true,
        );

        $orders = Order::whereIn('status', $statuses)->get();

        if ($orders->isEmpty()) {
            warning('No orders found matching criteria.');
            return self::SUCCESS;
        }

        // Show preview table
        table(
            headers: ['ID', 'Customer', 'Total', 'Status'],
            rows: $orders->map(fn ($o) => [$o->id, $o->customer->name, $o->total_formatted, $o->status])
        );

        // Confirm action
        if (!confirm("Process {$orders->count()} orders?", default: false)) {
            info('Operation cancelled.');
            return self::SUCCESS;
        }

        // Progress bar for batch processing
        $results = progress(
            label: 'Processing orders...',
            steps: $orders,
            callback: function ($order) use ($queue) {
                ProcessOrderJob::dispatch($order)->onQueue($queue);
                return $order->id;
            }
        );

        // Or use spinner for single long operation
        $result = spin(
            message: 'Generating report...',
            callback: fn () => $this->generateReport($orders)
        );

        info("Successfully dispatched {$orders->count()} orders to '{$queue}' queue.");

        return self::SUCCESS;
    }
}
```

### Available Prompts Functions
```php
use function Laravel\Prompts\text;        // Single line input
use function Laravel\Prompts\textarea;    // Multi-line input
use function Laravel\Prompts\password;    // Hidden input
use function Laravel\Prompts\confirm;     // Yes/No
use function Laravel\Prompts\select;      // Single choice
use function Laravel\Prompts\multiselect; // Multiple choices
use function Laravel\Prompts\suggest;     // Auto-complete
use function Laravel\Prompts\search;      // Searchable list
use function Laravel\Prompts\progress;    // Progress bar
use function Laravel\Prompts\spin;        // Spinner
use function Laravel\Prompts\table;       // Display table
use function Laravel\Prompts\info;        // Info message
use function Laravel\Prompts\warning;     // Warning message
use function Laravel\Prompts\error;       // Error message
use function Laravel\Prompts\alert;       // Alert box
use function Laravel\Prompts\note;        // Note box
```

## Laravel Horizon (Queue Dashboard)

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

### Horizon Setup (agent)

```bash
composer require laravel/horizon
php artisan horizon:install
php artisan migrate
```

### Horizon Configuration (config/horizon.php, agent)

```php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default', 'high'],
            'balance' => 'auto',
            'minProcesses' => 1,
            'maxProcesses' => 10,
            'balanceMaxShift' => 1,
            'balanceCooldown' => 3,
            'tries' => 3,
        ],
        'supervisor-2' => [
            'connection' => 'redis',
            'queue' => ['notifications'],
            'balance' => 'simple',
            'processes' => 3,
            'tries' => 3,
        ],
    ],
    'local' => [
        'supervisor-1' => [
            'connection' => 'redis',
            'queue' => ['default', 'high', 'notifications'],
            'balance' => 'simple',
            'processes' => 3,
            'tries' => 3,
        ],
    ],
],
```

### Dashboard Authorization
```php
// app/Providers/HorizonServiceProvider.php
protected function gate(): void
{
    Gate::define('viewHorizon', function ($user) {
        return in_array($user->email, [
            'admin@example.com',
        ]) || $user->hasRole('admin');
    });
}
```

### Horizon Commands
```bash
# Start Horizon
php artisan horizon

# Pause processing
php artisan horizon:pause

# Resume processing
php artisan horizon:continue

# Terminate gracefully
php artisan horizon:terminate

# View status
php artisan horizon:status

# Clear failed jobs
php artisan horizon:clear

# List supervisors
php artisan horizon:supervisors
```

### Horizon Metrics & Tags
```php
final class ProcessOrderJob implements ShouldQueue
{
    /**
     * Tags for Horizon filtering.
     */
    public function tags(): array
    {
        return [
            'order',
            'order:' . $this->order->id,
            'customer:' . $this->order->customer_id,
            'priority:' . ($this->order->is_priority ? 'high' : 'normal'),
        ];
    }

    /**
     * Display name in Horizon dashboard.
     */
    public function displayName(): string
    {
        return 'Process Order #' . $this->order->number;
    }
}
```

### Horizon Notifications (Slack/SMS)
```php
// config/horizon.php
'waits' => [
    'redis:default' => 60,      // Alert if jobs wait > 60 seconds
    'redis:high' => 30,
    'redis:notifications' => 120,
],

// HorizonServiceProvider
Horizon::routeSlackNotificationsTo('https://hooks.slack.com/...', '#alerts');
Horizon::routeMailNotificationsTo('alerts@example.com');
Horizon::routeSmsNotificationsTo('1234567890');
```

### Horizon with Supervisor (Production)
```ini
; /etc/supervisor/conf.d/horizon.conf
[program:horizon]
process_name=%(program_name)s
command=php /var/www/app/artisan horizon
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/app/storage/logs/horizon.log
stopwaitsecs=3600
```
