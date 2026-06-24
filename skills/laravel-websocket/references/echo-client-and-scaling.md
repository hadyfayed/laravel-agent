# Laravel Echo Client and Scaling Reference

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

## Presence Channel — Full (from agent)

```javascript
// Join presence channel for chat
Echo.join(`chat.${roomId}`)
    .here((users) => {
        // Called when successfully joined
        // users = array of all users in channel
        this.onlineUsers = users;
    })
    .joining((user) => {
        // Called when new user joins
        this.onlineUsers.push(user);
        showToast(`${user.name} joined the chat`);
    })
    .leaving((user) => {
        // Called when user leaves
        this.onlineUsers = this.onlineUsers.filter(u => u.id !== user.id);
        showToast(`${user.name} left the chat`);
    })
    .listen('.message.sent', (e) => {
        // Handle new message
        this.messages.push(e);
    })
    .error((error) => {
        console.error('Channel error:', error);
    });
```

## Whisper (Client-to-Client)

```javascript
// Typing indicator (doesn't go through server)
const channel = Echo.join(`chat.${roomId}`);

// Send whisper
channel.whisper('typing', {
    user: currentUser.name
});

// Listen for whispers
channel.listenForWhisper('typing', (e) => {
    showTypingIndicator(e.user);
});
```

## Livewire Integration

### Real-time Component

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

### Chat Box Component (from agent)

```php
<?php

declare(strict_types=1);

namespace App\Livewire;

use App\Events\MessageSent;
use App\Models\ChatRoom;
use App\Models\Message;
use Livewire\Attributes\On;
use Livewire\Component;

final class ChatBox extends Component
{
    public ChatRoom $room;
    public string $message = '';
    public array $messages = [];

    public function mount(ChatRoom $room): void
    {
        $this->room = $room;
        $this->messages = $room->messages()
            ->with('user')
            ->latest()
            ->take(50)
            ->get()
            ->reverse()
            ->values()
            ->toArray();
    }

    public function getListeners(): array
    {
        return [
            "echo-presence:chat.{$this->room->id},.message.sent" => 'onMessageReceived',
            "echo-presence:chat.{$this->room->id},here" => 'onUsersHere',
            "echo-presence:chat.{$this->room->id},joining" => 'onUserJoined',
            "echo-presence:chat.{$this->room->id},leaving" => 'onUserLeft',
        ];
    }

    public function sendMessage(): void
    {
        $this->validate(['message' => 'required|max:1000']);

        $message = Message::create([
            'chat_room_id' => $this->room->id,
            'user_id' => auth()->id(),
            'content' => $this->message,
        ]);

        broadcast(new MessageSent($this->room, auth()->user(), $this->message))->toOthers();

        $this->messages[] = $message->toArray();
        $this->message = '';
    }

    public function onMessageReceived(array $payload): void
    {
        $this->messages[] = $payload;
    }

    public function render()
    {
        return view('livewire.chat-box');
    }
}
```

### Blade Template with Echo

```blade
<div
    x-data="{
        onlineUsers: @entangle('onlineUsers'),
        isTyping: false,
        typingUser: ''
    }"
    x-init="
        Echo.join('chat.{{ $room->id }}')
            .here(users => onlineUsers = users)
            .joining(user => onlineUsers.push(user))
            .leaving(user => onlineUsers = onlineUsers.filter(u => u.id !== user.id))
            .listenForWhisper('typing', e => {
                typingUser = e.user;
                isTyping = true;
                setTimeout(() => isTyping = false, 3000);
            })
    "
>
    <!-- Online users -->
    <div class="flex gap-2 mb-4">
        <template x-for="user in onlineUsers" :key="user.id">
            <span class="px-2 py-1 bg-green-100 text-green-800 rounded-full text-sm" x-text="user.name"></span>
        </template>
    </div>

    <!-- Messages -->
    <div class="space-y-2 h-96 overflow-y-auto">
        @foreach($messages as $msg)
            <div class="p-2 rounded {{ $msg['user_id'] === auth()->id() ? 'bg-blue-100 ml-auto' : 'bg-gray-100' }} max-w-xs">
                <p class="text-sm font-semibold">{{ $msg['user']['name'] }}</p>
                <p>{{ $msg['content'] }}</p>
            </div>
        @endforeach
    </div>

    <!-- Typing indicator -->
    <div x-show="isTyping" x-transition class="text-sm text-gray-500">
        <span x-text="typingUser"></span> is typing...
    </div>

    <!-- Input -->
    <form wire:submit="sendMessage" class="mt-4 flex gap-2">
        <input
            type="text"
            wire:model="message"
            @input="Echo.join('chat.{{ $room->id }}').whisper('typing', { user: '{{ auth()->user()->name }}' })"
            class="flex-1 rounded border p-2"
            placeholder="Type a message..."
        >
        <button type="submit" class="px-4 py-2 bg-blue-500 text-white rounded">Send</button>
    </form>
</div>
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

## Nginx Configuration (WebSocket proxy)

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

### Nginx Proxy with TLS (from agent)

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream reverb {
    server 127.0.0.1:8080;
}

server {
    listen 443 ssl;
    server_name ws.yourapp.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://reverb;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
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

## Scaling WebSockets

### Reverb Config (horizontal scaling, from skill)

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

### Reverb Config with Redis (from agent)

```php
// config/reverb.php
'apps' => [
    [
        'app_id' => env('REVERB_APP_ID'),
        'app_key' => env('REVERB_APP_KEY'),
        'app_secret' => env('REVERB_APP_SECRET'),
        'options' => [
            'host' => env('REVERB_HOST'),
            'port' => env('REVERB_PORT', 443),
            'scheme' => env('REVERB_SCHEME', 'https'),
        ],
        'allowed_origins' => ['*'],
        'ping_interval' => 60,
        'max_message_size' => 10_000,
    ],
],

'scaling' => [
    'enabled' => env('REVERB_SCALING_ENABLED', true),
    'channel' => env('REVERB_SCALING_CHANNEL', 'reverb'),
    'server' => [
        'url' => env('REDIS_URL'),
        'host' => env('REDIS_HOST', '127.0.0.1'),
        'port' => env('REDIS_PORT', 6379),
        'database' => env('REDIS_DB', 0),
        'password' => env('REDIS_PASSWORD'),
    ],
],
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

## Guardrails

- **NEVER** expose sensitive data in broadcasts
- **ALWAYS** authorize private/presence channels
- **ALWAYS** validate data before broadcasting
- **PREFER** queued broadcasts for non-critical updates
- **USE** `toOthers()` to exclude sender from broadcast
