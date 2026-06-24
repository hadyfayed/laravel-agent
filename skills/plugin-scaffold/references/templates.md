# Claude Plugin & Command Templates

## Complete Plugin Layout

```
<plugin-name>/
├── .claude-plugin/
│   ├── plugin.json          # Main manifest
│   └── marketplace.json     # Marketplace listing
├── agents/
│   └── <agent-name>.md      # Agent definitions
├── commands/
│   └── <command>.md         # Slash commands
├── skills/
│   ├── SKILLS.md            # Skills registry
│   └── <skill-name>/
│       ├── meta.md          # Tier 1: Metadata
│       ├── SKILL.md         # Tier 2: Core instructions
│       └── references/      # Tier 3: Deep dive
├── hooks/
│   ├── hooks.example.json   # Hook configuration
│   └── scripts/             # Hook scripts
├── mcp/                     # Optional MCP extension
│   ├── composer.json
│   └── src/
├── .ai/
│   └── guidelines/          # AI coding standards
├── docs/                    # Documentation site
├── CLAUDE.md                # Project instructions
├── README.md
├── LICENSE
└── CHANGELOG.md
```

## Plugin Manifest (plugin.json)

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "<description>",
  "author": {
    "name": "<author-name>",
    "url": "<url>"
  },
  "license": "MIT",
  "keywords": ["<keyword1>", "<keyword2>"],
  "agents": [
    "./agents/<agent>.md"
  ],
  "commands": [
    "./commands/<command>.md"
  ]
}
```

## Marketplace Manifest (marketplace.json)

```json
{
  "name": "<plugin-name>",
  "description": "<marketplace description>",
  "owner": {
    "name": "<owner-name>",
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

## Agent Template

```markdown
---
name: <agent-name>
description: >
  <Multi-line description of what this agent does.
  Include key capabilities and when to use it.>
tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# ROLE
<Define the agent's expertise, personality, and approach>

# CAPABILITIES
<List what this agent can do>

# WORKFLOW
<Step-by-step process the agent follows>

# GUARDRAILS
<Rules the agent must follow>

# OUTPUT FORMAT
<How the agent should structure its responses>
```

## Command Template

```markdown
---
description: "<One-line description>"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /<command-name> - <Title>

<Brief description of what this command does>

## Input
$ARGUMENTS = `<expected-arguments>`

Examples:
- `/<command-name> arg1`
- `/<command-name> arg1 with options`

## Process

1. **Parse Arguments**
   - `param1`: First word
   - `param2`: Remaining text

2. **Validate**
   <Validation steps>

3. **Execute**
   <Main logic or agent delegation>

4. **Report Results**
   \`\`\`markdown
   ## <Command> Complete

   ### Summary
   - <result summary>

   ### Next Steps
   - <follow-up actions>
   \`\`\`
```

## Skill Template (meta.md - Tier 1)

```markdown
---
id: <skill-id>
name: <Display Name>
version: 1.0.0
description: <One-line description>
triggers:
  - "<trigger phrase 1>"
  - "<trigger phrase 2>"
packages: []
complexity: low|medium|high
tokens: ~<estimated>
---

<Brief summary of what this skill does>

Use: `/<command>` or ask the agent for recommendations.
```

## Skill Template (SKILL.md - Tier 2)

```markdown
# <Skill Name>

## Quick Start
\`\`\`bash
/<command> <example>
\`\`\`

## Key Patterns
1. **Pattern 1** - Description
2. **Pattern 2** - Description

## Common Options
- `--option1`: Description
- `--option2`: Description

## Output Structure
\`\`\`
<expected-output-structure>
\`\`\`
```

## MCP Tool Template (PHP)

```php
<?php

namespace <Namespace>\Mcp\Tools;

use PhpMcp\Server\Attributes\McpTool;
use PhpMcp\Server\Attributes\ToolParameter;

#[McpTool(
    name: '<tool-name>',
    description: '<description>'
)]
class <ToolName>Tool
{
    public function __construct(
        protected <Service> $service
    ) {}

    public function __invoke(
        #[ToolParameter(description: '<param description>')]
        string $param1,

        #[ToolParameter(description: '<param description>', required: false)]
        ?int $param2 = null
    ): array {
        // Implementation
        return [
            'success' => true,
            'data' => $result,
        ];
    }
}
```

## Scaffolding Workflows

### Complete Plugin
1. Create directory structure
2. Generate plugin.json with provided metadata
3. Generate marketplace.json
4. Create CLAUDE.md
5. Create README.md
6. Create LICENSE (MIT default)
7. Create CHANGELOG.md
8. Initialize git if requested

### Agent
1. Parse agent name and description
2. Determine required tools based on purpose
3. Generate agent markdown
4. Add to plugin.json agents array
5. Report success

### Command
1. Parse command name and description
2. Determine if it delegates to an agent
3. Generate command markdown
4. Add to plugin.json commands array
5. Report success

### Skill
1. Create skill directory structure
2. Generate meta.md (Tier 1)
3. Generate SKILL.md (Tier 2)
4. Create references directory
5. Update SKILLS.md registry
6. Report success

### MCP Tool
1. Create tool class file
2. Add service injection if needed
3. Register tool in MCP service provider
4. Generate tool documentation
5. Report success

## Naming Conventions

- Plugin names: `kebab-case`
- Agent names: `kebab-case` (e.g., `laravel-architect`)
- Command names: `verb:noun` (e.g., `feature:make`)
- Skill IDs: `kebab-case`
- MCP tools: `verb_noun` (e.g., `get_issue`)

## Required Fields

- Plugins: name, version, description
- Agents: name, description, tools
- Commands: description, allowed-tools
- Skills: id, name, triggers
- MCP tools: name, description

## Tool Permissions

- **Read-only agents**: Read, Grep, Glob
- **Builder agents**: Read, Grep, Glob, Edit, Write, MultiEdit, Bash
- **Orchestrator agents**: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
