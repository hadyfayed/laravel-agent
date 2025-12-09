---
description: "Intelligent build - architect analyzes and decides implementation approach"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /build - Intelligent Laravel Builder

Invoke the **laravel-architect** agent to analyze the request and decide the best implementation approach.

## Input
$ARGUMENTS = The build request (e.g., "invoice system", "payment gateway", "user notifications")

## Process

1. **Invoke the Architect**

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

2. **Report Results**

After completion, summarize:
- What was built
- Location
- How to use it
- Manual steps needed

## Examples

| Command | Decision | Result |
|---------|----------|--------|
| `/build invoice system` | Feature | `app/Features/Invoices/` |
| `/build pricing calculator` | Module | `app/Modules/Pricing/` |
| `/build send welcome email` | Action | `app/Actions/Users/SendWelcomeEmailAction.php` |
| `/build payment service` | Service | `app/Services/PaymentService.php` |
