---
description: "Analyze and refactor code for SOLID/DRY compliance"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /refactor - Code Quality Improvement

Invoke **laravel-refactor** agent to analyze and improve code quality.

## Input
$ARGUMENTS = `<target>` - File path, class name, or directory

Examples:
- `/refactor app/Http/Controllers/OrderController.php`
- `/refactor OrderService`
- `/refactor app/Services/`

## Process

1. **Invoke Refactor Agent**

   Use Task tool with subagent_type `laravel-refactor`:
   ```
   Analyze and refactor:

   Target: $ARGUMENTS
   Focus: general

   Detect code smells, propose fixes, implement incrementally, verify tests.
   ```

2. **Report Results**
   ```markdown
   ## Refactoring Complete: <Target>

   ### Issues Fixed
   | Issue | Fix Applied |
   |-------|-------------|
   | ... | ... |

   ### Improvements
   - Lines: X → Y
   - Methods: X → Y

   ### Tests: All passing
   ```
