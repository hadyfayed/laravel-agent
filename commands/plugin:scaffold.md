---
description: "Scaffold a complete Claude Code plugin with manifests, directories, and configuration"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /plugin:scaffold - Create Claude Code Plugin

Scaffold a complete Claude Code plugin structure ready for development and marketplace distribution.

## Input
$ARGUMENTS = `<plugin-name> [description]`

Examples:
- `/plugin:scaffold my-awesome-plugin`
- `/plugin:scaffold jira-assistant A Jira integration plugin for Claude Code`
- `/plugin:scaffold laravel-helper with auth, testing, and deployment agents`

## Process

1. **Parse Arguments**
   - `name`: Plugin name (kebab-case)
   - `description`: Optional description

2. **Gather Information**

   Ask user (if not provided):
   ```
   Plugin Details:
   - Name: <parsed or ask>
   - Description: <parsed or ask>
   - Author name: <ask>
   - GitHub URL: <ask, optional>
   - Initial agents: <ask, comma-separated>
   - Initial commands: <ask, comma-separated>
   ```

3. **Create Directory Structure**

   ```bash
   mkdir -p <plugin-name>/{.claude-plugin,agents,commands,skills,hooks/scripts,.ai/guidelines,docs}
   ```

4. **Generate plugin.json**

   ```json
   {
     "name": "<plugin-name>",
     "version": "1.0.0",
     "description": "<description>",
     "author": {
       "name": "<author>",
       "url": "<url>"
     },
     "license": "MIT",
     "keywords": [],
     "agents": [],
     "commands": []
   }
   ```

5. **Generate marketplace.json**

   ```json
   {
     "name": "<plugin-name>",
     "description": "<description>",
     "owner": {
       "name": "<author>",
       "url": "<github-url>"
     },
     "plugins": [
       {
         "name": "<plugin-name>",
         "source": "./",
         "description": "<full description>",
         "version": "1.0.0"
       }
     ]
   }
   ```

6. **Generate CLAUDE.md**

   ```markdown
   # <Plugin Name>

   <description>

   ## Quick Start

   ```bash
   /plugin marketplace add <owner>/<plugin-name>
   /plugin install <plugin-name>@<owner>-<plugin-name>
   ```

   ## Available Commands

   (List will be populated as commands are added)

   ## Available Agents

   (List will be populated as agents are added)

   ## Development

   ### Adding a Command
   ```bash
   /command:make <command-name> "<description>"
   ```

   ### Adding an Agent
   ```bash
   /agent:make <agent-name> "<description>"
   ```
   ```

7. **Generate README.md**

   ```markdown
   # <Plugin Name>

   <description>

   ## Installation

   ### Via Claude Code Marketplace
   ```bash
   /plugin marketplace add <owner>/<plugin-name>
   /plugin install <plugin-name>@<owner>-<plugin-name>
   ```

   ### Manual Installation
   Clone this repository into your `.claude-plugins` directory.

   ## Features

   - (Add features here)

   ## Commands

   | Command | Description |
   |---------|-------------|
   | (Add commands here) |

   ## Agents

   | Agent | Description |
   |-------|-------------|
   | (Add agents here) |

   ## License

   MIT
   ```

8. **Generate Supporting Files**

   - `LICENSE` (MIT)
   - `CHANGELOG.md` (initial entry)
   - `.gitignore`
   - `hooks/hooks.example.json`

9. **Initialize Git (Optional)**

   ```bash
   cd <plugin-name> && git init
   ```

10. **Report Results**

    ```markdown
    ## Plugin Scaffolded: <plugin-name>

    ### Structure Created
    ```
    <plugin-name>/
    ├── .claude-plugin/
    │   ├── plugin.json
    │   └── marketplace.json
    ├── agents/
    ├── commands/
    ├── skills/
    ├── hooks/
    │   ├── hooks.example.json
    │   └── scripts/
    ├── .ai/
    │   └── guidelines/
    ├── docs/
    ├── CLAUDE.md
    ├── README.md
    ├── LICENSE
    ├── CHANGELOG.md
    └── .gitignore
    ```

    ### Next Steps
    1. Add agents: `/agent:make <name> "<description>"`
    2. Add commands: `/command:make <name> "<description>"`
    3. Add skills: `/skill:make <name> "<description>"`
    4. Push to GitHub for marketplace distribution
    5. Publish: `/plugin:publish`
    ```

## Quick Scaffold (Minimal)

For a minimal plugin with just manifests:
```
/plugin:scaffold <name> --minimal
```

Creates only:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `CLAUDE.md`
- `README.md`
