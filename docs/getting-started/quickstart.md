# Quick Start Guide

Get productive with Laravel Agent in 5 minutes.

## Your First Feature

Let the architect decide the best approach:

```bash
/laravel-agent:build user management with roles and permissions
```

The architect will:
1. Analyze your request
2. Scan your codebase for existing patterns
3. Decide implementation type (Feature/Module/Service)
4. Generate code with tests
5. Verify everything works

## Direct Commands

For specific tasks, use direct commands:

### Create a Feature
```bash
/laravel-agent:feature:make Products with categories and inventory
```

### Create an API
```bash
/laravel-agent:api:make Products v1
```

### Generate Tests
```bash
/laravel-agent:test:make ProductService
```

### Security Audit
```bash
/laravel-agent:security:audit
```

## Using Skills (Automatic)

Skills activate automatically based on context. Just describe what you need:

| Say This | Skill Activated |
|----------|-----------------|
| "Build a feature for..." | laravel-feature |
| "Create an API endpoint for..." | laravel-api |
| "Write tests for..." | laravel-testing |
| "The app is slow, help me..." | laravel-performance |
| "Add authentication..." | laravel-auth |

## Common Workflows

### Building a CRUD Feature

```bash
# Option 1: Let architect decide
/laravel-agent:build invoice management with PDF export

# Option 2: Direct feature command
/laravel-agent:feature:make Invoices with line items and PDF generation
```

### Creating an API

```bash
# Create versioned API
/laravel-agent:api:make Orders v1

# Generate documentation
/laravel-agent:api:docs
```

### Adding Authentication

```bash
# Setup auth with roles
/laravel-agent:auth:setup

# Or just describe it
"Add role-based authentication with admin and user roles"
```

### Database Operations

```bash
# Optimize queries
/laravel-agent:db:optimize

# Generate diagram
/laravel-agent:db:diagram
```

### Deployment

```bash
# Setup deployment
/laravel-agent:deploy:setup vapor

# Setup CI/CD
/laravel-agent:cicd:setup github
```

## Code Review

Before committing:

```bash
# Review staged changes
/laravel-agent:review:staged

# Create smart commit
/laravel-agent:git:commit
```

## Best Practices

### 1. Start with `/laravel-agent:build`

Let the architect analyze your request and decide the best approach.

### 2. Use Natural Language

Skills respond to natural language. Just describe what you need:

> "I need to add a notification system that sends emails and Slack messages when orders are placed"

### 3. Review Generated Code

Always review generated code before committing. Use:

```bash
/laravel-agent:review:staged
```

### 4. Run Tests

After generating features, run tests:

```bash
php artisan test
```

### 5. Check Patterns

Keep patterns under control:

```bash
/laravel-agent:patterns
```

## Next Steps

- [Command Reference](../commands/index.md) - All available commands
- [Skills Overview](../skills/index.md) - How skills work
- [Building Features Guide](../guides/building-features.md) - In-depth guide
