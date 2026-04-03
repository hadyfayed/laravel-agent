---
description: "Create a new Claude Code agent with proper structure and tools"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /agent:make - Create Claude Code Agent

Create a new specialized agent for a Claude Code plugin.

## Input
$ARGUMENTS = `<agent-name> [description] [--tools=<tool-list>]`

Examples:
- `/agent:make code-reviewer "Reviews code for quality and security issues"`
- `/agent:make api-builder "Builds REST APIs with documentation" --tools=Read,Write,Edit,Bash`
- `/agent:make deployment-expert "Handles AWS and Docker deployments"`

## Process

1. **Parse Arguments**
   - `name`: Agent name (kebab-case)
   - `description`: What the agent does
   - `--tools`: Optional comma-separated tool list

2. **Determine Agent Type**

   | Type | Purpose | Default Tools |
   |------|---------|---------------|
   | **Explorer** | Read-only analysis | Read, Grep, Glob |
   | **Builder** | Creates/modifies code | Read, Grep, Glob, Edit, Write, MultiEdit, Bash |
   | **Orchestrator** | Delegates to other agents | Read, Grep, Glob, Task |
   | **Reviewer** | Analyzes and reports | Read, Grep, Glob, Bash |
   | **Full** | All capabilities | Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task |

3. **Gather Agent Details**

   If not provided, ask:
   ```
   Agent Configuration:
   - Name: <parsed>
   - Description: <parsed or ask>
   - Type: Explorer / Builder / Orchestrator / Reviewer / Full
   - Expertise areas: <ask>
   - Key workflows: <ask>
   ```

4. **Generate Agent File**

   Create `agents/<agent-name>.md`:

   ```markdown
   ---
   name: <agent-name>
   description: >
     <Multi-line description of what this agent does.
     Include key capabilities and when to use proactively.>
   tools: <tool-list>
   ---

   # ROLE
   You are a <expertise> expert with deep knowledge in <domains>.
   Your approach is <personality traits>.

   **Mindset: "<guiding principle>"**

   # CAPABILITIES

   ## What You Can Do
   - <capability 1>
   - <capability 2>
   - <capability 3>

   ## What You Should NOT Do
   - <limitation 1>
   - <limitation 2>

   # WORKFLOW

   ## Phase 1: UNDERSTAND
   **Goal:** Fully understand the request

   1. Parse the user's request
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

   Output format:
   ```markdown
   ## <Agent Name> Complete

   ### Summary
   - <what was done>

   ### Files Created/Modified
   - `path/to/file` - Description

   ### Recommendations
   - <next steps>
   ```

   # GUARDRAILS

   - NEVER <prohibited action 1>
   - NEVER <prohibited action 2>
   - ALWAYS <required behavior 1>
   - ALWAYS <required behavior 2>

   # DELEGATION

   When to delegate to other agents:
   | Situation | Delegate To |
   |-----------|-------------|
   | <situation 1> | <agent-name> |
   | <situation 2> | <agent-name> |

   # EXAMPLES

   ## Example 1: <scenario>
   Input: "<user request>"
   Action: <what the agent does>
   Output: <expected result>

   ## Example 2: <scenario>
   Input: "<user request>"
   Action: <what the agent does>
   Output: <expected result>
   ```

5. **Update plugin.json**

   Add to agents array:
   ```json
   {
     "agents": [
       "./agents/<agent-name>.md"
     ]
   }
   ```

6. **Report Success**

   ```markdown
   ## Agent Created: <agent-name>

   ### File Created
   - `agents/<agent-name>.md`

   ### Configuration Updated
   - `plugin.json` - Added to agents array

   ### Tools Assigned
   - <tool-list>

   ### Usage

   **Via Task tool:**
   ```
   Use Task tool with subagent_type `<agent-name>`:
   <your prompt here>
   ```

   **Via command (if created):**
   ```bash
   /<plugin-name>:<command> <arguments>
   ```

   ### Next Steps
   1. Edit `agents/<agent-name>.md` to refine behavior
   2. Create a command to invoke this agent: `/command:make <cmd> --agent=<agent-name>`
   3. Add examples and edge cases
   4. Test the agent
   ```

## Agent Templates

### Template: Code Reviewer
```markdown
# ROLE
You are a senior code reviewer with expertise in security, performance, and best practices.

# WORKFLOW
1. Read the code to review
2. Check for security issues (OWASP Top 10)
3. Check for performance issues
4. Check for code quality (SOLID, DRY)
5. Report findings with severity levels
```

### Template: Builder Agent
```markdown
# ROLE
You are a code generation expert who creates clean, maintainable code.

# WORKFLOW
1. Understand requirements
2. Check existing patterns
3. Generate code following conventions
4. Add tests
5. Report what was created
```

### Template: Orchestrator Agent
```markdown
# ROLE
You are a coordinator who delegates tasks to specialized agents.

# WORKFLOW
1. Analyze the request
2. Determine which agents are needed
3. Delegate using Task tool
4. Combine results
5. Report overall outcome
```
