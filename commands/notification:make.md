---
description: "Create multi-channel notification with 55+ Laravel Notification Channels"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /notification:make - Multi-Channel Notifications

Create Laravel notifications with 55+ notification channels, or setup individual channels.

## Input
$ARGUMENTS = `<NotificationName> [--channels=<list>] [--setup=<channel>]`

Examples:
- `/notification:make OrderShipped --channels=mail,telegram` - Create notification
- `/notification:make --setup=telegram` - Setup channel only
- `/notification:make WelcomeUser --channels=mail,discord,twilio`
- `/notification:make AlertAdmin --channels=slack,teams`

## Supported Channels

### Built-in (No Package Required)
| Channel | Description | Env Variables |
|---------|-------------|---------------|
| mail | Email | MAIL_* |
| database | Store in DB | (migration required) |
| broadcast | WebSocket | BROADCAST_DRIVER |
| slack | Slack webhooks | SLACK_WEBHOOK_URL |

### Push Notifications
| Channel | Package | Env Variables |
|---------|---------|---------------|
| telegram | laravel-notification-channels/telegram | TELEGRAM_BOT_TOKEN |
| discord | laravel-notification-channels/discord | DISCORD_WEBHOOK_URL |
| fcm | laravel-notification-channels/fcm | FCM_SERVER_KEY |
| onesignal | laravel-notification-channels/onesignal | ONESIGNAL_APP_ID, ONESIGNAL_REST_API_KEY |
| webpush | laravel-notification-channels/webpush | VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY |
| apn | laravel-notification-channels/apn | APN_KEY_ID, APN_TEAM_ID |

### SMS/Voice
| Channel | Package | Env Variables |
|---------|---------|---------------|
| twilio | laravel-notification-channels/twilio | TWILIO_SID, TWILIO_TOKEN, TWILIO_FROM |
| vonage | laravel/vonage-notification-channel | VONAGE_KEY, VONAGE_SECRET |
| messagebird | laravel-notification-channels/messagebird | MESSAGEBIRD_ACCESS_KEY |
| plivo | laravel-notification-channels/plivo | PLIVO_AUTH_ID, PLIVO_AUTH_TOKEN |

### Messenger/Chat
| Channel | Package | Env Variables |
|---------|---------|---------------|
| teams | laravel-notification-channels/microsoft-teams | (webhook per notification) |
| googlechat | laravel-notification-channels/google-chat | (webhook per notification) |
| rocketchat | laravel-notification-channels/rocket-chat | ROCKETCHAT_URL |

## Process

### Mode 1: Setup Channel Only (`--setup=<channel>`)

1. **Install Package**
   ```bash
   composer require laravel-notification-channels/<channel>
   ```

2. **Publish Config**
   ```bash
   php artisan vendor:publish --tag=<channel>-config
   ```

3. **Add Environment Variables**
   Update `.env.example` with required variables

4. **Add User Model Routing**
   ```php
   public function routeNotificationFor<Channel>(): ?string
   {
       return $this-><channel>_id;
   }
   ```

5. **Create Migration** (if user identifier needed)
   ```php
   Schema::table('users', function (Blueprint $table) {
       $table->string('<channel>_id')->nullable();
   });
   ```

### Mode 2: Create Notification (`<NotificationName>`)

1. **Parse Channels**
   - From `--channels` flag or prompt interactively

2. **Install Required Packages**
   For each non-built-in channel:
   ```bash
   composer show laravel-notification-channels/<channel> 2>/dev/null || \
   composer require laravel-notification-channels/<channel>
   ```

3. **Invoke Queue Agent**
   Use Task tool with subagent_type `laravel-queue`:
   ```
   Create notification:
   Name: <NotificationName>
   Type: notification
   Channels: [<channel1>, <channel2>, ...]
   Features: [queued, per-channel-config, user-preferences]
   ```

4. **Generate Channel Methods**
   For each channel, add the via() and to<Channel>() methods

5. **Add Env Variables**
   Update `.env.example` with required credentials

## Channel Configuration Reference

### Telegram
```env
TELEGRAM_BOT_TOKEN=your-bot-token
```
```php
// User Model
public function routeNotificationForTelegram(): ?string
{
    return $this->telegram_chat_id;
}
```

### Discord
```env
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
```

### Twilio (SMS)
```env
TWILIO_SID=your-account-sid
TWILIO_TOKEN=your-auth-token
TWILIO_FROM=+1234567890
```
```php
// User Model
public function routeNotificationForTwilio(): ?string
{
    return $this->phone;
}
```

### FCM (Firebase)
```env
FCM_SERVER_KEY=your-server-key
FCM_SENDER_ID=your-sender-id
```
```php
// User Model
public function routeNotificationForFcm(): array
{
    return $this->fcm_tokens()->pluck('token')->toArray();
}
```

### WebPush
```env
VAPID_PUBLIC_KEY=your-public-key
VAPID_PRIVATE_KEY=your-private-key
VAPID_SUBJECT=mailto:admin@yoursite.com
```
Generate keys:
```bash
php artisan webpush:vapid
```

### OneSignal
```env
ONESIGNAL_APP_ID=your-app-id
ONESIGNAL_REST_API_KEY=your-rest-api-key
```

### Vonage (SMS)
```env
VONAGE_KEY=your-key
VONAGE_SECRET=your-secret
VONAGE_SMS_FROM=YourApp
```

## Interactive Prompts

When run without `--channels`, prompt:

1. **Notification name?**
   - (text input)

2. **Select channels:**
   - [x] Mail (default)
   - [ ] Database
   - [ ] Telegram
   - [ ] Discord
   - [ ] Twilio (SMS)
   - [ ] Slack
   - [ ] FCM (Firebase)
   - [ ] WebPush

3. **Queue notifications?**
   - Yes (recommended for external channels)
   - No (synchronous)

4. **Add user preferences?**
   - Yes (per-user channel preferences table)
   - No

## Output

### For Setup Mode
```markdown
## Channel Setup: <Channel>

### Package Installed
- laravel-notification-channels/<channel>

### Environment Variables
Add to .env:
- VARIABLE_1=
- VARIABLE_2=

### Files Created/Modified
- .env.example (updated)
- app/Models/User.php (routing method added)
- database/migrations/xxxx_add_<channel>_to_users.php

### Next Steps
1. Add credentials to .env
2. Run `php artisan migrate`
3. Test: `$user->notify(new TestNotification());`

### Documentation
https://laravel-notification-channels.com/<channel>
```

### For Notification Creation
```markdown
## Notification Created: <NotificationName>

### Packages Installed
- laravel-notification-channels/telegram
- laravel-notification-channels/discord

### Files Created
- app/Notifications/<NotificationName>.php

### Channels Configured
| Channel | Method | Queued |
|---------|--------|--------|
| mail | toMail() | Yes |
| telegram | toTelegram() | Yes |
| discord | toDiscord() | Yes |

### Environment Variables Required
- TELEGRAM_BOT_TOKEN=
- DISCORD_WEBHOOK_URL=

### Usage
```php
$user->notify(new <NotificationName>($data));

// Or with facade
Notification::send($users, new <NotificationName>($data));
```

### Documentation
- https://laravel-notification-channels.com
```
