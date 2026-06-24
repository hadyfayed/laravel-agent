# Contributing to laravel-agent

Thanks for contributing! As of **v3.0.0**, laravel-agent is a single, coherent **skill** taxonomy backed by a generated catalog. Read this before opening a PR.

## Architecture in one minute

- **Skills** (`skills/<name>/SKILL.md`) are the primary unit. Every capability is a skill of exactly one **kind**:
  - **reference** — auto-trigger knowledge (conventions, patterns). No `context`/`disable-model-invocation`.
  - **scaffolder** — `context: fork` + `agent: laravel-<topic>`; the skill body is the task prompt a retained agent runs.
  - **utility** — `disable-model-invocation: true` + `allowed-tools`; a single manual one-shot action.
- **Agents** (`agents/*.md`) are the 11 retained forked workers that scaffolder skills target. We do **not** add a per-topic agent for every skill — most knowledge lives in reference skills.
- **The catalog** (`CATALOG.md`) and all counts are **generated** by `scripts/build-catalog.mjs`. Never hand-edit counts.

The full contract is in [`docs/architecture/skill-standard.md`](docs/architecture/skill-standard.md). Read it first.

## Adding or changing a skill

1. Decide the **kind** (reference / scaffolder / utility) using the rules in the skill standard.
2. Create `skills/<name>/SKILL.md` with the correct frontmatter for that kind. Keep the body ≤ ~150 lines; move depth into `references/*.md` (progressive disclosure).
3. Add `skills/<name>/evals/evals.json` with a couple of realistic trigger cases.
4. Regenerate and verify:
   ```bash
   node scripts/build-catalog.mjs --write   # updates CATALOG.md + counts
   node scripts/build-catalog.mjs --check   # must exit 0
   node --test scripts/build-catalog.test.mjs
   ```
5. Commit. CI (`.github/workflows/catalog-check.yml`) re-runs `--check` and fails on any count/catalog drift.

## Naming

- Reference skills: `laravel-<topic>` (e.g. `laravel-security`).
- Scaffolder skills: `laravel-<topic>` matching their agent.
- Utility skills: `<topic>-<verb>` kebab-case, **no colons** (e.g. `dto-make`, `auth-setup`). Invoked as `/laravel-agent:<skill>`.

## What not to do

- Don't add `commands/` — custom commands were merged into skills upstream; use a skill.
- Don't hand-edit `CATALOG.md` or the count strings in `README.md` / `marketplace.json` / `docs/_config.yml` — the generator owns them.
- Don't duplicate a retained agent's deep knowledge inside its scaffolder skill — defer to the agent.

## Commits & PRs

- Conventional commits (`feat:`, `fix:`, `refactor(skill):`, `docs:` …).
- Run the three verification commands above before pushing.
- Note any breaking change (renamed/removed skill) prominently; v3 invocation is `/laravel-agent:<skill>`.

See also [`CUSTOMIZATION.md`](CUSTOMIZATION.md) for adapting skills to your own project, and [`docs/superpowers/v3-cleanup-and-deferred.md`](docs/superpowers/v3-cleanup-and-deferred.md) for the current follow-up backlog.
