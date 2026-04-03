---
description: "Create a new Claude Code slash command"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /command:make - Create Claude Code Command

Create a new slash command for a Claude Code plugin.

## Input
$ARGUMENTS = `<command-name> [description] [--agent=<agent-name>]`

Examples:
- `/command:make deploy:aws "Deploy to AWS infrastructure"`
- `/command:make test:e2e "Run end-to-end tests" --agent=testing-agent`
- `/command:make db:seed "Seed database with test data"`

## Process

1. **Parse Arguments**
   - `name`: Command name (verb:noun format preferred)
   - `description`: What the command does
   - `--agent`: Optional agent to delegate to

2. **Validate Command Name**

   Preferred formats:
   - `verb:noun` (e.g., `feature:make`, `test:run`)
   - `noun` for simple actions (e.g., `build`, `deploy`)

   ```
   ✓ feature:make
   ✓ db:migrate
   ✓ deploy
   ✗ makeFeature (use kebab-case)
   ✗ DEPLOY (use lowercase)
   ```

3. **Determine Command Type**

   | Type | Characteristics | Tools Needed |
   |------|-----------------|--------------|
   | **Delegating** | Invokes an agent | Task, Read, Glob, Grep |
   | **Direct** | Executes directly | Read, Glob, Grep, Write, Edit, Bash |
   | **Hybrid** | Both direct + delegation | All tools |

4. **Generate Command File**

   Create `commands/<command-name>.md`:

   **For Delegating Commands:**
   ```markdown
   ---
   description: "<description>"
   allowed-tools: Task, Read, Glob, Grep
   ---

   # /<command-name> - <Title>

   <Brief description>

   ## Input
   $ARGUMENTS = `<expected-arguments>`

   Examples:
   - `/<command-name> example1`
   - `/<command-name> example2 with options`

   ## Process

   1. **Parse Arguments**
      - `arg1`: Description
      - `arg2`: Description (optional)

   2. **Validate Input**
      - Check required arguments
      - Validate format

   3. **Delegate to Agent**

      Use Task tool with subagent_type `<agent-name>`:
      ```
      Execute the following request:

      Input: $ARGUMENTS
      Context: <any additional context>

      Follow your standard workflow.
      ```

   4. **Report Results**

      Pass through agent's response to user.
   ```

   **For Direct Commands:**
   ```markdown
   ---
   description: "<description>"
   allowed-tools: Read, Glob, Grep, Write, Edit, MultiEdit, Bash
   ---

   # /<command-name> - <Title>

   <Brief description>

   ## Input
   $ARGUMENTS = `<expected-arguments>`

   Examples:
   - `/<command-name> example1`
   - `/<command-name> example2`

   ## Process

   1. **Parse Arguments**
      - `arg1`: Description

   2. **Execute**

      <Step-by-step execution logic>

   3. **Report Results**
      ```markdown
      ## <Command> Complete

      ### Summary
      - Result 1
      - Result 2

      ### Files Modified
      - `path/to/file`

      ### Next Steps
      1. Step 1
      2. Step 2
      ```
   ```

5. **Update plugin.json**

   Add to commands array:
   ```json
   {
     "commands": [
       "./commands/<command-name>.md"
     ]
   }
   ```

6. **Report Success**

   ```markdown
   ## Command Created: /<command-name>

   ### File Created
   - `commands/<command-name>.md`

   ### Configuration Updated
   - `plugin.json` - Added to commands array

   ### Usage
   ```bash
   /<plugin-name>:<command-name> <arguments>
   ```

   ### Test It
   ```bash
   /<plugin-name>:<command-name> --help
   ```

   ### Next Steps
   1. Edit `commands/<command-name>.md` to customize logic
   2. Add examples and edge cases
   3. Test the command
   ```

## Command Patterns

### Pattern 1: Simple Delegating Command
```markdown
Use Task tool with subagent_type `<agent>`:
```
<prompt>
```
```

### Pattern 2: Interactive Command
```markdown
1. Ask user for input:
   - Option A: Description
   - Option B: Description

2. Based on selection, proceed with...
```

### Pattern 3: Multi-Step Command
```markdown
1. **Step 1**: Do X
2. **Step 2**: Do Y
3. **Step 3**: Report Z
```

### Pattern 4: Conditional Command
```markdown
If condition A:
  - Do X
Else if condition B:
  - Do Y
Else:
  - Do Z
```
