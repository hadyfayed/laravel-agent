---
description: "Analyze and optimize database queries and schema"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /db:optimize - Database Optimization

Analyze queries, suggest indexes, and optimize database performance.

## Input
$ARGUMENTS = `[target]`

Examples:
- `/db:optimize` - Analyze entire application
- `/db:optimize OrderController` - Analyze specific controller
- `/db:optimize orders` - Analyze specific table

## Process

Use Task tool with subagent_type `laravel-database`:
```
Optimize database:

Target: <target or "all">

1. Scan for N+1 queries
2. Check missing indexes
3. Analyze slow queries
4. Suggest eager loading
5. Review schema efficiency
```
