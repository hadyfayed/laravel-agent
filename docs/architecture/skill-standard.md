# laravel-agent Skill Standard

**Version:** 3.0.0-draft
**Effective from:** rebuild/skill-standard-v3

This document is the written contract that every skill in `laravel-agent` follows. Tasks 8–10 (the three pilot conversions) and all subsequent wave conversions must conform to it. The rules here mirror the design spec at `docs/superpowers/specs/2026-06-23-laravel-agent-rebuild-design.md` and the classifier logic in `scripts/build-catalog.mjs`.

---

## 1. The three skill kinds and how they are detected

Every topic resolves to exactly one of three kinds. The canonical detector is `classifySkill` in `scripts/build-catalog.mjs`. The rules are evaluated in order; the **first matching rule wins**:

```
1. context contains 'fork'                        → scaffolder
2. disable-model-invocation equals string 'true'  → utility
3. neither                                         → reference
```

Because the check is ordered, a skill that carries both `context: fork` and `disable-model-invocation: true` is classified as a **scaffolder** (rule 1 wins). A skill that carries neither is classified as a **reference** by absence of both signals.

The three kinds and their intended use are:

| Kind | Core signal | Retains an agent? | Execution |
| :--- | :--- | :--- | :--- |
| **Reference** | no invocation lock; no fork | No | Inline; auto-triggers on topic mentions |
| **Scaffolder** | `context: fork` + `agent:` | **Yes** (one retained worker) | Forks a sub-agent session; `SKILL.md` is the task prompt |
| **Utility** | `disable-model-invocation: true` | No | Runs defined tool steps; no model call for the skill body |

### Reference

A reference skill provides knowledge and conventions that Claude applies while already in conversation. It auto-triggers when the description's trigger phrases appear in the user's message. Claude executes inline — no fork, no lock. The `SKILL.md` is a guidance document, not a task prompt. Deep material lives in `references/*.md` and is injected or referenced by the skill.

### Scaffolder

A scaffolder skill handles tasks that produce a coordinated multi-file unit (a feature, module, API surface, admin panel, component) or that perform a deep read-and-judge audit. `context: fork` isolates the work in a dedicated sub-agent session; `agent:` names the retained heavy worker that actually executes. The `SKILL.md` is the task prompt delivered to that agent. The classification test (`tests:`) applied during design:

- Generates three or more related files as one coherent unit, **or**
- Audits or reviews an entire codebase.

### Utility

A utility skill handles a single bounded action: a one-shot generator, a setup wizard, a git operation, or a report. `disable-model-invocation: true` prevents the skill body from triggering a model invocation; the skill instead runs defined tool steps or shell commands (via `allowed-tools` and dynamic injection). There is no retained agent; any topic knowledge lives in the skill's own `references/`.

---

## 2. Required frontmatter per kind

The supported Claude Code skill frontmatter fields are: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`. The user-facing invocation name is derived from the skill's directory name, namespaced as `laravel-agent:<skill-name>`.

### 2.1 Reference — required and expected fields

Required: `name`, `description`.
No `context`, no `disable-model-invocation`, no `agent`.

The `description` field must include trigger phrases so auto-trigger fires on relevant user messages.

```yaml
---
name: laravel-database
description: >
  Apply Laravel database best practices: migrations, schema design, Eloquent
  relationships, N+1 query detection, Big O complexity fixes, and index strategy.
  Triggers: "migration", "schema", "N+1", "eloquent", "query", "index", "database".
---
```

### 2.2 Scaffolder — required and expected fields

Required: `name`, `description`, `context: fork`, `agent: laravel-<topic>`.
Optional: `argument-hint` (shown in command palette), `allowed-tools` (passed to the forked session).

The `agent` value must be the exact filename stem of the retained agent in `agents/`.

```yaml
---
name: laravel-feature
description: >
  Build a complete Laravel feature with models, controllers, migrations, views,
  policies, and tests as a self-contained unit under app/Features/<Name>.
  Triggers: "build feature", "create feature", "implement", "crud", "new module".
