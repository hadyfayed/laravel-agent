---
name: laravel-websocket
description: Laravel real-time / WebSockets — Reverb server, broadcasting events, public/private/presence channels, Echo client, scaling with Redis; when building real-time features (chat, notifications, live updates). Use when the user mentions WebSockets, real-time, Reverb, broadcasting, Echo, presence channels, live chat, pusher, or socket.
---

# Laravel WebSocket Skill

Build real-time features with Laravel Reverb (the first-party WebSocket server) and the broadcasting layer. Events implement `ShouldBroadcast`; channels can be public, private (authorized), or presence (authorized members who share presence).

## When to Use

- Real-time notifications
- Live chat applications
- Live dashboards
- Collaborative editing
- Real-time data updates

## Quick Start

```bash
/laravel-agent:reverb:setup
# or manually:
composer require laravel/reverb
php artisan reverb:install
npm install laravel-echo pusher-js
```

## Conventions Checklist

### Events
- [ ] Implement `ShouldBroadcast` (or `ShouldBroadcastNow`)
- [ ] Return `Channel` / `PrivateChannel` / `PresenceChannel` from `broadcastOn()`
- [ ] Define `broadcastAs()` for custom event names (frontend listens with a leading dot)
- [ ] Keep `broadcastWith()` payload small — never send entire models
- [ ] Set `$afterCommit = true` when the event depends on committed DB state
- [ ] Implement `ShouldQueue` + `broadcastQueue()` for non-critical broadcasts

### Channels (`routes/channels.php`)
- [ ] Authorize every private/presence channel
- [ ] Return `bool` for private channels, an array of user data for presence channels
- [ ] Authorize against relationships — never trust client-supplied IDs alone

### Echo Client
- [ ] Configure `broadcaster: 'reverb'` with Vite env vars
- [ ] Listen with `.event.name` (leading dot) when `broadcastAs()` is set
- [ ] Handle reconnection states; use `toOthers()` to exclude the sender

### Operations
- [ ] Run Reverb under Supervisor in production (`reverb:start --host=0.0.0.0`)
- [ ] Proxy `/app` via Nginx with WebSocket upgrade headers
- [ ] Enable Redis scaling (`config/reverb.php` `scaling`) for multiple servers

## Common Pitfalls

1. **Events not broadcasting** — event must `implements ShouldBroadcast`
2. **Channel authorization fails** — route in `channels.php` missing or wrong logic
3. **Frontend not receiving** — event name format: `.order.updated` (dot) when using `broadcastAs`
4. **CORS** — set `allowed_origins` in `config/reverb.php`
5. **Missing CSRF token** — private channel auth needs the token header
6. **Large payloads** — send only needed fields, not `->toArray()`
7. **Events fire before commit** — use `$afterCommit = true`

## Guardrails

- **NEVER** expose sensitive data in broadcasts
- **ALWAYS** authorize private/presence channels
- **ALWAYS** validate data before broadcasting
- **PREFER** queued broadcasts for non-critical updates
- **USE** `toOthers()` to exclude sender from broadcast

## Related Commands

- `/laravel-agent:reverb:setup` — set up Laravel Reverb
- `/laravel-agent:broadcast:make` — create broadcast events

## Related Agents

- `laravel-reverb` — WebSocket specialist

## Related Skills

- `laravel-testing` — testing broadcasting events
- `laravel-queue` — queued broadcasts
- `laravel-livewire` — Livewire + Echo listeners

## Additional references

- Install, config, env, broadcasting config, public/private/presence events, queued broadcasts, patterns, testing → [references/reverb-and-broadcasting.md](references/reverb-and-broadcasting.md)
- Channel types, authorization routes, presence membership → [references/channels.md](references/channels.md)
- Echo client, listening/whisper, Livewire + Blade integration, Supervisor, Nginx, reconnection, Redis scaling, pitfalls, best practices → [references/echo-client-and-scaling.md](references/echo-client-and-scaling.md)
