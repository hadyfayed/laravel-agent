# Echo Client Setup

## Installation

```bash
npm install laravel-echo pusher-js
```

## Basic Echo Configuration

Create `resources/js/echo.js`:

```javascript
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

## Environment Variables

Add to `.env`:

```env
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=laravel-app
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
```

Add to `vite.config.js` or use environment variables directly:

```javascript
export default defineConfig({
    plugins: [
        laravel({
            input: 'resources/js/app.js',
            refresh: true,
        }),
    ],
});
```

Reference in Vite:

```env
VITE_REVERB_APP_KEY=your-app-key
VITE_REVERB_HOST=localhost
VITE_REVERB_PORT=8080
VITE_REVERB_SCHEME=http
```

## Listening to Channels

### Public Channel

```javascript
Echo.channel('notifications')
    .listen('OrderShipped', (event) => {
        console.log('Order shipped!', event);
    });
```

### Private Channel

```javascript
Echo.private('chat.123')
    .listen('NewMessage', (event) => {
        console.log('New message:', event.message);
    });
```

### Presence Channel

```javascript
Echo.join('users.online')
    .here((users) => {
        console.log('Users online:', users);
    })
    .joining((user) => {
        console.log('User joined:', user);
    })
    .leaving((user) => {
        console.log('User left:', user);
    })
    .listen('ActivityUpdate', (event) => {
        console.log('Activity:', event);
    });
```

## Whisper (Client-to-Server Messaging)

Send a whisper without broadcasting to others:

```javascript
Echo.private('chat.123')
    .whisper('typing', {
        name: 'John',
    });
```

Listen to whispers:

```javascript
Echo.private('chat.123')
    .listenForWhisper('typing', (event) => {
        console.log('User is typing...', event.name);
    });
```

## Authentication

Echo automatically sends CSRF token for private/presence channels:

```javascript
// Config automatically includes CSRF token in headers
window.Echo = new Echo({
    broadcaster: 'reverb',
    // ... other config
    authEndpoint: '/broadcasting/auth', // default
});
```

## Disconnection and Reconnection

Echo handles reconnection automatically. For custom handling:

```javascript
Echo.connector.socket.on('connect', () => {
    console.log('Connected to WebSocket server');
});

Echo.connector.socket.on('disconnect', () => {
    console.log('Disconnected from WebSocket server');
});

Echo.connector.socket.on('reconnect', () => {
    console.log('Reconnected to WebSocket server');
});
```

## Integration with Blade/Livewire

Include Echo in your main Blade layout:

```blade
@import('resources/js/echo.js')
```

Or in `resources/js/app.js`:

```javascript
import './echo.js';
```

For Livewire components:

```blade
<script>
    Livewire.on('eventName', (payload) => {
        // Handle event
    });
</script>
```

## Debugging

Enable Pusher debugging:

```javascript
window.Pusher = Pusher;
Pusher.logToConsole = true; // Enable in development
```

Check browser console for connection status and events.
