# Installation

## Requirements

- **Claude Code** with Plugin support
- **Laravel 10+** project
- PHP 8.1 or higher

## Quick Install

```bash
# Add the marketplace
/plugin marketplace add hadyfayed/laravel-agent

# Install the plugin
/plugin install laravel-agent@hadyfayed-laravel-agent
```

## Verify Installation

After installation, verify by running:

```bash
/laravel-agent:patterns
```

You should see the current pattern usage for your project.

## Optional Dependencies

For the best experience, install these packages in your Laravel project:

### Code Quality
```bash
# Code formatting
composer require laravel/pint --dev

# Static analysis
composer require phpstan/phpstan --dev
composer require larastan/larastan --dev

# IDE support
composer require barryvdh/laravel-ide-helper --dev
```

### Testing
```bash
# Pest testing framework
composer require pestphp/pest --dev
composer require pestphp/pest-plugin-laravel --dev
```

### Development Tools
```bash
# Debug bar
composer require barryvdh/laravel-debugbar --dev

# Query detector (N+1)
composer require beyondcode/laravel-query-detector --dev
```

## Configuration

### Hooks Setup

To enable pre-commit hooks and auto-formatting, add to `.claude/settings.json`:

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

See [Hooks Documentation](../hooks/index.md) for full configuration.

## Updating

To update to the latest version:

```bash
/plugin update laravel-agent@hadyfayed-laravel-agent
```

## Uninstalling

To remove the plugin:

```bash
/plugin uninstall laravel-agent@hadyfayed-laravel-agent
```

## Troubleshooting

### Plugin not found

Make sure you've added the marketplace first:

```bash
/plugin marketplace add hadyfayed/laravel-agent
```

### Commands not working

1. Check that you're in a Laravel project directory
2. Verify plugin is installed: `/plugin list`
3. Try reinstalling the plugin

### Hooks not running

1. Check `.claude/settings.json` exists
2. Verify hook paths are correct
3. Make sure scripts are executable: `chmod +x hooks/scripts/*.sh`
