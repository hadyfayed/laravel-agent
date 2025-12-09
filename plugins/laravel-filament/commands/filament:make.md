---
description: "Create Filament resource, page, or widget"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /filament:make - Create Filament Component

Generate Filament admin panel components.

## Input
$ARGUMENTS = `<Name> [type]`

Examples:
- `/filament:make Products` - Full resource with CRUD
- `/filament:make Settings page` - Custom page
- `/filament:make Revenue widget` - Stats/chart widget
- `/filament:make Orders relation` - Relation manager

## Types
- `resource` - Full CRUD resource (default)
- `page` - Custom page
- `widget` - Stats or chart widget
- `relation` - Relation manager

## Process

Use Task tool with subagent_type `laravel-filament`:
```
Create Filament component:

Name: <name>
Type: <type>
Features: [filters, bulk-actions, relations, charts]
```
