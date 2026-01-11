---
description: "Create a reusable domain module with contracts, services, DTOs, and tests"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /module:make - Create Domain Module

Generate a reusable domain module under `app/Modules/<Name>` (or `Modules/` if nwidart/laravel-modules is installed).

## Input
$ARGUMENTS = `<ModuleName> [specification] [--flags]`

Examples:
- `/module:make Pricing --with-dto`
- `/module:make Notification --with-events`
- `/module:make Payment --package`
- `/module:make Inventory --minimal`

## Flags
- `--package`: Scaffold as a distributable package in the `packages/` directory.
- `--with-dto`: Generate a Data Transfer Object.
- `--with-events`: Generate an `Events` directory and a sample event class.
- `--minimal`: Generate only the ServiceProvider and the core Service class.

## Process

1. **Check Environment**
   ```bash
   # Check if nwidart/laravel-modules is installed
   composer show nwidart/laravel-modules 2>/dev/null && echo "NWIDART=yes" || echo "NWIDART=no"
   ```

2. **Parse Arguments**
   - Extract `name` and `specification`.
   - Extract flags like `--package`, `--with-dto`, etc.

3. **Ask About Patterns (if not using flags)**
   If no flags are provided, you can still ask about patterns for guided creation.
   ```
   Which patterns should this module use?
   - Strategy: Multiple interchangeable algorithms
   - Repository: Data access abstraction
   ```

4. **Invoke Module Builder**

   Use Task tool with subagent_type `laravel-module-builder`:
   ```
   Build a reusable Module:

   Name: <name>
   Patterns: [selected patterns]
   Spec: <specification>
   UseNwidart: <yes|no based on check>
   Flags: [--package, --with-dto, --with-events, --minimal]
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
