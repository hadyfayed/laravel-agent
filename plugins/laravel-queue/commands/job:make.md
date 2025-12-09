---
description: "Create queued job, event, listener, or notification"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /job:make - Create Queue Component

Generate queued jobs, events, listeners, and notifications.

## Input
$ARGUMENTS = `<Name> [type]`

Examples:
- `/job:make ProcessOrder` - Queued job
- `/job:make OrderCreated event` - Event with broadcasting
- `/job:make SendOrderEmail listener` - Event listener
- `/job:make OrderShipped notification` - Multi-channel notification

## Types
- `job` - Queued job (default)
- `event` - Event (with optional broadcasting)
- `listener` - Event listener
- `notification` - Multi-channel notification
- `all` - Event + Listener + Notification combo

## Process

Use Task tool with subagent_type `laravel-queue`:
```
Create queue component:

Name: <name>
Type: <type>
Features: [batches, chains, broadcasting, retries]
```
