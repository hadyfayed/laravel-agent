---
description: "Create a service class or action with proper patterns"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /service:make - Create Service or Action

Generate a service class or single-purpose action.

## Input
$ARGUMENTS = `<Name> [specification] [--flags]`

Examples:
- `/service:make OrderProcessor` - Service class
- `/service:make SendWelcomeEmail --action`
- `/service:make CreateOrder --action --controller --job`
- `/service:make ProcessPayment --action --all`

## Flags
- `--action`: Generate a single-purpose Action. If `lorisleiva/laravel-actions` is installed, it will be a rich "Laravel Action."
- `--controller`: (Requires `--action`) Adds the `AsController` trait.
- `--job`: (Requires `--action`) Adds the `AsJob` trait.
- `--listener`: (Requires `--action`) Adds the `AsListener` trait.
- `--command`: (Requires `--action`) Adds the `AsCommand` trait.
- `--all`: (Requires `--action`) A shorthand for `--controller --job --listener --command`.

## Process

1. **Check Environment**
   ```bash
   composer show lorisleiva/laravel-actions 2>/dev/null && echo "LARAVEL_ACTIONS=yes" || echo "LARAVEL_ACTIONS=no"
   ```

2. **Parse Arguments**
   - Extract `name` and `specification`.
   - Extract flags like `--action`, `--controller`, etc.

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

   Name: <name>
   Spec: <specification>
   Domain: <domain>
   Flags: [--action, --controller, --job, --listener, --command, --all]
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
