---
description: "Generate comprehensive tests for a class or feature"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /test:make - Generate Tests

Generate comprehensive Pest tests for any class, feature, or API.

## Input
$ARGUMENTS = `<Target> [type] [coverage]`

Examples:
- `/test:make OrderService` - Unit tests for service
- `/test:make Orders feature` - Feature tests for Orders
- `/test:make api/v1/products api` - API tests
- `/test:make Checkout browser` - Dusk browser tests
- `/test:make Invoice all comprehensive` - All test types

## Types
- `unit` - Isolated class tests
- `feature` - HTTP/controller tests
- `api` - API endpoint tests
- `browser` - Dusk tests
- `all` - Generate all types

## Coverage Levels
- `basic` - Happy path only
- `comprehensive` - Happy path + edge cases + errors (default)
- `exhaustive` - All scenarios including performance

## Process

Use Task tool with subagent_type `laravel-testing`:
```
Generate tests:

Target: <target>
Type: <type>
Coverage: <coverage>
```
