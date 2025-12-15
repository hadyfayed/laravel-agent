# Laravel Agent Hooks

Pre-configured hooks for Laravel development with Claude Code.

## Available Hooks

### Pre-Commit Hook (UserPromptSubmit)

Runs before git commit to ensure code quality:

- **PHP CS Fixer / Laravel Pint** - Code style formatting
- **PHPStan** - Static analysis
- **Laravel IDE Helper** - Model annotations

### Post-Edit Hook (PostToolUse)

Runs after file edits to maintain code quality:

- Auto-format PHP files with Pint
- Update IDE helper when models change

## Installation

Add to your Claude Code settings (`.claude/settings.json` or project settings):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git commit",
        "command": "bash hooks/scripts/pre-commit.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "bash hooks/scripts/post-edit.sh \"$FILE_PATH\""
      }
    ]
  }
}
```

## Hook Scripts

### pre-commit.sh

Checks staged PHP files for:
- Syntax errors
- Code style violations (auto-fixes with Pint)
- PHPStan errors

### post-edit.sh

After editing a PHP file:
- Formats with Laravel Pint
- Updates IDE helper if model was changed

## Requirements

- Laravel Pint (`composer require laravel/pint --dev`)
- PHPStan (`composer require phpstan/phpstan --dev`)
- IDE Helper (`composer require barryvdh/laravel-ide-helper --dev`) - optional

## Configuration

The scripts auto-detect available tools and skip if not installed.
