---
name: broadcast-make
description: Generate a broadcast event + channel wiring for real-time updates; when adding broadcasting.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Read Write Edit
argument-hint: "<EventName> [public|private|presence] [channel-pattern]"
---

## Task

Generate a broadcast event with channel authorization and client-ready usage examples.

## Input

- **EventName:** Pascal-cased event name (e.g., `OrderUpdated`, `MessageSent`, `UserJoined`)
- **Channel type:** Broadcast channel scope (default: `public`)
  - `public` — Any client can listen; no authorization
  - `private` — User must be authorized; channel name pattern like `user.{id}`
  - `presence` — Like private, but broadcasts presence (joins/leaves); e.g., `chat.{roomId}`
- **Channel pattern:** Broadcast channel name with optional placeholders (e.g., `order.{id}`, `user.{userId}.notifications`)

## Steps

1. **Create the event** in `app/Events/<EventName>.php`:
   ```bash
   php artisan make:event <EventName>
   ```
   Implement `ShouldBroadcast` and set `broadcastOn()` to return the appropriate channel type.

2. **Add channel authorization** (if private or presence type):
   Edit `routes/channels.php` to add authorization logic:
   ```php
   Broadcast::private('user.{id}', function ($user, $id) {
       return $user->id === (int) $id;
   });
   ```

3. **Dispatch the event** in your application code:
   ```php
   broadcast(new OrderUpdated($order));
   broadcast(new MessageSent($message))->toOthers(); // exclude sender
   ```

4. **Wire the client listener** (JavaScript/Livewire):
   ```javascript
   Echo.private('user.123')
       .listen('.order-updated', (e) => {
           console.log('Order updated:', e);
       });
   ```

## Reference

For deep broadcasting patterns (presence channels, private channels, authentication, connection strategies), see the `laravel-websocket` reference skill in the plugin.

## Broadcasting best practices

- Use `toOthers()` to exclude the sender when broadcasting user actions
- Leverage presence channels for real-time user activity (typing indicators, online status)
- Authorize private channels to prevent unauthorized listeners
- Use queue broadcasting in production for better performance
- Test broadcasting with fake() in tests

## Reverb/Pusher config

Update `.env`:
```env
BROADCAST_DRIVER=reverb
REVERB_APP_ID=app-id
REVERB_APP_KEY=app-key
REVERB_APP_SECRET=app-secret
REVERB_HOST=localhost
REVERB_PORT=8080
```

Or for Pusher:
```env
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=app-id
PUSHER_APP_KEY=app-key
PUSHER_APP_SECRET=app-secret
PUSHER_APP_CLUSTER=mt1
```
