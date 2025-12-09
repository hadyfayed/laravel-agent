---
description: "Create a complete Laravel feature directly (bypasses architect)"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /feature:make - Direct Feature Creation

Directly create a complete feature, bypassing the architect's decision process.

## Input
$ARGUMENTS = `<FeatureName> [specification]`

Examples:
- `/feature:make Invoices`
- `/feature:make Products with categories and tags`
- `/feature:make Orders with line items and status tracking`

## Process

1. **Parse Arguments**
   - `name`: First word
   - `spec`: Remaining text

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
