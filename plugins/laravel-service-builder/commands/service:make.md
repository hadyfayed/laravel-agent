---
description: "Create a service class or action with proper patterns"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /service:make - Create Service or Action

Generate a service class or single-purpose action.

## Input
$ARGUMENTS = `<Name> [type] [specification]`

Examples:
- `/service:make OrderProcessor` - Service class
- `/service:make SendWelcomeEmail action` - Native action
- `/service:make CreateOrder action:controller,job` - Laravel Actions with traits
- `/service:make ProcessPayment with Stripe integration`

## Types
- `service` - Service class with multiple methods (default)
- `action` - Native action with single `execute()` method
- `action:controller` - Laravel Actions running as controller
- `action:job` - Laravel Actions running as queued job
- `action:listener` - Laravel Actions running as event listener
- `action:command` - Laravel Actions running as artisan command
- `action:all` - Laravel Actions with all contexts

## Process

1. **Check Environment**
   ```bash
   composer show lorisleiva/laravel-actions 2>/dev/null && echo "LARAVEL_ACTIONS=yes" || echo "LARAVEL_ACTIONS=no"
   ```

2. **Parse Arguments**
   - `name`: Service/Action name
   - `type`: service, action, or action with contexts
   - `spec`: Additional specification

3. **Determine Domain**
   ```
   What domain does this belong to?
   - Orders
   - Users
   - Products
   - Payments
   - [Other]
   ```

4. **Invoke Service Builder**

   Use Task tool with subagent_type `laravel-service-builder`:
   ```
   Create:

   Type: <Service|Action>
   Domain: <domain>
   Name: <name>
   Spec: <specification>
   RunAs: [controller, job, listener, command] (if laravel-actions)
   ```

5. **Report Results**
   ```markdown
   ## Service/Action Created: <Name>

   ### Type
   [Service | Action (Native) | Action (Laravel Actions)]

   ### Location
   - Service: app/Services/<Name>Service.php
   - Action: app/Actions/<Domain>/<Name>.php

   ### Usage
   ```php
   // Service
   $result = app(<Name>Service::class)->method($input);

   // Action (Native)
   $result = app(<Name>Action::class)->execute($input);

   // Action (Laravel Actions)
   $result = <Name>::run($input);
   <Name>::dispatch($input); // As job
   ```

   ### Test
   vendor/bin/pest --filter=<Name>
   ```

## Examples

| Command | Type | Location |
|---------|------|----------|
| `/service:make OrderProcessor` | Service | app/Services/OrderProcessorService.php |
| `/service:make SendEmail action` | Native Action | app/Actions/Notifications/SendEmailAction.php |
| `/service:make CreateOrder action:controller,job` | Laravel Actions | app/Actions/Orders/CreateOrder.php |
