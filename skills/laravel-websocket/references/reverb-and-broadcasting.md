# Laravel Reverb and Broadcasting Reference

## Installation

```bash
composer require laravel/reverb
php artisan reverb:install
```

## Configuration

### Environment Variables

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=my-app
REVERB_APP_KEY=my-key
REVERB_APP_SECRET=my-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http

# For production
REVERB_HOST="your-domain.com"
REVERB_PORT=443
REVERB_SCHEME=https

VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

### Broadcasting Config (from agent)

```php
// config/broadcasting.php
'connections' => [
    'reverb' => [
        'driver' => 'reverb',
        'key' => env('REVERB_APP_KEY'),
        'secret' => env('REVERB_APP_SECRET'),
        'app_id' => env('REVERB_APP_ID'),
        'options' => [
            'host' => env('REVERB_HOST'),
            'port' => env('REVERB_PORT', 443),
            'scheme' => env('REVERB_SCHEME', 'https'),
            'useTLS' => env('REVERB_SCHEME', 'https') === 'https',
        ],
        'client_options' => [
            // Guzzle client options
        ],
    ],
],
```

## Broadcasting Events

### Private Channel Event (from skill)

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

final class OrderStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly Order $order
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("orders.{$this->order->user_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'order.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->order->id,
            'status' => $this->order->status,
            'updated_at' => $this->order->updated_at->toISOString(),
        ];
    }
}
```

### Public Channel Event (from agent)

```php
<?php

declare(strict_types=1);

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

final class OrderStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly int $orderId,
        public readonly string $status,
        public readonly string $message,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new Channel('orders'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'order.status.updated';
    }

    public function broadcastWith(): array
    {
        return [
            'order_id' => $this->orderId,
            'status' => $this->status,
            'message' => $this->message,
            'timestamp' => now()->toIso8601String(),
        ];
    }
}
```

### Private Channel Event — Notification (from agent)

```php
<?php

declare(strict_types=1);

namespace App\Events;

use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

final class NotificationReceived implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly User $user,
        public readonly string $title,
        public readonly string $body,
        public readonly string $type = 'info',
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('user.' . $this->user->id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'notification.received';
    }
}
```

### Presence Channel Event — Message (from agent)

```php
<?php

declare(strict_types=1);

namespace App\Events;

use App\Models\ChatRoom;
use App\Models\User;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

final class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly ChatRoom $room,
        public readonly User $user,
        public readonly string $message,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PresenceChannel('chat.' . $this->room->id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    public function broadcastWith(): array
    {
        return [
            'user' => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'avatar' => $this->user->avatar_url,
            ],
            'message' => $this->message,
            'sent_at' => now()->toIso8601String(),
        ];
    }
}
```

## Queue Broadcast Events

```php
final class MessageSent implements ShouldBroadcast, ShouldQueue
{
    use Dispatchable, InteractsWithSockets, SerializesModels;
    use InteractsWithQueue; // For queue features

    public $afterCommit = true; // Wait for DB transaction

    public function __construct(
        public readonly Message $message
    ) {}

    public function broadcastQueue(): string
    {
        return 'broadcasts';
    }
}
```

## Broadcast to Specific Users

```php
// Using toOthers() to exclude sender
event((new MessageSent($message))->dontBroadcastToCurrentUser());

// Or in the event
public function broadcastWith(): array
{
    return [
        'message' => $this->message,
        'sender_id' => auth()->id(),
    ];
}

// Broadcast to specific users
Broadcast::private('App.Models.User.' . $userId)
    ->with(['notification' => $notification])
    ->via(new NotificationReceived($notification));
```

## Common Patterns

### Real-time Notifications

```php
// Notify user via broadcast
$user->notify(new OrderShipped($order));

// In notification class
public function toBroadcast($notifiable): BroadcastMessage
{
    return new BroadcastMessage([
        'title' => 'Order Shipped',
        'body' => "Your order #{$this->order->number} has shipped!",
        'action_url' => route('orders.show', $this->order),
    ]);
}
```

### Live Dashboard Updates

```php
// Dispatch from anywhere
broadcast(new DashboardUpdated([
    'metric' => 'revenue',
    'value' => $newRevenue,
    'change' => $percentChange,
]))->toOthers();
```

### Activity Feed

```php
// After any action
event(new ActivityLogged(
    user: auth()->user(),
    action: 'created',
    subject: $invoice,
    description: "Created invoice #{$invoice->number}"
));
```

## Testing Broadcasting

```php
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Broadcast;

it('broadcasts order updated event', function () {
    Event::fake();

    $order = Order::factory()->create();
    $order->update(['status' => 'shipped']);

    Event::assertDispatched(OrderStatusUpdated::class, function ($event) use ($order) {
        return $event->order->id === $order->id;
    });
});

it('broadcasts to correct channel', function () {
    $order = Order::factory()->create();
    $event = new OrderStatusUpdated($order);

    expect($event->broadcastOn())
        ->toHaveCount(1)
        ->sequence(
            fn ($channel) => $channel->name->toBe("private-orders.{$order->user_id}")
        );
});
```
