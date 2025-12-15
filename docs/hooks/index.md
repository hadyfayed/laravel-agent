# Hooks Overview

Laravel Agent provides 7 pre-configured hooks for automated code quality checks.

## What Are Hooks?

Hooks are scripts that run automatically in response to Claude Code events:

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   User Action    │ ──▶ │   Hook Trigger   │ ──▶ │   Script Runs    │
│  (edit, commit)  │     │  (PostToolUse)   │     │  (lint, format)  │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

## Available Hooks

### Core Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `pre-commit.sh` | UserPromptSubmit | Comprehensive pre-commit checks |
| `post-edit.sh` | PostToolUse | Auto-format PHP, update IDE helper |

### Security Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `security-scan.sh` | PostToolUse | Detect secrets and API keys |
| `env-check.sh` | PostToolUse | Validate .env files |

### Quality Hooks

| Hook | Event | Description |
|------|-------|-------------|
| `blade-lint.sh` | PostToolUse | Check Blade templates |
| `migration-safety.sh` | PostToolUse | Warn about dangerous migrations |
| `test-runner.sh` | PostToolUse | Run related tests |

## Pre-Commit Checks

The `pre-commit.sh` hook runs comprehensive checks:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Laravel Agent: Pre-Commit Checks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Staged files:
  PHP: 5 files
  Blade: 2 files

PHP Checks
────────────────────────────────────────
[✓] Syntax check passed
[✓] Pint formatting applied
[✓] PHPStan passed
[✓] Security scan passed

Blade Checks
────────────────────────────────────────
[✓] Blade checks passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All pre-commit checks PASSED!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Security Scanning

The `security-scan.sh` hook detects:

- AWS credentials (AKIA...)
- Stripe keys (sk_live_, pk_live_)
- GitHub tokens (ghp_, gho_)
- Private keys (-----BEGIN PRIVATE KEY-----)
- Database URLs with passwords
- Hardcoded passwords
- Debug functions (dd, dump, var_dump)
- eval() calls

## Quick Setup

Add to `.claude/settings.json`:

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
      }
    ]
  }
}
```

## Exit Codes

| Code | Meaning | Effect |
|------|---------|--------|
| 0 | Success | Continue |
| 1 | Warning | Continue with message |
| 2 | Error | Block operation |

## See Also

- [Installation Guide](installation.md)
- [Available Hooks](available.md)
- [Configuration](../getting-started/configuration.md)
