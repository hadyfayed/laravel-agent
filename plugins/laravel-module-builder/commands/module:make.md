---
description: "Create a reusable domain module with contracts, services, DTOs, and tests"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /module:make - Create Domain Module

Generate a reusable domain module under `app/Modules/<Name>` (or `Modules/` if nwidart/laravel-modules is installed).

## Input
$ARGUMENTS = `<ModuleName> [specification]`

Examples:
- `/module:make Pricing` - Basic pricing module
- `/module:make Notification with email, SMS, and push channels`
- `/module:make Payment with Stripe and PayPal strategies`
- `/module:make Inventory with stock tracking and alerts`

## Process

1. **Check Environment**
   ```bash
   # Check if nwidart/laravel-modules is installed
   composer show nwidart/laravel-modules 2>/dev/null && echo "NWIDART=yes" || echo "NWIDART=no"
   ```

2. **Parse Arguments**
   - `name`: Module name (PascalCase)
   - `spec`: Additional specification

3. **Ask About Patterns**
   ```
   Which patterns should this module use?
   - Strategy: Multiple interchangeable algorithms (e.g., payment gateways)
   - Repository: Data access abstraction
   - DTO: Type-safe data transfer objects
   - None: Simple service class
   ```

4. **Invoke Module Builder**

   Use Task tool with subagent_type `laravel-module-builder`:
   ```
   Build a reusable Module:

   Name: <name>
   Patterns: [selected patterns]
   Spec: <specification>
   UseNwidart: <yes|no based on check>
   ```

5. **Report Results**
   ```markdown
   ## Module Created: <Name>

   ### Location
   app/Modules/<Name>/ (or Modules/<Name>/ for nwidart)

   ### Public API
   ```php
   interface <Name>ServiceInterface
   {
       public function method(): Result;
   }
   ```

   ### Usage
   ```php
   $service = app(<Name>ServiceInterface::class);
   $result = $service->method();
   ```

   ### Registration
   Add to config/app.php providers:
   App\Modules\<Name>\<Name>ServiceProvider::class
   ```

## Examples

| Command | Patterns | Result |
|---------|----------|--------|
| `/module:make Pricing` | DTO | Pricing calculation module |
| `/module:make Payment with Stripe` | Strategy | Payment with gateway strategies |
| `/module:make Inventory` | Repository | Stock management module |
| `/module:make Notification` | Strategy | Multi-channel notifications |
