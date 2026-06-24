---
name: agent-make
description: >
  Scaffold a new Claude Code agent file (.md with frontmatter, role, capabilities, and workflow).
  Use when creating a plugin agent.
disable-model-invocation: true
allowed-tools: Read Write Edit Bash(mkdir *) Bash(test *) Bash(find *)
argument-hint: "<agent-name> [description]"
---

## Task

Create a new agent scaffolding in `agents/<agent-name>.md` with proper structure.

## Input

Parse `$ARGUMENTS`:
- `<agent-name>`: agent filename (kebab-case; will be stored as `agents/<agent-name>.md`)
- `[description]`: optional one-line agent purpose

## Steps

1. **Validate name** — kebab-case, no colons, no spaces. Exit if invalid.

2. **Check existence** — `test -f agents/<agent-name>.md`. If exists, report and skip.

3. **Create directory** if needed: `mkdir -p agents`

4. **Generate** `agents/<agent-name>.md`:

```markdown
---
name: <agent-name>
description: >
  <One-line description of what this agent does.
  Include key capabilities and when to use.>
tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash
---

# Role

You are a senior engineer specialized in <domain>.
Your approach is <personality traits>.

**Mindset:** "<guiding principle>"

# Capabilities

## What You Can Do
- <capability 1>
- <capability 2>
- <capability 3>

## What You Should NOT Do
- <limitation 1>
- <limitation 2>

# Workflow

## Phase 1: UNDERSTAND
**Goal:** Fully understand the request

1. Parse the request
2. Identify key requirements
3. Check for ambiguities

## Phase 2: ANALYZE
**Goal:** Gather context

1. Explore relevant files
2. Check existing patterns
3. Identify dependencies

## Phase 3: EXECUTE
**Goal:** Perform the main task

1. <main action 1>
2. <main action 2>
3. <main action 3>

## Phase 4: VERIFY
**Goal:** Ensure quality

1. Validate output
2. Check for errors
3. Run tests if applicable

## Phase 5: REPORT
**Goal:** Summarize results

Output:
```markdown
## Complete

### Summary
- <what was done>

### Files Created/Modified
- `path/to/file` - Description

### Recommendations
- <next steps>
```

# Guardrails

- NEVER execute destructive operations without explicit confirmation
- ALWAYS validate input before processing
- ALWAYS report file paths in output

# Delegation

When you need another agent:
| Situation | Delegate To |
|-----------|-------------|
| <situation> | <agent-name> |

# Examples

## Example 1: <scenario>
Input: "<user request>"
Output: Creates agent file with full structure
```

5. **Report creation**:
   - File path: `agents/<agent-name>.md`
   - Next: edit the agent file to customize role, capabilities, and workflows
