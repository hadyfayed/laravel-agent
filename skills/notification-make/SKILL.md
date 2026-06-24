---
name: notification-make
description: Generate a Laravel notification with multi-channel support (mail, database, broadcast, SMS, Telegram, Discord, Slack, WebPush, FCM) and queueing; when adding notifications.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(composer require) Bash(composer show) Read Write Edit
argument-hint: "<NotificationName> [--channels=<list>] [--setup=<channel>]"
---

## Task

Create a multi-channel Laravel notification with queueing and optional channel setup.

## Input

- **NotificationName:** Class name (e.g., `OrderShipped`, `WelcomeUser`, `AlertAdmin`)
- **channels:** Comma-separated list (e.g., `mail,telegram,discord`) — defaults to `mail`
- **setup:** Configure a single channel only (no notification class)

## Modes

### Mode 1: Create Notification

1. **Install required packages** for non-built-in channels:
   ```bash
   # For channels like telegram, discord, twilio, fcm, webpush, etc.
   composer show laravel-notification-channels/<channel> 2>/dev/null || \
   composer require laravel-notification-channels/<channel>
   ```

2. **Generate notification class** in `app/Notifications/<NotificationName>.php`:
   - Implement `via()` method with selected channels
   - Add channel-specific methods: `toMail()`, `toDatabase()`, `toTelegram()`, `toDiscord()`, `toSlack()`, etc.
   - Configure queueing: use `ShouldQueue` trait and `$connection`/`$queue` properties
   - Add routing methods to User model if needed: `routeNotificationFor<Channel>()`

3. **Add environment variables** to `.env.example`:
   - TELEGRAM_BOT_TOKEN, DISCORD_WEBHOOK_URL, TWILIO_SID, TWILIO_TOKEN, FCM_SERVER_KEY, etc.

### Mode 2: Setup Channel Only

1. **Install package**:
   ```bash
   composer require laravel-notification-channels/<channel>
   ```

2. **Add environment variables** to `.env.example`

3. **Add routing method** to User model if channel requires user identifier:
   ```php
   public function routeNotificationFor<Channel>(): ?string
   {
       return $this-><channel>_id;
   }
   ```

4. **Create migration** (optional, if user field needed):
   ```php
   Schema::table('users', function (Blueprint $table) {
       $table->string('<channel>_id')->nullable();
   });
   ```

## Supported Built-in Channels

- **mail** — Email (Laravel Mail)
- **database** — Database (requires notification table)
- **broadcast** — WebSocket (Laravel Broadcasting)
- **slack** — Slack webhooks

## Supported Third-Party Channels

See `${CLAUDE_SKILL_DIR}/references/channel-packages.md` for 50+ available channels including Telegram, Discord, Twilio, Firebase Cloud Messaging, WebPush, OneSignal, ApplePush, Microsoft Teams, Google Chat, Vonage, MessageBird, Plivo, and more.

## Output

### For Create Mode
```markdown
## Notification: <NotificationName>

### Files Created
- app/Notifications/<NotificationName>.php

### Channels
| Channel | Method | Queued |
|---------|--------|--------|
| mail | toMail() | Yes |
| telegram | toTelegram() | Yes |

### Packages Installed
- laravel-notification-channels/telegram
- laravel-notification-channels/discord

### Environment Variables
Add to .env:
- TELEGRAM_BOT_TOKEN=
- DISCORD_WEBHOOK_URL=

### Usage
```php
$user->notify(new <NotificationName>($data));
```
```

### For Setup Mode
```markdown
## Channel Setup: <Channel>

### Package Installed
- laravel-notification-channels/<channel>

### Environment Variables
Add to .env:
- VARIABLE=

### User Model Routing
Add to User model:
```php
public function routeNotificationFor<Channel>(): ?string
{
    return $this-><channel>_id;
}
```
```
