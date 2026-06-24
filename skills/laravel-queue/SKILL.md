---
name: laravel-queue
description: Laravel queues — jobs, batching, chains, events/listeners, notifications, retries, failure handling, and workers. Use when building async/background processing, dispatching jobs, sending queued notifications, or wiring up events and Horizon.
---

# Laravel Queue Skill

Implement asynchronous processing with Laravel queues.

## When to Use

- Background job processing
- Sending emails asynchronously
- Event-driven architecture
- Notification systems
- Long-running tasks

## Quick Start

```bash
/laravel-agent:job:make <JobName>
```

## Conventions Checklist

### Jobs
- [ ] Implement `ShouldQueue`; use `Dispatchable, InteractsWithQueue, Queueable, SerializesModels`
- [ ] Type models with `readonly` promoted constructor params (serialized by ID via `SerializesModels`)
- [ ] Set `$tries`, `$timeout`, and `$backoff` (array for exponential) explicitly
- [ ] Implement `failed(Throwable $e)` for logging + admin notification
- [ ] Apply `WithoutOverlapping` / `RateLimited` / `ThrottlesExceptions` via `middleware()`
- [ ] Use `ShouldBeUnique` + `uniqueId()` to prevent duplicate dispatches
- [ ] Store file paths, not payloads, for heavy data

### Dispatching
- [ ] Use `dispatch()->onQueue('...')` for priority lanes
- [ ] `Bus::chain([...])` for ordered steps; `Bus::batch([...])` for fan-out
- [ ] `dispatchIf` / `dispatchUnless` for conditional dispatch

### Events & Listeners
- [ ] Make listeners `ShouldQueue` for async side effects
- [ ] Register in `EventServiceProvider::$listen` or rely on auto-discovery
- [ ] `shouldQueue(Event)` for conditional queuing

### Notifications
- [ ] Implement `ShouldQueue`; route via `via()` returning channel array
- [ ] Add `routeNotificationFor<Channel>()` on the notifiable model
- [ ] Use `Notification::send($users, ...)` for fan-out

### Workers
- [ ] Run under Supervisor (`numprocs`, `autorestart`)
- [ ] Restart workers after deploy (`php artisan queue:restart`)
- [ ] Use Horizon for Redis queue monitoring + tags

## Common Pitfalls

1. **No `SerializesModels`** — serializes whole model; pass the model + trait instead
2. **Missing `failed()` handler** — silent failures; log + notify
3. **No timeout** — runaway jobs; set `$timeout` and `$failOnTimeout`
4. **Infinite retry loops** — set `$tries` and `$backoff`
5. **Heavy payloads** — pass file paths, not large blobs
6. **Stale workers after deploy** — `queue:restart`
7. **No Supervisor** — workers die and stay dead

## Related Commands

- `/laravel-agent:job:make` - Create queued jobs, events, listeners
- `/laravel-agent:notification:make` - Create notifications
- `/laravel-agent:horizon:setup` - Set up Laravel Horizon

## Related Skills

- `laravel-horizon` - Redis queue dashboard and monitoring
- `laravel-octane` - High-performance application servers
- `laravel-websocket` - Real-time broadcasting backends
- `laravel-testing` - Testing job dispatch and handling

## Additional references

- Jobs, dispatching, uniqueness, rate limiting, middleware, workers, supervisor → [references/jobs-and-dispatching.md](references/jobs-and-dispatching.md)
- Batches, chains, events/listeners, notifications, broadcasting, scheduling, Prompts, Horizon → [references/batches-chains-events.md](references/batches-chains-events.md)
- Testing, retries/backoff/timeouts, failure handling, pitfalls, best practices → [references/retries-and-failure.md](references/retries-and-failure.md)
