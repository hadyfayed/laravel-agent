# Customizing Laravel Agent

The `laravel-agent` is designed to be flexible and adaptable to your specific needs. This guide will walk you through the process of customizing the agent's behavior by modifying existing agents and commands.

## Customizing Agents

Agents define the core logic of the `laravel-agent`. You can customize their behavior by editing the Markdown files in the `agents/` directory.

### 1. Locate the Agent File

Navigate to the `agents/` directory and find the Markdown file corresponding to the agent you want to customize. For example, to modify the `laravel-architect` agent, you would edit `agents/laravel-architect.md`.

### 2. Modify the Agent Definition

Open the agent file and modify the content to change its behavior. You can:

- **Change the description:** Update the `description` field in the front matter to change how the agent is described.
- **Modify the tools:** Add or remove tools from the `tools` list to change the agent's capabilities.
- **Update the prompts:** Edit the Markdown content to change the prompts and instructions given to the agent.

## Customizing Commands

Commands are the entry points for interacting with the `laravel-agent`. You can customize them by editing the Markdown files in the `commands/` directory.

### 1. Locate the Command File

Navigate to the `commands/` directory and find the Markdown file for the command you want to customize. For example, to modify the `build` command, you would edit `commands/build.md`.

### 2. Modify the Command Definition

Open the command file and modify the content to change its behavior. You can:

- **Change the description:** Update the `description` field in the front matter to change the command's description.
- **Modify the allowed tools:** Add or remove tools from the `allowed-tools` list to change the command's capabilities.
- **Update the process:** Edit the process description to change which agent is called or how arguments are passed.

## Customizing Project Templates

The `laravel-agent` uses project templates located in the `templates/` directory to scaffold new applications. You can customize these templates to fit your project's architecture and coding standards.

### 1. Locate the Template Directory

Navigate to the `templates/` directory and find the template you want to customize. For example, to modify the SaaS template, you would edit the files in `templates/saas/`.

### 2. Modify the Template Files

Open the template files and make any desired changes. You can add, remove, or modify files to create a custom starting point for your projects.
