---
description: "Create a broadcast event with channel configuration"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /broadcast:make - Create Broadcast Event

Generate a broadcast event with channel authorization.

## Input
$ARGUMENTS = `<EventName> [channel-type] [channel-name]`

Examples:
- `/broadcast:make OrderUpdated` - Public channel
- `/broadcast:make MessageSent private user.{id}` - Private channel
- `/broadcast:make UserJoined presence chat.{roomId}` - Presence channel

## Process

1. **Parse Arguments**
   - Event name
   - Channel type: public, private, presence
   - Channel name pattern

2. **Invoke Reverb Agent**
   ```
   Create broadcast event:

   Action: event
   Name: <EventName>
   Type: <public|private|presence>
   Channel: <channel pattern>
   ```

3. **Files Created**
   - app/Events/<EventName>.php
   - Channel authorization in routes/channels.php (if private/presence)

4. **Report Results**
   ```markdown
   ## Broadcast Event Created: <EventName>

   ### Event
   app/Events/<EventName>.php

   ### Channel
   Type: <type>
   Name: <channel>

   ### Usage
   ```php
   // Dispatch event
   broadcast(new <EventName>($data));

   // Exclude sender
   broadcast(new <EventName>($data))->toOthers();
   ```

   ### Client
   ```javascript
   Echo.<channel-method>('<channel>')
       .listen('.<event-name>', (e) => {
           console.log(e);
       });
   ```
   ```
