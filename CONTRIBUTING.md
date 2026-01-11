# Contributing to Laravel Agent

We welcome contributions from the community! Whether you're fixing a bug, adding a new feature, or improving documentation, your help is greatly appreciated. This guide will walk you through the process of extending the `laravel-agent` with new agents, commands, and skills.

## Adding a New Agent

Agents are the core of the `laravel-agent` and are responsible for handling specific tasks. They are defined as Markdown files in the `agents/` directory.

### 1. Create the Agent File

Create a new Markdown file in the `agents/` directory, following the naming convention `[agent-name].md`. For example, `agents/laravel-new-feature.md`.

### 2. Define the Agent

In the new file, define the agent's behavior using Markdown. Here's a basic template:

```markdown
---
name: laravel-new-feature
description: "Description of the new feature."
tools: [Task, Read, Write, Bash]
---

# ROLE
You are a specialized agent for handling [new-feature].

# GOAL
Your goal is to [objective of the agent].

# RULES
- Rule 1
- Rule 2

# OUTPUT FORMAT
- Desired output format
```

## Adding a New Command

Commands are the entry points for interacting with the `laravel-agent`. They are defined as Markdown files in the `commands/` directory.

### 1. Create the Command File

Create a new Markdown file in the `commands/` directory, such as `commands/new-command.md`.

### 2. Define the Command

In the new file, define the command's behavior. Here's a template:

```markdown
---
description: "Description of the new command."
allowed-tools: [Task]
---

# /new-command - Description

This command invokes the `[agent-name]` agent.

## Usage
/laravel-agent:new-command [arguments]

## Input
$ARGUMENTS = The input for the command.

## Process
Use the Task tool with subagent_type `[agent-name]`:
"Analyze and process the following request: $ARGUMENTS"
```

## Adding a New Skill

Skills are auto-invoked based on context and are defined in the `skills/` directory.

### 1. Create the Skill File

Create a new Markdown file in the `skills/` directory, such as `skills/new-skill.md`.

### 2. Define the Skill

In the new file, define the skill's triggers and behavior.

```markdown
---
name: new-skill
triggers: ["keyword1", "keyword2"]
tools: [Task]
---

# New Skill

This skill is triggered by the keywords "keyword1" or "keyword2".
It invokes the `[agent-name]` agent to handle the request.
```
