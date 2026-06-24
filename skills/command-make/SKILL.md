---
name: command-make
description: Scaffold a Claude Code slash-command with frontmatter and prompt; when creating a plugin command.
disable-model-invocation: true
allowed-tools: Read Write Edit Bash(mkdir *) Bash(test *) Bash(find *)
argument-hint: "<command-name> [description]"
---

## Task

Create a new command scaffolding in `commands/<command-name>.md` with proper structure.

## Input

Parse `$ARGUMENTS`:
- `<command-name>`: command filename (kebab-case or `verb:noun` format)
- `[description]`: optional one-line command purpose

## Steps

1. **Validate name** — kebab-case with optional colon (e.g. `feature:make`), no spaces. Exit if invalid.

2. **Check existence** — `test -f commands/<command-name>.md`. If exists, report and skip.

3. **Create directory** if needed: `mkdir -p commands`

4. **Generate** `commands/<command-name>.md`:

```markdown
---
description: Scaffold a Claude Code slash-command with frontmatter and prompt; when creating a plugin command.
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# /<command-name> - <Title>

<One-line description of what this command does>

## Input

$ARGUMENTS = `<expected-arguments>`

Examples:
- `/<command-name> example1`
- `/<command-name> example2`

## Process

1. **Parse Arguments**
   - `arg1`: Description
   - `arg2`: Description (optional)

2. **Validate Input**
   - Check required arguments
   - Validate format

3. **Execute**

   <Step-by-step execution logic>

4. **Report Results**

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

5. **Report creation**:
   - File path: `commands/<command-name>.md`
   - Next: edit the command file to customize description, logic, and process steps
