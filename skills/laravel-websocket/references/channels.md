# Laravel WebSocket Channels Reference

## Channel Types

- **Public** — anyone may listen (`Channel`). For broadcast announcements.
- **Private** — authenticated, authorized per user (`PrivateChannel`). For user-specific data.
- **Presence** — authenticated members expose presence info (`PresenceChannel`). For chat/who's-online.

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

## Channel Routes (from agent)

```php
// routes/channels.php

use App\Models\ChatRoom;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

// Private channel - user's own notifications
Broadcast::channel('user.{id}', function (User $user, int $id) {
    return $user->id === $id;
});

// Private channel - order belongs to user
Broadcast::channel('orders.{orderId}', function (User $user, int $orderId) {
    return $user->orders()->where('id', $orderId)->exists();
});

// Presence channel - chat room membership
Broadcast::channel('chat.{roomId}', function (User $user, int $roomId) {
    $room = ChatRoom::find($roomId);

    if ($room && $room->members()->where('user_id', $user->id)->exists()) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'avatar' => $user->avatar_url,
        ];
    }

    return false;
});

// Team presence channel
Broadcast::channel('team.{teamId}', function (User $user, int $teamId) {
    if ($user->belongsToTeam($teamId)) {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'role' => $user->teamRole($teamId),
        ];
    }

    return false;
});
```

## Authorization Rules

- Return `true`/`false` for private channels (membership only).
- Return an array (user data) for presence channels — the array is shared with other members.
- Authorize against relationships (`$user->orders()->where(...)`) — never trust client-supplied IDs alone.
- Register every channel in `routes/channels.php`; private/presence channels are rejected without a matching route.
