---
description: "Starts an interactive session to guide you through the available commands."
allowed-tools: [Task]
---

# /interactive - Interactive Mode

The `/interactive` command starts a guided, step-by-step session to help you find the right agent and command for your needs. This is a great way to explore the capabilities of the `laravel-agent` and get started with building your application.

## Usage

```bash
/laravel-agent:interactive
```

## Process

When you invoke this command, the `laravel-agent` will ask you a series of questions to understand your goals. Based on your answers, it will recommend the best command to use.

### Example

```
$ /laravel-agent:interactive

Welcome to the Laravel Agent interactive mode! What would you like to do?
1. Build a new feature
2. Create a reusable module
3. Generate a service or action
4. Scaffold a new application
5. Explore other commands

> 1

Great! What kind of feature would you like to build? (e.g., "invoice management system")

> an invoice management system

Perfect! The `build` command is the best tool for this. Here's how to use it:

`/laravel-agent:build invoice management system`

Would you like to run this command now? (y/n)
```
