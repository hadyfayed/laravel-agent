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

## Best Practices

- Use private channels for sensitive data
- Authorize channel access properly
- Keep broadcast payloads small
- Use presence channels for user lists
- Handle reconnection on the frontend
- Monitor WebSocket connections
