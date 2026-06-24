---
name: bug-fix
description: Systematically diagnose and fix a bug — reproduce, root-cause, fix, regression test; when fixing a reported bug.
disable-model-invocation: true
allowed-tools: Bash(php artisan *) Read Grep Glob Edit Write
argument-hint: "[error-source]"
---

## Task

Diagnose and fix a bug in your Laravel application.

1. **Gather error context**

   From argument (error message, log file, or exception type):
   - If empty, check `storage/logs/laravel.log` for recent exceptions
   - If passed, search for matching errors across logs

   ```bash
   tail -200 storage/logs/laravel.log | grep -A 30 "Exception\|Error"
   ```

2. **Analyze the error**
   - Read stack trace line-by-line (file, line number, method)
   - Identify the triggering event (HTTP request, job, command, event)
   - Check related code: model scopes, migrations, validation rules, config
   - Look for recent changes that might have introduced the bug

3. **Identify root cause**

   Common patterns:
   - **QueryException** → missing column, foreign key constraint, syntax error
   - **Class/Method not found** → missing import, namespace mismatch, typo
   - **Validation error** → missing/wrong rule, custom rule logic, request class
   - **Authentication/Authorization** → guard config, middleware order, policy logic
   - **Relationship issue** → wrong relationship type, missing join, circular dependency

4. **Fix the bug**
   - Edit or create files as needed (migrations, model methods, validation rules)
   - Keep changes minimal and focused
   - Update related code if side effects exist

5. **Test the fix**
   - Reproduce the original error to confirm it's fixed
   - Write a regression test (unit or feature test)
   - Check for related edge cases

6. **Report**

   ```markdown
   ## Bug Fix: <Error Type>

   ### Error
   <Full error message>

   ### Root Cause
   <Why this error occurred>

   ### Solution
   <Changes made with explanations>

   ### Files Modified
   - app/Models/X.php (line Y)
   - database/migrations/...

   ### Regression Test
   <Test added to prevent reoccurrence>
   ```

## See also

- `${CLAUDE_SKILL_DIR}/references/error-patterns.md` — detailed diagnosis guides per error type
- `laravel-testing` reference skill for test patterns
- Laravel documentation for Eloquent, validation, authentication
