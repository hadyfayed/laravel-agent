# Laravel Security Hooks

Security validation hooks that run automatically during code generation and tool use.

## Hook System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         HOOK LIFECYCLE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PreToolUse ────► Tool Execution ────► PostToolUse                  │
│      │                                       │                       │
│      ▼                                       ▼                       │
│  ┌─────────────┐                     ┌─────────────┐                │
│  │  VALIDATE   │                     │   VERIFY    │                │
│  │  - Patterns │                     │   - Output  │                │
│  │  - Secrets  │                     │   - Files   │                │
│  │  - Danger   │                     │   - Changes │                │
│  └─────────────┘                     └─────────────┘                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## PreToolUse Hooks

### 1. Code Generation Security Hook

**Triggers:** Write, Edit, MultiEdit tools with PHP files

**Validates:**

```yaml
# Dangerous patterns to block
dangerous_patterns:
  # SQL Injection vectors
  - pattern: 'DB::raw\(\s*\$'
    message: "Potential SQL injection - use parameterized queries"
    severity: critical

  - pattern: 'whereRaw\(\s*["\'].*\$'
    message: "Raw where clause with variable - use bindings"
    severity: critical

  - pattern: 'DB::select\(\s*["\'][^?]*\$'
    message: "Dynamic SQL without bindings"
    severity: critical

  # XSS vectors
  - pattern: '\{\!\!\s*\$request->'
    message: "Unescaped user input - XSS risk"
    severity: critical

  - pattern: 'echo\s+\$_(?:GET|POST|REQUEST)'
    message: "Direct output of superglobals - XSS risk"
    severity: critical

  # Command Injection
  - pattern: 'exec\(\s*\$|shell_exec\(\s*\$|system\(\s*\$'
    message: "Command execution with variable - injection risk"
    severity: critical

  - pattern: 'proc_open\(\s*\$|passthru\(\s*\$'
    message: "Process execution with variable - injection risk"
    severity: critical

  # File Inclusion
  - pattern: 'include\s*\(\s*\$|require\s*\(\s*\$'
    message: "Dynamic file inclusion - LFI risk"
    severity: critical

  - pattern: 'file_get_contents\(\s*\$request'
    message: "File access with user input - SSRF risk"
    severity: high

  # Deserialization
  - pattern: 'unserialize\(\s*\$'
    message: "Unsafe deserialization - use JSON instead"
    severity: critical

  # Mass Assignment
  - pattern: '->create\(\s*\$request->all\(\)'
    message: "Mass assignment vulnerability - use validated()"
    severity: high

  - pattern: '->fill\(\s*\$request->all\(\)'
    message: "Mass assignment via fill() - use only() or validated()"
    severity: high

  # Debug in production code
  - pattern: '\bdd\(|\bdump\(|\bvar_dump\('
    message: "Debug statement detected - remove before commit"
    severity: warning
    action: warn  # Don't block, just warn
```

### 2. Secret Detection Hook

**Triggers:** Write, Edit tools on any file

**Validates:**

```yaml
secrets_patterns:
  # API Keys
  - pattern: '(api[_-]?key|apikey)\s*[=:]\s*["\'][a-zA-Z0-9]{20,}'
    message: "Potential API key detected"
    severity: critical

  # AWS Credentials
  - pattern: 'AKIA[0-9A-Z]{16}'
    message: "AWS Access Key ID detected"
    severity: critical

  - pattern: '[a-zA-Z0-9/+]{40}'
    context: 'aws|secret|key'
    message: "Potential AWS Secret Key"
    severity: critical

  # Private Keys
  - pattern: '-----BEGIN\s+(RSA\s+)?PRIVATE KEY-----'
    message: "Private key detected - do not commit"
    severity: critical

  # Database URLs
  - pattern: 'mysql://[^:]+:[^@]+@'
    message: "Database credentials in URL"
    severity: critical

  # JWT Secrets
  - pattern: '(jwt[_-]?secret|JWT_SECRET)\s*[=:]\s*["\'][^"\']{10,}'
    message: "JWT secret in code"
    severity: critical

  # Generic passwords
  - pattern: '(password|passwd|pwd)\s*[=:]\s*["\'][^"\']{4,}'
    message: "Hardcoded password detected"
    severity: critical
    exclude_files: ['*.test.php', '*Test.php', 'database/factories/*']
```

### 3. Dangerous Operations Hook

**Triggers:** Bash tool

**Validates:**

