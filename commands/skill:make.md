---
description: "Create a new auto-invoked skill with progressive disclosure architecture"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /skill:make - Create Claude Code Skill

Create a new auto-invoked skill with proper progressive disclosure tiers.

## Input
$ARGUMENTS = `<skill-name> [description] [--triggers=<trigger-phrases>]`

Examples:
- `/skill:make database-optimizer "Optimizes database queries and schema"`
- `/skill:make api-tester "Tests API endpoints" --triggers="test api,api test,endpoint test"`
- `/skill:make code-documenter "Generates documentation for code"`

## Process

1. **Parse Arguments**
   - `name`: Skill ID (kebab-case)
   - `description`: What the skill does
   - `--triggers`: Comma-separated trigger phrases

2. **Gather Skill Details**

   If not provided, ask:
   ```
   Skill Configuration:
   - Name/ID: <parsed>
   - Display Name: <ask>
   - Description: <parsed or ask>
   - Trigger phrases: <parsed or ask>
   - Associated agent: <ask, optional>
   - Complexity: low / medium / high
   - Required packages: <ask, optional>
   ```

3. **Create Directory Structure**

   ```bash
   mkdir -p skills/<skill-name>/references/{patterns,examples,edge-cases}
   ```

4. **Generate Tier 1: Metadata (meta.md)**

   Create `skills/<skill-name>/meta.md`:

   ```markdown
   ---
   id: <skill-name>
   name: <Display Name>
   version: 1.0.0
   description: <One-line description>
   triggers:
     - "<trigger phrase 1>"
     - "<trigger phrase 2>"
     - "<trigger phrase 3>"
   packages:
     - <package-name> (optional)
   complexity: low|medium|high
   tokens: ~<estimated>
   ---

   <Brief summary of what this skill does and when to use it>

   **Quick Start:** `/<command>` or describe your need naturally.

   **Key Capabilities:**
   - <capability 1>
   - <capability 2>
   - <capability 3>
   ```

5. **Generate Tier 2: Core Instructions (SKILL.md)**

   Create `skills/<skill-name>/SKILL.md`:

   ```markdown
   # <Display Name>

   <Detailed description of the skill>

   ## Quick Start

   ```bash
   /<associated-command> <example>
   ```

   Or simply describe what you need:
   > "<example natural language request>"

   ## When This Skill Activates

   This skill is automatically invoked when you:
   - <trigger scenario 1>
   - <trigger scenario 2>
   - <trigger scenario 3>

   ## Key Patterns

   ### Pattern 1: <Name>
   <Description and usage>

   ### Pattern 2: <Name>
   <Description and usage>

   ## Workflow

   1. **Analyze** - Understand the request
   2. **Explore** - Gather context from codebase
   3. **Execute** - Perform the main action
   4. **Verify** - Validate the result
   5. **Report** - Summarize what was done

   ## Common Options

   | Option | Description | Default |
   |--------|-------------|---------|
   | `--option1` | Description | value |
   | `--option2` | Description | value |

   ## Output Structure

   ```
   <expected-output-structure>
   ```

   ## Examples

   ### Example 1: <Scenario>
   ```
   Input: "<user request>"
   Result: <what happens>
   ```

   ### Example 2: <Scenario>
   ```
   Input: "<user request>"
   Result: <what happens>
   ```

   ## Related Skills

   - `<related-skill-1>` - <relationship>
   - `<related-skill-2>` - <relationship>
   ```

6. **Generate Tier 3 Stubs**

   Create reference placeholders:

   `skills/<skill-name>/references/patterns/README.md`:
   ```markdown
   # Patterns for <Skill Name>

   Add pattern documentation files here:
   - `pattern-name.md` - Description
   ```

   `skills/<skill-name>/references/examples/README.md`:
   ```markdown
   # Examples for <Skill Name>

   Add example files here:
   - `example-name.md` - Description
   ```

   `skills/<skill-name>/references/edge-cases/README.md`:
   ```markdown
   # Edge Cases for <Skill Name>

   Document edge cases here:
   - `edge-case-name.md` - Description
   ```

7. **Update Skills Registry**

   Add to `skills/SKILLS.md` registry section:

   ```yaml
   - id: <skill-name>
     name: <Display Name>
     trigger: "<trigger phrases>"
     tier1: skills/<skill-name>/meta.md
     tier2: skills/<skill-name>/SKILL.md
     tier3: skills/<skill-name>/references/
     agent: <associated-agent>
   ```

8. **Report Success**

   ```markdown
   ## Skill Created: <skill-name>

   ### Files Created
   ```
   skills/<skill-name>/
   ├── meta.md          (Tier 1: ~100 tokens)
   ├── SKILL.md         (Tier 2: ~500-1000 tokens)
   └── references/
       ├── patterns/
       ├── examples/
       └── edge-cases/
   ```

   ### Triggers Registered
   - "<trigger 1>"
   - "<trigger 2>"

   ### How It Works

   1. User says something matching a trigger
   2. System loads Tier 1 (meta.md) - ~100 tokens
   3. If skill matches, loads Tier 2 (SKILL.md)
   4. For complex tasks, loads Tier 3 references

   ### Test It

   Try saying:
   > "<trigger phrase example>"

   ### Next Steps
   1. Edit `skills/<skill-name>/SKILL.md` to refine instructions
   2. Add reference patterns in `references/patterns/`
   3. Add examples in `references/examples/`
   4. Document edge cases
   ```

## Progressive Disclosure Tips

### Tier 1 (meta.md) - Always Loaded
- Keep under 100 tokens
- Focus on: ID, triggers, brief description
- Purpose: Quick skill matching

### Tier 2 (SKILL.md) - On Demand
- Keep between 500-1000 tokens
- Focus on: Workflow, key patterns, common usage
- Purpose: Execute most requests

### Tier 3 (references/) - Deep Dive
- Can be 2000+ tokens per file
- Focus on: Complex patterns, edge cases, examples
- Purpose: Handle complex/unusual requests
