# Laravel Agent Hooks

Pre-configured hooks for Laravel development with Claude Code.

## Available Hooks

### Core Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `pre-commit.sh` | UserPromptSubmit | Comprehensive pre-commit checks |
| `post-edit.sh` | PostToolUse (Edit/Write) | Auto-format PHP, update IDE helper |

### Security Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `security-scan.sh` | PostToolUse | Scans for secrets, API keys, passwords |
| `env-check.sh` | PostToolUse | Validates .env files, prevents commits |

### Quality Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `blade-lint.sh` | PostToolUse | Checks Blade templates for issues |
| `migration-safety.sh` | PostToolUse | Warns about dangerous migrations |
| `test-runner.sh` | PostToolUse | Runs related tests on file changes |
| `scout-indexing.sh` | PostToolUse | Validates Scout searchable models |
| `cashier-webhook.sh` | PostToolUse | Validates Cashier/Stripe webhooks |

## Pre-Commit Checks

The comprehensive pre-commit hook runs:

### PHP Checks
1. **Syntax Check** - Validates PHP syntax
2. **Laravel Pint** - Code style formatting
3. **PHPStan** - Static analysis
4. **Security Scan** - Detects secrets and debug functions

### Blade Checks
1. **CSRF Tokens** - Ensures forms have @csrf
2. **XSS Prevention** - Warns about unescaped output

### Migration Checks
1. **Destructive Operations** - Warns about drops/truncates
2. **Rollback Support** - Checks for down() method

### Environment Checks
1. **Block .env** - Prevents committing secrets

## Installation

### Option 1: Claude Code Settings

Add to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git commit",
        "command": "bash .claude-plugins/laravel-agent/hooks/scripts/pre-commit.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "bash .claude-plugins/laravel-agent/hooks/scripts/post-edit.sh \"$TOOL_INPUT_FILE_PATH\""
      },
      {
        "matcher": "Write",
        "command": "bash .claude-plugins/laravel-agent/hooks/scripts/post-edit.sh \"$TOOL_INPUT_FILE_PATH\""
      }
    ]
  }
}
```

### Option 2: Full Configuration

For all hooks, use the provided `hooks.example.json`.

## Hook Scripts

### pre-commit.sh

Comprehensive pre-commit validation:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Laravel Agent: Pre-Commit Checks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Staged files:
  PHP: 5 files
  Blade: 2 files

PHP Checks
────────────────────────────────────────
[1/4] PHP Syntax Check...
[✓] Syntax check passed
[2/4] Laravel Pint...
[✓] Pint formatting applied
[3/4] PHPStan...
[✓] PHPStan passed
[4/4] Security Scan...
[✓] Security scan passed

Blade Checks
────────────────────────────────────────
[✓] Blade checks passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All pre-commit checks PASSED!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### security-scan.sh

Detects potential secrets:

- API keys (AWS, Stripe, GitHub, GitLab, Slack)
- Private keys (RSA, DSA, EC, OPENSSH)
- Database credentials
- JWT tokens
- Hardcoded passwords
- Debug functions (dd, dump, var_dump)
- eval() calls

### migration-safety.sh

Checks for dangerous operations:

- `dropColumn`, `dropTable`, `drop`
- `truncate`
- `renameColumn`, `rename`
- Missing `down()` method
- Non-nullable columns without defaults

### blade-lint.sh

Validates Blade templates:

- Missing @csrf in forms
- Unescaped output ({!! !!})
- Inline PHP (<?php)
- Unclosed directives
- Missing @method for PUT/PATCH/DELETE

### test-runner.sh

Automatically runs related tests:

- Detects test files for modified classes
- Supports Pest and PHPUnit
- Searches by class name patterns
- Blocks commit on test failures

### env-check.sh

Validates environment files:

- Blocks .env file commits
- Checks .env.example for real secrets
- Validates required variables
- Checks for duplicate keys
- Warns about insecure defaults

## Requirements

Optional but recommended:

```bash
# Code style
composer require laravel/pint --dev

# Static analysis
composer require phpstan/phpstan --dev

# IDE helper
composer require barryvdh/laravel-ide-helper --dev

# Testing
composer require pestphp/pest --dev
```

## Configuration

### Environment Variables

```bash
# Number of parallel jobs for pre-commit
export PARALLEL_JOBS=4

# Skip specific checks
export SKIP_PHPSTAN=1
export SKIP_PINT=1
```

### Customization

Copy and modify hooks for your project:

```bash
cp .claude-plugins/laravel-agent/hooks/scripts/pre-commit.sh ./hooks/
# Edit to your needs
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Non-blocking warning |
| 2 | Blocking error (fails commit) |

Claude Code hooks use exit code 2 to block operations.
