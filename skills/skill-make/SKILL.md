---
name: skill-make
description: Scaffold a Claude Code skill with directory structure, references, and evals; when creating a skill.
disable-model-invocation: true
allowed-tools: Read Write Edit Bash(mkdir *) Bash(test *) Bash(find *)
argument-hint: "<skill-name> [description]"
---

## Task

Create a new skill scaffolding in `skills/<skill-name>/` with directory structure, SKILL.md, and evals.

## Input

Parse `$ARGUMENTS`:
- `<skill-name>`: skill directory name (kebab-case; will be stored under `skills/<skill-name>/`)
- `[description]`: optional one-line skill purpose

## Steps

1. **Validate name** — kebab-case, no colons, no spaces. Exit if invalid.

2. **Check existence** — `test -d skills/<skill-name>`. If exists, report and skip.

3. **Create directory structure**:
   ```bash
   mkdir -p skills/<skill-name>/references
   mkdir -p skills/<skill-name>/evals
   ```

4. **Generate** `skills/<skill-name>/SKILL.md`:

```markdown
---
name: <skill-name>
description: Scaffold a Claude Code skill with directory structure, references, and evals; when creating a skill.
  <Trigger-rich one-line description: what action + when>.
disable-model-invocation: true
allowed-tools: <tools the skill needs>
argument-hint: "[arguments]"
---

## Context

<Brief description of what this skill does and when it activates.>

## Workflow

1. **Understand** — Parse the request and identify the goal
2. **Analyze** — Gather context from the codebase
3. **Execute** — Perform the main action
4. **Verify** — Validate the result
5. **Report** — Summarize what was done

## Key Patterns

### Pattern 1: <Name>
<Description and usage>

## Examples

### Example 1: <Scenario>
Input: "<user request>"
Result: <what happens>

## Related Skills

- `<related-skill-1>` - <relationship>
```

5. **Generate** `skills/<skill-name>/evals/evals.json`:

```json
{
  "skill": "<skill-name>",
  "cases": [
    {
      "prompt": "<user message that should trigger this skill>",
      "expect": "<one-sentence description of correct outcome>"
    },
    {
      "prompt": "<another trigger>",
      "expect": "<expected behavior>"
    }
  ]
}
```

6. **Create** `skills/<skill-name>/references/README.md`:
```markdown
# References for <skill-name>

Add reference files here:
- `topic-a.md` — Description
- `topic-b.md` — Description
```

7. **Report creation**:
   - Directory: `skills/<skill-name>/`
   - Files: SKILL.md, evals/evals.json, references/README.md
   - Next: read `docs/architecture/skill-standard.md` for skill kind (reference/scaffolder/utility) and customize as needed
