# Customizing laravel-agent

laravel-agent (v3.0.0+) is plain Markdown skills + a few agents. You can adapt it to your team's conventions without touching code.

## Where things live

| Path | What it is |
| :-- | :-- |
| `skills/<name>/SKILL.md` | A skill (reference / scaffolder / utility) |
| `skills/<name>/references/*.md` | Deep material loaded on demand |
| `skills/<name>/evals/evals.json` | Trigger/behavior test cases |
| `agents/<name>.md` | One of the 11 retained forked workers |
| `CATALOG.md` | Generated index — do not edit by hand |
| `docs/architecture/skill-standard.md` | The contract every skill follows |

## Common customizations

### Tune what a skill does
Edit the skill's `SKILL.md` body (or its `references/`). For a **reference** skill you're editing the conventions Claude applies inline; for a **scaffolder** you're editing the task prompt its agent runs; for a **utility** you're editing the one-shot steps. Keep `SKILL.md` ≤ ~150 lines and push detail into `references/`.

### Adjust when a skill triggers
The `description` (and optional `when_to_use`) drives auto-triggering. Add the keywords your team actually says. Make a skill manual-only with `disable-model-invocation: true`, or hide it from the menu with `user-invocable: false`.

### Pre-approve tools
Add `allowed-tools:` (e.g. `Bash(php artisan *) Read Write Edit`) so a skill's steps run without per-use prompts. Scope tightly (`Bash(git add *)`, not `Bash(*)`).

### Point a scaffolder at a different worker
A scaffolder skill's `agent:` field names the agent it forks. Change it to your own `agents/<name>.md` to swap in custom build behavior.

### Project-level overrides
You don't have to fork this repo. Drop a same-named skill in your project's `.claude/skills/` — it overrides the plugin's. Great for project-specific conventions (e.g. your own `laravel-database` rules).

## After any change

```bash
node scripts/build-catalog.mjs --write && node scripts/build-catalog.mjs --check
```

If you add/remove a skill or agent, the catalog and counts regenerate. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full workflow and the [skill standard](docs/architecture/skill-standard.md) for the rules.