```yaml
dangerous_commands:
  # Destructive Git
  - pattern: 'git\s+push\s+.*--force'
    message: "Force push detected - requires confirmation"
    severity: high
    action: confirm

  - pattern: 'git\s+reset\s+--hard'
    message: "Hard reset detected - requires confirmation"
    severity: high
    action: confirm

  # Database destruction
  - pattern: 'php\s+artisan\s+migrate:fresh'
    message: "migrate:fresh drops all tables - requires confirmation"
    severity: high
    action: confirm

  - pattern: 'php\s+artisan\s+db:wipe'
    message: "db:wipe destroys database - requires confirmation"
    severity: critical
    action: confirm

  # File destruction
  - pattern: 'rm\s+-rf\s+/'
    message: "Recursive delete from root - blocked"
    severity: critical
    action: block

  - pattern: 'rm\s+-rf\s+\*'
    message: "Recursive delete all - requires confirmation"
    severity: high
    action: confirm

  # Environment changes
  - pattern: 'cp\s+.*\.env|mv\s+.*\.env'
    message: "Environment file modification - requires confirmation"
    severity: high
    action: confirm
```

## PostToolUse Hooks

### 1. Output Verification Hook

**Triggers:** After Write, Edit on PHP files

**Validates:**

```yaml
post_write_checks:
  # Syntax validation
  - check: php_syntax
    command: 'php -l {file}'
    on_error: revert

  # Laravel-specific
  - check: class_exists
    pattern: 'class\s+(\w+)'
    validate: 'namespace matches directory structure'

  # Security post-check
  - check: no_debug_statements
    pattern: '\bdd\(|\bdump\('
    on_error: warn
```

### 2. Migration Safety Hook

**Triggers:** After creating migration files

**Validates:**

```yaml
migration_checks:
  # Destructive operations
  - check: no_drop_in_up
    pattern: 'dropColumn|dropTable|drop'
    message: "Destructive operation in up() - ensure down() reverses it"
    severity: warning

  # Index naming
  - check: explicit_index_names
    pattern: '->index\(\)|\->unique\(\)'
    message: "Consider using explicit index names for easier rollback"
    severity: suggestion
```

## Implementation

### Hook Configuration File

```json
// .claude/hooks.json
{
  "version": "1.0",
  "hooks": {
    "PreToolUse": [
      {
        "name": "security-patterns",
        "enabled": true,
        "tools": ["Write", "Edit", "MultiEdit"],
        "file_patterns": ["*.php", "*.blade.php"],
        "config": "./plugins/laravel-security/hooks/patterns.yaml"
      },
      {
        "name": "secret-detection",
        "enabled": true,
        "tools": ["Write", "Edit"],
        "file_patterns": ["*"],
        "exclude": ["*.test.php", "storage/*", "vendor/*"]
      },
      {
        "name": "dangerous-commands",
        "enabled": true,
        "tools": ["Bash"],
        "environments": ["production"]
      }
    ],
    "PostToolUse": [
      {
        "name": "php-syntax",
        "enabled": true,
        "tools": ["Write", "Edit"],
        "file_patterns": ["*.php"]
      },
      {
        "name": "migration-safety",
        "enabled": true,
        "tools": ["Write"],
        "file_patterns": ["database/migrations/*.php"]
      }
    ]
  }
}
```

### Hook Response Actions

| Action | Behavior |
|--------|----------|
| `block` | Prevent the operation entirely |
| `warn` | Show warning but allow operation |
| `confirm` | Require explicit user confirmation |
| `revert` | Undo the operation if post-check fails |
| `suggest` | Show suggestion for improvement |

### Example Hook Output

```
┌─────────────────────────────────────────────────────────────────────┐
│ ⚠️  SECURITY HOOK TRIGGERED                                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│ File: app/Http/Controllers/UserController.php                        │
│ Line: 45                                                            │
│                                                                      │
│ Issue: SQL injection vulnerability detected                          │
│                                                                      │
│ Code:                                                               │
│   DB::select("SELECT * FROM users WHERE id = $id");                 │
│                                                                      │
│ Fix:                                                                │
│   DB::select("SELECT * FROM users WHERE id = ?", [$id]);            │
│                                                                      │
│ Action: BLOCKED - Fix the issue and retry                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Integration with laravel-review

The hooks complement the review system:

1. **Hooks** - Real-time prevention during coding
2. **Review** - Comprehensive analysis after coding

```
┌───────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                             │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│  Layer 1: PreToolUse Hooks (Real-time)                        │
│           └─ Block dangerous patterns immediately              │
│                                                                │
│  Layer 2: PostToolUse Hooks (Verification)                    │
│           └─ Validate output meets standards                   │
│                                                                │
│  Layer 3: /review:staged (Pre-commit)                         │
│           └─ Comprehensive scan before commit                  │
│                                                                │
│  Layer 4: /review:pr (Pull Request)                           │
│           └─ Full review with parallel agents                  │
│                                                                │
│  Layer 5: /review:audit (Periodic)                            │
│           └─ Full codebase security audit                      │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```
