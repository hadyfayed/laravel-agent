---
name: laravel-websocket
description: >
  Implement real-time features with Laravel Reverb and WebSockets. Use when the user
  needs real-time updates, live notifications, chat, or broadcasting. Triggers:
  "websocket", "real-time", "realtime", "live", "broadcast", "Reverb", "pusher",
  "socket", "chat", "notifications live".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel WebSocket Skill

Implement real-time features with Laravel Reverb.

## When to Use

- Real-time notifications
- Live chat applications
- Live dashboards
- Collaborative editing
- Real-time data updates

## Quick Start

```bash
/laravel-agent:reverb:setup
```

## Installation

```bash
composer require laravel/reverb
php artisan reverb:install
```

## Configuration

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=my-app
REVERB_APP_KEY=my-key
REVERB_APP_SECRET=my-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http

VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

## Broadcasting Events

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

## Channel Authorization

```php
// routes/channels.php

use Illuminate\Support\Facades\Broadcast;

// Private channel
Broadcast::channel('orders.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Presence channel
Broadcast::channel('chat.{roomId}', function ($user, $roomId) {
    if ($user->canJoinRoom($roomId)) {
        return ['id' => $user->id, 'name' => $user->name];
    }
});
```

## Frontend (Laravel Echo)

```bash
npm install laravel-echo pusher-js
```

```javascript
// resources/js/echo.js
import Echo from 'laravel-echo';
import Pusher from 'pusher-js';

window.Pusher = Pusher;

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: import.meta.env.VITE_REVERB_HOST,
    wsPort: import.meta.env.VITE_REVERB_PORT ?? 80,
    wssPort: import.meta.env.VITE_REVERB_PORT ?? 443,
    forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'https') === 'https',
    enabledTransports: ['ws', 'wss'],
});
```

## Listening to Events

```javascript
// Private channel
Echo.private(`orders.${userId}`)
    .listen('.order.updated', (e) => {
        console.log('Order updated:', e);
        updateOrderUI(e);
    });

// Presence channel (for user lists)
Echo.join(`chat.${roomId}`)
    .here((users) => {
        console.log('Users in room:', users);
    })
    .joining((user) => {
        console.log('User joined:', user);
    })
    .leaving((user) => {
        console.log('User left:', user);
    })
    .listen('.message.sent', (e) => {
        console.log('Message:', e);
    });

// Public channel
Echo.channel('news')
    .listen('.article.published', (e) => {
        console.log('New article:', e);
    });
```

## Livewire Integration

```php
<?php

namespace App\Livewire;

use Livewire\Component;
use Livewire\Attributes\On;

final class OrderTracker extends Component
{
    public Order $order;

    public function getListeners(): array
    {
        return [
            "echo-private:orders.{$this->order->user_id},.order.updated" => 'refreshOrder',
        ];
    }

    public function refreshOrder($payload): void
    {
        $this->order->refresh();
    }

    public function render()
    {
        return view('livewire.order-tracker');
    }
}
```

## Running Reverb

```bash
# Development
php artisan reverb:start

# Production (with Supervisor)
php artisan reverb:start --host=0.0.0.0 --port=8080
```

## Supervisor Configuration

```ini
[program:reverb]
command=php /var/www/html/artisan reverb:start --host=0.0.0.0 --port=8080
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/reverb.log
stopwaitsecs=3600
```

## Nginx Configuration

```nginx
# WebSocket proxy
location /app {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 86400;
}
```

## Client-Side Reconnection

```javascript
// Handle connection state
Echo.connector.pusher.connection.bind('state_change', (states) => {
    console.log('Connection state:', states.current);

    if (states.current === 'disconnected') {
        showReconnecting();
    }

    if (states.current === 'connected') {
        hideReconnecting();
        resubscribeChannels();
    }
});

// Manual reconnection
function reconnect() {
    Echo.connector.pusher.connect();
}

// Error handling
Echo.connector.pusher.connection.bind('error', (err) => {
    console.error('WebSocket error:', err);
    showError('Connection lost. Retrying...');
});
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

## Scaling WebSockets

```php
// config/reverb.php - for horizontal scaling
'scaling' => [
    'enabled' => true,
    'channel' => 'reverb',
],

// Use Redis for scaling across servers
'connections' => [
    'reverb' => [
        'driver' => 'reverb',
        'host' => env('REVERB_HOST'),
        'port' => env('REVERB_PORT'),
        'scheme' => env('REVERB_SCHEME', 'https'),
    ],
],
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

## Common Pitfalls

1. **Channel Authorization Fails** - Check route and logic
   ```php
   // routes/channels.php - route must be correct
   Broadcast::channel('orders.{orderId}', function ($user, $orderId) {
       // Must return true or array for presence
       return $user->orders()->where('id', $orderId)->exists();
   });
   ```

2. **Events Not Broadcasting** - Check implements ShouldBroadcast
   ```php
   // Missing interface!
   class OrderUpdated // Wrong
   class OrderUpdated implements ShouldBroadcast // Correct
   ```

3. **Frontend Not Receiving** - Check event name format
   ```javascript
   // Laravel broadcasts as: OrderUpdated
   // With broadcastAs: .order.updated (note the dot)

   // For default class name
   Echo.channel('orders').listen('OrderUpdated', (e) => {});

   // For custom broadcastAs
   Echo.channel('orders').listen('.order.updated', (e) => {});
   ```

4. **CORS Issues** - Configure allowed origins
   ```php
   // config/reverb.php
   'apps' => [
       [
           'allowed_origins' => ['http://localhost:3000', 'https://myapp.com'],
       ],
   ],
   ```

5. **Missing CSRF Token for Private Channels**
   ```javascript
   // Ensure token is set for auth
   window.Echo = new Echo({
       broadcaster: 'reverb',
       key: import.meta.env.VITE_REVERB_APP_KEY,
       authorizer: (channel, options) => {
           return {
               authorize: (socketId, callback) => {
                   axios.post('/broadcasting/auth', {
                       socket_id: socketId,
                       channel_name: channel.name,
                   }, {
                       headers: {
                           'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                       },
                   }).then(response => {
                       callback(null, response.data);
                   }).catch(error => {
                       callback(error);
                   });
               },
           };
       },
   });
   ```

6. **Large Payloads** - Keep broadcast data small
   ```php
   // Bad - sending entire model
   public function broadcastWith(): array
   {
       return ['order' => $this->order->toArray()];
   }

   // Good - send only needed data
   public function broadcastWith(): array
   {
       return [
           'id' => $this->order->id,
           'status' => $this->order->status,
       ];
   }
   ```

7. **Not Using afterCommit** - Events fire before DB commits
   ```php
   public $afterCommit = true; // Wait for transaction
   ```

## Best Practices

- Use private channels for sensitive data
- Authorize channel access properly
- Keep broadcast payloads small
- Use presence channels for user lists
- Handle reconnection on the frontend
- Monitor WebSocket connections
- Queue broadcast events for performance
- Use afterCommit for database-dependent events
- Test channel authorization thoroughly
