---
description: "Setup Laravel Reverb WebSocket server"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /reverb:setup - WebSocket Server Setup

Configure Laravel Reverb for real-time features.

## Input
$ARGUMENTS = `[options]`

Options:
- `/reverb:setup` - Full setup with Echo
- `/reverb:setup minimal` - Server only, no frontend
- `/reverb:setup scaled` - With Redis scaling

## Process

1. **Install Packages**
   ```bash
   composer require laravel/reverb
   php artisan reverb:install
   npm install --save-dev laravel-echo pusher-js
   ```

2. **Configure Environment**
   - Set BROADCAST_CONNECTION=reverb
   - Generate REVERB_APP_ID, REVERB_APP_KEY, REVERB_APP_SECRET
   - Configure VITE_REVERB_* variables

3. **Setup Echo**
   - Create resources/js/echo.js
   - Import in app.js

4. **Create Example Channel**
   - Add to routes/channels.php
   - Create sample broadcast event

5. **Report Results**
   ```markdown
   ## Reverb Configured

   ### Server
   Start with: `php artisan reverb:start`

   ### Environment
   - REVERB_APP_ID: xxx
   - REVERB_APP_KEY: xxx
   - WebSocket URL: ws://localhost:8080

   ### Client
   Echo configured in resources/js/echo.js

   ### Test
   ```bash
   php artisan reverb:start &
   php artisan tinker
   >>> broadcast(new App\Events\TestEvent('Hello!'))
   ```
   ```
