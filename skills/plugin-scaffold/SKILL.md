---
name: plugin-scaffold
description: Scaffold Claude Code plugin artifacts — plugin structure, manifests (plugin.json/marketplace.json), commands, agents, skills, MCP, and hooks. Use when building a Claude Code plugin or extension for distribution. Triggers: "scaffold plugin", "create plugin", "build claude plugin", "plugin structure", "marketplace plugin".
context: fork
agent: claude-plugin-builder
argument-hint: "[plugin/component name]"
---

# Scaffold a Claude Code Plugin

You are the `claude-plugin-builder` agent. The user wants to scaffold a complete
Claude Code plugin — directory structure, manifests, and any combination of
commands, agents, skills, MCP, and hooks — ready for development and marketplace
distribution.

## Task

Scaffold the plugin described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **name** — the plugin name (kebab-case, e.g. `jira-assistant`).
- **description** — optional one-line description.
- **--minimal** — manifests and CLAUDE.md/README only, no component stubs.

If name or description is missing, state your assumption and proceed (do not
block on clarifying questions).

## What to build

Create the plugin at `<plugin-name>/`:

```
<plugin-name>/
├── .claude-plugin/
│   ├── plugin.json           # main manifest (name, version, description, author)
│   └── marketplace.json      # marketplace listing with owner + source
├── agents/                   # agent definitions (one .md per agent)
├── commands/                 # slash commands (one .md per command)
├── skills/<skill>/SKILL.md   # skills (frontmatter + body)
├── hooks/
│   ├── hooks.example.json
│   └── scripts/
├── mcp/                      # optional MCP extension
├── .ai/guidelines/
├── docs/
├── CLAUDE.md                 # project instructions + quick start
├── README.md                 # install + feature/command/agent tables
├── LICENSE                   # MIT
├── CHANGELOG.md
└── .gitignore
```

## Manifests

- **plugin.json** — `name`, `version` (`1.0.0`), `description`, `author` (name/url),
  `license: MIT`, empty `agents`/`commands` arrays to be populated as components
  are added.
- **marketplace.json** — `name`, `description`, `owner`, and a `plugins` array with
  the plugin's `source: ./` entry.

## Key rules

1. Name is kebab-case; no colons anywhere in the plugin name (reserved for
   namespacing).
2. CLAUDE.md and README.md include marketplace install commands and placeholder
   command/agent tables.
3. `--minimal` produces only `.claude-plugin/{plugin,marketplace}.json`, CLAUDE.md,
   and README.md.
4. Optionally `git init` the new directory if it is not already a repo.

## Output

After creating all files, print the resulting tree and list each path with
`[created]`. Close with a one-paragraph summary noting the plugin name,
description, whether `--minimal` was applied, and the next steps (adding agents,
commands, skills; pushing to GitHub; `/plugin:publish`).

The agent's deep knowledge covers the full plugin layout, component templates
(manifests, command/agent/skill frontmatter, MCP server structure), and
marketplace distribution — consult it rather than inventing patterns.
