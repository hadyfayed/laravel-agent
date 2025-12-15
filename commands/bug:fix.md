---
description: "AI-powered bug analysis and fix suggestions"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit
---

# /bug:fix - AI Bug Analysis & Fix

Analyze errors and suggest fixes for Laravel applications.

## Input
$ARGUMENTS = `[error-source]`

Examples:
- `/bug:fix` - Analyze latest error from logs
- `/bug:fix "Class not found"` - Analyze specific error
- `/bug:fix storage/logs/laravel.log` - Analyze from log file
- `/bug:fix --exception=QueryException` - Find specific exception type

## Process

1. **Gather Error Context**
   ```bash
   # Get recent errors
   tail -100 storage/logs/laravel.log | grep -A 20 "Exception"

   # Or from Telescope
   php artisan tinker --execute="Telescope::get('exceptions')"
   ```

2. **Analyze Error**
   - Parse stack trace
   - Identify root cause
   - Find related code
   - Check for common patterns

3. **Suggest Fix**
   ```markdown
   ## Bug Analysis

   ### Error
   ```
   Illuminate\Database\QueryException: SQLSTATE[42S22]: Column not found: 1054 Unknown column 'users.tenant_id' in 'where clause'
   ```

   ### Root Cause
   The `tenant_id` column is referenced in a query scope but doesn't exist in the users table.

   ### Stack Trace Analysis
   1. `App\Models\User::scopeForTenant()` at line 45
   2. `App\Services\UserService::getUsers()` at line 23
   3. `App\Http\Controllers\UserController::index()` at line 15

   ### Solution

   **Option 1: Add the missing column**
   ```bash
   php artisan make:migration add_tenant_id_to_users_table
   ```

   ```php
   Schema::table('users', function (Blueprint $table) {
       $table->foreignId('tenant_id')->nullable()->after('id');
   });
   ```

   **Option 2: Fix the scope (if column shouldn't exist)**
   ```php
   // Before
   public function scopeForTenant($query, $tenantId)
   {
       return $query->where('tenant_id', $tenantId);
   }

   // After (if using different column)
   public function scopeForTenant($query, $tenantId)
   {
       return $query->where('created_for_id', $tenantId);
   }
   ```

   ### Prevention
   - Add test for tenant scope
   - Run migrations before deploying
   ```

## Common Error Patterns

### QueryException
- Missing columns
- Foreign key constraints
- Duplicate entries
- Syntax errors

### Class Not Found
- Missing imports
- Autoload issues
- Namespace mismatches

### Method Not Found
- Typos in method names
- Missing traits
- Wrong model relationships

### Validation Errors
- Missing rules
- Custom rule issues
- Request class problems

### Authentication Issues
- Guard configuration
- Middleware order
- Session problems

## Interactive Prompts

When run without arguments, prompt:

1. **Error source?**
   - Latest from laravel.log
   - Paste error message
   - Specific exception type
   - Telescope exceptions

2. **Error type?**
   - Database/Query error
   - Class/Method not found
   - Validation error
   - Authentication error
   - Other

3. **Apply fix automatically?**
   - Yes (create migration/edit files)
   - No (show suggestions only)

## Output

```markdown
## Bug Analysis: <Error Type>

### Error
```
<Full error message>
```

### Root Cause
<Explanation of why this error occurred>

### Stack Trace
| # | File | Line | Method |
|---|------|------|--------|
| 1 | app/Models/User.php | 45 | scopeForTenant |
| 2 | app/Services/UserService.php | 23 | getUsers |

### Solution

**Recommended Fix:**
<Code changes with explanations>

**Alternative Approaches:**
1. <Alternative 1>
2. <Alternative 2>

### Prevention
- <How to prevent this in the future>
- <Related tests to add>

### Files Modified
- app/Models/User.php (line 45)
```
