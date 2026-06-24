# Supported Notification Channels

## Built-in (No Package Required)
- mail — Email (Laravel Mail)
- database — Database (requires notification table migration)
- broadcast — WebSocket (Laravel Broadcasting)
- slack — Slack webhooks

## Third-Party Channels

### Push Notifications
- telegram — Telegram Bot API (laravel-notification-channels/telegram)
- discord — Discord webhooks (laravel-notification-channels/discord)
- fcm — Firebase Cloud Messaging (laravel-notification-channels/fcm)
- onesignal — OneSignal push service (laravel-notification-channels/onesignal)
- webpush — Web Push Protocol (laravel-notification-channels/webpush)
- apn — Apple Push Notification (laravel-notification-channels/apn)

### SMS/Voice
- twilio — Twilio SMS/voice (laravel-notification-channels/twilio)
- vonage — Vonage SMS (laravel/vonage-notification-channel)
- messagebird — MessageBird SMS (laravel-notification-channels/messagebird)
- plivo — Plivo SMS (laravel-notification-channels/plivo)

### Messenger/Chat
- teams — Microsoft Teams (laravel-notification-channels/microsoft-teams)
- googlechat — Google Chat (laravel-notification-channels/google-chat)
- rocketchat — Rocket.Chat (laravel-notification-channels/rocket-chat)

## Environment Variables Reference

```env
# Telegram
TELEGRAM_BOT_TOKEN=your-bot-token

# Discord
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# Twilio
TWILIO_SID=your-account-sid
TWILIO_TOKEN=your-auth-token
TWILIO_FROM=+1234567890

# FCM
FCM_SERVER_KEY=your-server-key
FCM_SENDER_ID=your-sender-id

# WebPush
VAPID_PUBLIC_KEY=your-public-key
VAPID_PRIVATE_KEY=your-private-key
VAPID_SUBJECT=mailto:admin@yoursite.com

# OneSignal
ONESIGNAL_APP_ID=your-app-id
ONESIGNAL_REST_API_KEY=your-rest-api-key

# Vonage
VONAGE_KEY=your-key
VONAGE_SECRET=your-secret
VONAGE_SMS_FROM=YourApp
```
