---
description: "Create a complete Laravel feature directly (bypasses architect)"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /feature:make - Direct Feature Creation

Directly create a complete feature, bypassing the architect's decision process.

## Input
$ARGUMENTS = `<FeatureName> [specification] [--flags]`

Examples:
- `/feature:make Invoices`
- `/feature:make Products with categories and tags`
- `/feature:make Orders --no-views`
- `/feature:make Subscriptions --minimal`

## Flags
- `--no-views`: Skips creation of Blade views and web controller.
- `--no-api`: Skips API controller and resource generation.
- `--minimal`: Generates only Model, Migration, and ServiceProvider.

## Process

1. **Parse Arguments**
   - Extract `name` and `specification` from the beginning of the arguments.
   - Extract flags (`--no-views`, `--no-api`, `--minimal`) from the end.

2. **Ask About Tenancy**
   ```
   Does this feature need multi-tenant isolation?
   - Yes: Data belongs to specific tenants
   - No: Shared across all users
   ```

3. **Invoke Feature Builder**

   Use Task tool with subagent_type `laravel-feature-builder`:
   ```
   Build a complete Feature:

   Name: <name>
   Tenancy: <Yes|No>
   Patterns to use: [check .ai/patterns/registry.json]
   Spec: <specification>
   Flags: [--no-views, --no-api, --minimal]
   ```

4. **Report Results**
   ```markdown
   ## Feature Created: <Name>

   ### Location
   app/Features/<Name>/

   ### Routes
   - Web: /<slug>
   - API: /api/<slug>

   ### Permissions
   - read-<slug>
   - create-<slug>
   - update-<slug>
   - delete-<slug>
   ```
