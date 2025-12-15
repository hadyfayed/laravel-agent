---
layout: home
title: Laravel Agent
description: AI-powered Laravel development assistant for Claude Code
---

# Laravel Agent

> AI-powered Laravel development assistant - architecture decisions, code generation, testing, deployment, and more.

A Claude Code plugin with **23 specialized agents**, **42 commands**, **12 auto-invoked skills**, and **7 quality hooks** covering the entire Laravel development lifecycle.

## Quick Start

```bash
# Add the marketplace
/plugin marketplace add hadyfayed/laravel-agent

# Install the plugin
/plugin install laravel-agent@hadyfayed-laravel-agent
```

That's it! All agents, commands, and skills are now available.

## Features

- **23 Specialized Agents** - Architecture, features, APIs, testing, security, deployment
- **42 Commands** - Direct access to all capabilities
- **12 Auto-Invoked Skills** - Claude automatically applies Laravel expertise
- **7 Quality Hooks** - Pre-commit checks, security scanning, auto-formatting
- **SOLID/DRY Enforcement** - Every generated code follows best practices
- **85+ Package Integrations** - Detects and adapts to installed packages

## Documentation

### Getting Started
- [Installation](getting-started/installation.md)
- [Quick Start Guide](getting-started/quickstart.md)
- [Configuration](getting-started/configuration.md)

### Commands
- [Command Reference](commands/index.md)
- [Build Commands](commands/build.md)
- [API Commands](commands/api.md)
- [Testing Commands](commands/testing.md)
- [DevOps Commands](commands/devops.md)

### Skills
- [Skills Overview](skills/index.md)
- [How Skills Work](skills/how-skills-work.md)
- [Available Skills](skills/available.md)

### Hooks
- [Hooks Overview](hooks/index.md)
- [Installation](hooks/installation.md)
- [Available Hooks](hooks/available.md)

### Guides
- [Building Features](guides/building-features.md)
- [Creating APIs](guides/creating-apis.md)
- [Testing Best Practices](guides/testing.md)
- [Security Auditing](guides/security.md)
- [Deployment](guides/deployment.md)

## Architecture

```
User Request
     │
     ▼
┌─────────────┐
│  Architect  │ ─── Analyzes request, decides implementation
└─────────────┘
     │
     ▼
┌─────────────────────────────────────────┐
│            Builder Selection            │
├─────────────┬─────────────┬─────────────┤
│   Feature   │   Module    │   Service   │
│   Builder   │   Builder   │   Builder   │
└─────────────┴─────────────┴─────────────┘
     │
     ▼
┌─────────────┐
│   Testing   │ ─── Generates Pest tests
└─────────────┘
     │
     ▼
┌─────────────┐
│   Review    │ ─── Code quality check
└─────────────┘
```

## Support

- [GitHub Issues](https://github.com/hadyfayed/laravel-agent/issues)
- [Contributing](https://github.com/hadyfayed/laravel-agent/blob/main/CONTRIBUTING.md)

## License

MIT License - see [LICENSE](https://github.com/hadyfayed/laravel-agent/blob/main/LICENSE)
