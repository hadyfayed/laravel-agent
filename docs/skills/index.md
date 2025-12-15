# Skills Overview

Skills are auto-invoked capabilities that activate based on context. Unlike commands, you don't need to call them explicitly - Claude automatically applies them when relevant.

## How Skills Work

When you describe a task, Claude analyzes your request and activates relevant skills:

```
User: "I need to optimize my slow database queries"
                    │
                    ▼
         ┌─────────────────────┐
         │  Skill Detection    │
         │  ─────────────────  │
         │  Triggers found:    │
         │  • "optimize"       │
         │  • "slow"           │
         │  • "queries"        │
         └─────────────────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │  laravel-database   │
         │  laravel-performance│
         │  Skills Activated   │
         └─────────────────────┘
```

## Available Skills (12)

| Skill | Triggers | Purpose |
|-------|----------|---------|
| `laravel-feature` | "build feature", "create feature", "crud" | Complete feature development |
| `laravel-api` | "build api", "create endpoint", "rest" | REST API development |
| `laravel-database` | "migration", "query", "N+1", "index" | Database operations |
| `laravel-testing` | "test", "pest", "coverage", "tdd" | Writing tests |
| `laravel-auth` | "auth", "permission", "role", "login" | Authentication |
| `laravel-livewire` | "livewire", "reactive", "component" | Livewire components |
| `laravel-filament` | "filament", "admin panel", "dashboard" | Admin panels |
| `laravel-performance` | "slow", "optimize", "cache", "fast" | Performance |
| `laravel-security` | "security", "vulnerability", "XSS" | Security |
| `laravel-deploy` | "deploy", "production", "server" | Deployment |
| `laravel-queue` | "queue", "job", "notification" | Background jobs |
| `laravel-websocket` | "websocket", "real-time", "Reverb" | Real-time features |

## Skill vs Command

| Aspect | Skill | Command |
|--------|-------|---------|
| Invocation | Automatic | Explicit (`/command`) |
| Context | Natural language | Structured input |
| Use Case | Conversational | Direct action |
| Flexibility | High | Specific |

### When to Use Skills

Skills work best for:
- Exploratory conversations
- Complex requirements
- Learning and guidance
- Multi-step tasks

```
"Help me build a user dashboard with real-time notifications"
→ Activates: laravel-feature, laravel-websocket
```

### When to Use Commands

Commands work best for:
- Specific, known tasks
- Repetitive operations
- Scripted workflows
- Quick actions

```bash
/laravel-agent:feature:make Dashboard
```

## Skill Content

Each skill provides:

1. **Quick Reference** - Common patterns and code snippets
2. **Complete Examples** - Full working implementations
3. **Common Pitfalls** - Anti-patterns to avoid
4. **Package Integration** - Related packages
5. **Best Practices** - Guidelines and standards

## Combining Skills

Multiple skills can activate together:

```
"Build a feature with API endpoints and real-time updates"
→ laravel-feature + laravel-api + laravel-websocket
```

## Creating Custom Triggers

Skills respond to natural language. Be specific:

| Less Effective | More Effective |
|---------------|----------------|
| "help with code" | "help with database queries" |
| "make something" | "build a feature for orders" |
| "fix this" | "fix the slow API endpoint" |

## See Also

- [Available Skills](available.md)
- [How Skills Work](how-skills-work.md)
- [Command Reference](../commands/index.md)
