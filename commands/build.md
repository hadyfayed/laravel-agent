---
description: "Intelligent build - architect analyzes and decides implementation approach"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /build - Intelligent Laravel Builder

The `/build` command invokes the **laravel-architect** agent to analyze your request and determine the best implementation approach. It's the recommended entry point for creating new functionality.

## Usage

```bash
/laravel-agent:build [description of what you want to build]
```

## Input
$ARGUMENTS = The build request (e.g., "invoice system", "payment gateway", "user notifications")

## Examples

```bash
/laravel-agent:build invoice management system with PDF export
/laravel-agent:build user notification preferences
/laravel-agent:build payment gateway integration
/laravel-agent:build product catalog with categories and variants
```

## Process

When you invoke this command, the architect will:

1. **Check for Laravel Boost MCP tools** - Leverage existing tooling if available
2. **Scan codebase structure** - Understand existing patterns and conventions
3. **Check pattern registry** - Review `.ai/patterns/registry.json` (max 5 patterns)
4. **Decide implementation type** - Feature, Module, Service, or Action
5. **Consider tenancy requirements** - Check if multi-tenant isolation is needed
6. **Ensure SOLID/DRY compliance** - Validate architectural decisions
7. **Delegate to appropriate builder** - Hand off to specialized agent
8. **Verify with tests** - Ensure implementation is properly tested

### Implementation Details

Use the Task tool with subagent_type `laravel-architect`:

```
Analyze and implement the following request:

"$ARGUMENTS"

Follow your full decision protocol:
1. Check for Laravel Boost MCP tools
2. Scan codebase structure
3. Check pattern registry (.ai/patterns/registry.json)
4. Decide implementation type (Feature/Module/Service/Action)
5. Consider tenancy requirements
6. Ensure SOLID/DRY compliance
7. Delegate to appropriate builder agent
8. Verify implementation with tests
```

### Report Results

After completion, summarize:
- What was built
- Location
- How to use it
- Manual steps needed

## Decision Matrix

| Command Example | Decision | Result Location |
|-----------------|----------|-----------------|
| `/build invoice system` | Feature | `app/Features/Invoices/` |
| `/build pricing calculator` | Module | `app/Modules/Pricing/` |
| `/build send welcome email` | Action | `app/Actions/Users/SendWelcomeEmailAction.php` |
| `/build payment service` | Service | `app/Services/PaymentService.php` |

## Related Agent

This command uses the [laravel-architect](/agents/laravel-architect.md) agent, which then delegates to specialized builders based on the analysis.

## See Also

- [/laravel-agent:feature:make](/commands/feature-make.md) - Direct feature creation (bypasses architect)
- [/laravel-agent:module:make](/commands/module-make.md) - Create reusable domain module
- [/laravel-agent:service:make](/commands/service-make.md) - Create service or action