context: fork
agent: laravel-feature
argument-hint: "<FeatureName> [--tenancy]"
---
```

### 2.3 Utility — required and expected fields

Required: `name`, `description`, `disable-model-invocation: true`, `allowed-tools`.
Optional: `argument-hint`, dynamic context injection (see §5).

The `allowed-tools` list scopes what tools the skill's steps may use; pattern-scoping is supported, e.g. `Bash(git *)` to restrict to specific commands. List each tool that the skill's shell commands or file operations need. Utility skills do not carry `context: fork` or `agent:`.

```yaml
---
name: git-commit
description: >
  Stage and commit the current working-tree changes with a conventional-commit
  message derived from the diff. Triggers: "commit", "git commit", "stage changes".
disable-model-invocation: true
allowed-tools: Bash(git *)
argument-hint: "[message]"
---
```

---

## 3. Naming convention

**Reference skills:** `laravel-<topic>` (e.g., `laravel-database`, `laravel-security`, `laravel-auth`). The `laravel-` prefix signals inline knowledge.

**Scaffolder skills** take one of two forms depending on their origin (as enumerated in §7.3 of the rebuild design spec, `docs/superpowers/specs/2026-06-23-laravel-agent-rebuild-design.md`):
- Topics that map directly to a retained agent use the agent's name: `laravel-<topic>` (e.g., `laravel-feature`, `laravel-api`, `laravel-review`).
- Topics derived from a legacy command or with a clear verb scope use `<topic>-<verb>` kebab-case (e.g., `test-make`, `security-audit`, `scaffold-app`, `plugin-scaffold`).

**Utility skills:** `<topic>-<verb>` kebab-case (e.g., `api-make`, `git-commit`, `db-diagram`).

In both cases, **no colons** are permitted in a skill name. The colon character is reserved by the Claude Code platform for plugin namespacing (`plugin:skill`); colons inside a skill directory name break invocation.

**Retained agents:** `laravel-<topic>` with no `-builder` suffix (e.g., `laravel-feature`, `laravel-api`, `laravel-testing`). The `-builder` suffix is legacy and is removed during conversion.

**User-facing invocation:** Claude Code namespaces plugin skills automatically. A skill in directory `skills/git-commit/` is invoked as `/laravel-agent:git-commit`. A skill in directory `skills/laravel-feature/` is invoked as `/laravel-agent:laravel-feature`.

The single-word legacy commands (`build`, `patterns`, `refactor`) become reference skills prefixed with `laravel-`: `laravel-build`, `laravel-patterns`, `laravel-refactor`.

---

## 4. Progressive disclosure

`SKILL.md` must be at most approximately 150 lines. This keeps the inline context window cost low and the skill's intent immediately readable. Material that exceeds this budget must be moved:

- **Conceptual depth, API references, pattern libraries:** `references/*.md` within the skill's directory. Each file covers one theme (e.g., `references/n1-patterns.md`, `references/big-o.md`). Reference them from `SKILL.md` by path or via dynamic injection (§5).
- **Runnable helpers, check scripts, generators:** `scripts/` within the skill's directory. Reference them from `SKILL.md` using the `${CLAUDE_SKILL_DIR}` variable (§5).
- **Evals:** `evals/evals.json` within the skill's directory (§7).

The three-level layout for a mature skill:

```
skills/<skill-name>/
├── SKILL.md              # ≤ ~150 lines — the public face
├── references/
│   ├── topic-a.md        # deep material, injected on demand
│   └── topic-b.md
├── scripts/
│   └── helper.sh         # runnable helpers
└── evals/
    └── evals.json        # test prompts + expected behavior
```

---

## 5. Dynamic context injection

Dynamic context injection lets a skill pull live data (git status, diff output, schema) into the context at invocation time, without a separate tool call in the conversation. Use the `` !`<command>` `` syntax at the start of a line in `SKILL.md`:

```markdown
!`git diff HEAD`
```

At invocation, Claude Code executes the command in a shell and prepends the output to the skill's context. This is distinct from static `${CLAUDE_SKILL_DIR}`, which resolves to the absolute path of the skill's own directory at load time and is used to reference scripts and reference files:

```markdown
See: ${CLAUDE_SKILL_DIR}/references/n1-patterns.md
Run: bash ${CLAUDE_SKILL_DIR}/scripts/check-schema.sh
```

Combine both for a utility skill that shows the current state before acting:

```markdown
!`git diff HEAD`
!`cat ${CLAUDE_SKILL_DIR}/references/commit-conventions.md`
```

---

## 6. Retained-agent template

Every scaffolder skill points to a retained agent file in `agents/laravel-<topic>.md`. The agent is the heavy worker that runs inside the forked session. All retained agents follow this minimal skeleton:

````markdown
---
name: laravel-<topic>
description: >
  One-sentence description of what this agent builds or reviews.
  Invoked by the laravel-agent:<topic-skill> skill via context:fork.
tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Role

You are a senior Laravel engineer specialised in <topic>.
You receive a structured task prompt from the `laravel-<topic>` skill and
execute it end to end.

# Execution environment

- Working directory: the project root (same as the main session).
- All file reads and writes use paths relative to the project root.
- You do not ask clarifying questions unless the task prompt is structurally
  incomplete. If a field is missing, state the assumption and continue.
- When the task is complete, output a one-paragraph summary of what was
  created or changed so the parent session can confirm.

# Task prompt format

The skill delivers a prompt using this structure:

```
Name:    <resource or feature name>
Options: <key-value pairs from the argument-hint>
Spec:    <detailed requirements or context from the user>
```

Execute each item in the spec in order. Create files if they do not exist;
edit files if they do. Do not leave stubs or placeholder methods.

# Output

After completing all files, list each path created or modified, one per line,
prefixed with `[created]` or `[modified]`.
````

The frontmatter `tools` field (not `allowed-tools`) is the correct field for agent files. Skills use `allowed-tools`; agents use `tools`. Do not conflate them.

---

## 7. Evals

Each skill must contain an `evals/evals.json` file. Evals serve three purposes: they document expected behavior in machine-readable form, they enable A/B testing (with-skill vs. without-skill baseline), and they support description tuning via the official `skill-creator` plugin.

The `skill-creator` plugin (`skill-creator@claude-plugins-official`) reads `evals/evals.json`, runs the test prompts against the installed skill, compares outcomes to the baseline, and produces a tuning suggestion for the `description` field. Running `skill-creator` against a skill after conversion is the recommended way to verify that auto-trigger fires on the right phrases and does not false-positive on unrelated ones. It writes its results back to `evals/evals.json`, so the file doubles as a living benchmark record. Manual runs are the current standard; wiring `skill-creator` into CI is a tracked follow-up and is not required by this wave.

A minimal `evals/evals.json`:

```json
{
  "skill": "<skill-directory-name>",
  "cases": [
    {
      "prompt": "<user message that should trigger this skill>",
      "expect": "<one-sentence description of the correct outcome>"
    },
    {
      "prompt": "<user message that should NOT trigger this skill>",
      "expect": "skill does not activate; handled by a different skill or inline"
    }
  ]
}
```

Provide at least two positive-trigger evals and one negative-trigger eval per skill.

> **Note on schema compatibility:** The canonical `evals/evals.json` schema read and written by the official `skill-creator@claude-plugins-official` plugin should be confirmed and adopted when `skill-creator` is wired in (a tracked follow-up). The `cases`/`expect` shape used in this repo's pilot skills is an interim convention and may differ from what `skill-creator` expects.

---

## 8. Kind-detection reference card

This table summarises §1 in card form for authors converting a topic:

| Signal present in frontmatter | Kind assigned by `classifySkill` |
| :--- | :--- |
| `context: fork` (with or without other fields) | **scaffolder** |
| `disable-model-invocation: true` (and no `context: fork`) | **utility** |
| Neither of the above | **reference** |

When in doubt, consult `scripts/build-catalog.mjs` `classifySkill` — it is the authoritative runtime classifier. The doc and the code must agree; if they ever diverge, the code wins.
