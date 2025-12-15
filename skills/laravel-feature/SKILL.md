---
name: laravel-feature
description: >
  Build complete Laravel features with CRUD, views, API, and tests. Use when the user
  wants to create a new feature, implement functionality, or build a complete module
  with models, controllers, views, and tests. Triggers: "build feature", "create feature",
  "implement", "new module", "add functionality".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Feature Builder Skill

Build self-contained business features in Laravel following best practices.

## When to Use

- User wants to "build a feature" or "create functionality"
- Request involves CRUD operations with UI
- Need models, controllers, views, and tests together
- Building a complete business capability

## Quick Start

```bash
/laravel-agent:feature:make <FeatureName>
```

Or describe what you need and I'll build it.

## Structure Generated

```
app/Features/<Name>/
├── <Name>ServiceProvider.php
├── Domain/
│   ├── Models/<Name>.php
│   ├── Events/<Name>Created.php
│   └── Enums/<Name>Status.php
├── Http/
│   ├── Controllers/<Name>Controller.php
│   ├── Requests/Store<Name>Request.php
│   └── Resources/<Name>Resource.php
├── Database/
│   ├── Migrations/
│   └── Factories/
└── Tests/
    └── <Name>FeatureTest.php
```

## Key Patterns

1. **Service Provider** - Auto-registers routes, views, migrations
2. **Form Requests** - Centralized validation
3. **API Resources** - Consistent JSON responses
4. **Policies** - Authorization logic
5. **Events** - Decoupled side effects
6. **Factories** - Test data generation

## Decision Matrix

| Request Type | Implementation |
|--------------|----------------|
| CRUD + UI + API | Feature (this skill) |
| Reusable logic only | Module |
| Single operation | Action |
| Business orchestration | Service |

## Process

1. Analyze requirements
2. Check existing patterns in codebase
3. Generate model with relationships
4. Create migration with proper indexes
5. Build controller with CRUD methods
6. Add form requests with validation
7. Create views or API resources
8. Generate Pest tests
9. Register in service provider

## Best Practices

- Use `final class` for non-inheritable classes
- Declare `strict_types=1`
- Follow SOLID principles
- Max 5 design patterns per project
- Include factory and tests
