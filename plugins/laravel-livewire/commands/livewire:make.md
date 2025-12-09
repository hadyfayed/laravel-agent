---
description: "Create Livewire component with form, table, or modal"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /livewire:make - Create Livewire Component

Generate reactive Livewire components for TALL stack.

## Input
$ARGUMENTS = `<Name> [type]`

Examples:
- `/livewire:make Orders` - Full CRUD (index, create, edit)
- `/livewire:make Products table` - Table with search/sort/pagination
- `/livewire:make Contact form` - Form component
- `/livewire:make DeleteConfirm modal` - Modal component

## Types
- `crud` - Full CRUD interface (default)
- `table` - Data table with filters
- `form` - Form with validation
- `modal` - Modal dialog
- `search` - Real-time search

## Process

Use Task tool with subagent_type `laravel-livewire`:
```
Create Livewire component:

Name: <name>
Type: <type>
Features: [search, sort, pagination, validation, file-upload]
```
