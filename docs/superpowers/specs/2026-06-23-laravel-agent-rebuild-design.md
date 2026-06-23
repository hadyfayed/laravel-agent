# laravel-agent rebuild to the modern skill standard

**Date:** 2026-06-23
**Status:** Approved design — pending spec review, then implementation plan
**Owner:** hadyfayed

---

## 1. Problem

`laravel-agent` is a published Claude Code plugin (installed from `github.com/hadyfayed/laravel-agent`; local `main` == `origin/main` == distributed copy at commit `e06d45f`). A full audit (agents, commands, skills, hooks, MCP, docs, templates, manifests, remote) found that the **content is mostly good** but the **plugin is structurally incoherent and fragile**:

### Confirmed defects (real)
1. **Phantom agent.** `laravel-validator` is referenced in `plugin.json` and as a *dispatch target* inside `agents/laravel-architect.md` (lines 826/858/859/913) and by `laravel-review`, but the file does not exist → instructing Claude to dispatch a non-existent subagent.
2. **Six contradictory self-reported counts**, none matching disk (disk = 30 agents, 53 commands, 21 skills, 9 hooks):
   - `README.md` line 9: 29 / 47 / 21
   - `README.md` lines 16–19: 23 / 42 / 13
   - `docs/_config.yml`: 23 / 42 / 12
   - `marketplace.json` + `CHANGELOG`: 23 / 38 / —
   - `plugin.json` arrays: 22 / 38 / 0
3. **`skills/SKILLS.md` is fiction** — documents a 14-skill *tiered (meta.md / Tier 1/2/3)* architecture with wrong (unprefixed) names that does not exist on disk (21 `laravel-*` skills, each a lone `SKILL.md`).
4. **Vestigial drift surface.** `plugin.json`'s `agents`/`commands` arrays do nothing (Claude Code auto-discovers from directories — verified: this session exposes all 53 commands / 21 skills / 30 agents despite the manifest listing 22/38/0) yet carry the phantom and drift.
5. **`mcp/composer.json`** autoloads a `tests/` dir that does not exist (composer warning).
6. **Three-way triplication.** ~20 Laravel topics each implemented as an agent **and** a skill **and** a command, with no written separation-of-concerns.

### Not defects (verified, do not "fix")
- Auto-discovery works; "unregistered = invisible" is false.
- Agent/command/skill **content quality is high** (accurate packages, real APIs, no hallucinations).
- MCP server is honestly self-labeled "proposal stage."
- Hooks are functional and opt-in by design.
- Git hygiene is fine (`docs/_site`, `.jekyll-cache` ignored).

### Root cause
No single source of truth and no written standard. Things were added to disk without updating any manifest or doc, so counts drift and three taxonomies duplicate each other. The platform itself has since **merged custom commands into skills** (`commands/x.md` and `skills/x/SKILL.md` both create `/x`; skills are the recommended form), so the command/skill split is now pure legacy.

---

## 2. Goals / Non-goals

### Goals
- Collapse the three taxonomies into **one** (`skills/`), per the current Claude Code standard.
- Classify every topic under a **written contract** (reference / scaffolder / utility).
- Make all counts/catalog **generated from disk** and **CI-enforced** so drift becomes structurally impossible.
- Adopt modern skill mechanics: progressive disclosure (`SKILL.md` slim + `references/`/`scripts/`), invocation control (`disable-model-invocation` / `user-invocable`), forked execution (`context: fork` + `agent:`), dynamic context injection (`` !`cmd` ``), and `skill-creator`-compatible `evals/`.
- Fix the real defects (phantom agent, counts, SKILLS.md, mcp autoload).
- Roll out safely via **pilot then waves** (plugin is published).

### Non-goals (this effort — flagged as follow-ups, not dropped)
- Rewriting the MCP server (separate project; here we only stop misrepresenting its status).
- Making hooks active-by-default (stays opt-in; documented).
- Building real `templates/` scaffolds (currently doc-only; later).

---

## 3. Architecture — the three-kind skill contract

Every topic becomes **exactly one** kind:

| Kind | Frontmatter signature | Retains an agent? | Body |
| :--- | :--- | :--- | :--- |
| **Reference** | auto-trigger (no invocation lock); inline | No | Slim `SKILL.md` (≤~150 lines) + `references/*.md` for depth |
| **Scaffolder** | `context: fork` + `agent: laravel-<topic>`; may auto-trigger | **Yes** (retained heavy worker) | `SKILL.md` is the *task prompt* the forked agent runs |
| **Utility** | `disable-model-invocation: true`; `allowed-tools`; `` !`cmd` `` injection | No | `SKILL.md` task steps |

**Reviewer** topics (`review:*`, `security:audit`) are scaffolders whose retained agent is read-heavy (`agent: laravel-review` / `laravel-security`).

### Effect on `agents/`
30 → ~8–10 **retained forked workers**: `laravel-feature`, `laravel-module`, `laravel-service`, `laravel-api`, `laravel-filament`, `laravel-livewire`, `laravel-review`, `laravel-security`, `claude-plugin-builder` (+ `laravel-architect` as the scaffold-app orchestrator). Arbitrary `-builder` suffixes dropped. The remaining ~20 agents' content folds into their skill's `references/`.

### Effect on `commands/`
**Deleted.** Each becomes a skill. A skill shadows a same-named legacy command cleanly (docs: "if a skill and a command share the same name, the skill takes precedence"), so migration is non-conflicting; old command files are removed during the waves.

---

## 4. Naming convention

- **Reference skills:** `laravel-<topic>` (e.g. `laravel-security`).
- **Scaffolder / utility skills:** `<topic>-<verb>` kebab-case, **no colons** (`api:make` → `api-make`, invoked `/laravel-agent:api-make`). Colons are reserved by the platform for plugin namespacing.
- **Retained agents:** `laravel-<topic>` (no `-builder`).
- The single-word commands that broke `noun:verb` (`build`, `patterns`, `refactor`) become `laravel-build` / `laravel-patterns` (reference) / `laravel-refactor`.

> ⚠️ Renaming user-facing commands is **breaking** → ship as **v3.0.0** with a CHANGELOG migration table. **Decision: accept the break** (no back-compat shims).

---

## 5. Single source of truth (the actual cure)

1. **Trim `plugin.json`** to `name / version / description / author / license / keywords`. Delete the `agents` and `commands` arrays (vestigial; carry the phantom). No `skills`/`hooks`/`mcpServers` keys (auto-discovery + separate files handle those).
2. **`scripts/build-catalog.mjs`** — scans `skills/` and `agents/`, derives kind from frontmatter, and (re)writes:
   - the count line(s) in `README.md`, `marketplace.json` description, `docs/_config.yml`;
   - a generated `CATALOG.md` (replaces the fictional `SKILLS.md`).
   - Supports `--check` (exit non-zero on any drift) and `--write`.
3. **CI guard** — a GitHub Action (repo already has `.github/workflows/`) runs `build-catalog --check` and fails on drift. **Decision: include the CI guard.** This makes the single source of truth permanent.
4. **Delete `skills/SKILLS.md`** (fiction) → replaced by generated `CATALOG.md`.

---

## 6. Progressive disclosure + evals

- `SKILL.md` ≤ ~150 lines. Deep material → `references/*.md`; runnable helpers → `scripts/` (referenced from `SKILL.md` via `${CLAUDE_SKILL_DIR}`). The 1000–1400-line skills (`nova`, `inertia`, `cashier`, `octane`, `passport`, `scout`) are split during their wave.
- Adopt the official **`skill-creator`** eval structure: `evals/evals.json` per converted skill (test prompts + expected behavior), documented as the standard so skills are measurable / A-B-testable / description-tunable. This is the real, grounded version of the "Skills 2.0 self-improving" idea (Anthropic's `skill-creator@claude-plugins-official`), not the speculative auto-eval claims from the blog.

---

## 7. Draft full classification (drives the waves — adjustable)

> Pilot topics in **bold**. "Agent" column = retained forked worker.

### Reference (inline, auto-trigger, no agent)
| Skill | Source agent/skill folded in | Agent |
| :-- | :-- | :-- |
| **laravel-database** | laravel-database agent + skill | — |
| laravel-performance | laravel-performance agent + skill | — |
| laravel-patterns | `patterns` command | — |
| laravel-auth | laravel-auth agent + skill (+ sanctum/passport/socialite as references) | — |

> **`laravel-security` is dual-natured:** a *reference* skill `laravel-security` (auto-trigger OWASP patterns, no fork) **plus** a retained `laravel-security` *agent* used as the fork target by the reviewer skills (`security-audit`, `laravel-review`). It also absorbs the role the phantom `laravel-validator` was meant to play (false-positive filtering / confidence scoring).

### Scaffolder (`context: fork` → retained agent)
| Skill | Agent | Source |
| :-- | :-- | :-- |
| **laravel-feature** | laravel-feature | feature:make + laravel-feature-builder |
| laravel-module | laravel-module | module:make + laravel-module-builder |
| laravel-service | laravel-service | service:make + laravel-service-builder |
| laravel-api | laravel-api | api:make/api:docs + laravel-api-builder |
| laravel-filament | laravel-filament | filament:make + laravel-filament |
| laravel-livewire | laravel-livewire | livewire:make + laravel-livewire |
| laravel-review | laravel-review | review:pr/review:staged/review:audit |
| security-audit | laravel-security | security:audit (+ reference skill `laravel-security`) |
| scaffold-app | laravel-architect | scaffold:app + laravel-architect |
| plugin-scaffold | claude-plugin-builder | plugin:scaffold/publish, mcp:make, skill:make, agent:make, command:make |

### Utility (`disable-model-invocation`, no agent)
`git-commit` (**pilot**), git-pr, git-release, dto-make, job-make, notification-make, broadcast-make, webhook-make, import-make, pdf-make, geo-make, test-make, test-coverage, db-diagram, db-optimize, ai-make, feature-flag-make, bug-fix, refactor (laravel-refactor agent may be retained as a fork target), docs-generate, analyze-codebase, migrate-from-legacy, upgrade-laravel, build.

### Setup utilities (`disable-model-invocation`)
auth-setup, cicd-setup, deploy-setup, reverb-setup, pulse-setup, telescope-setup, search-setup, seo-setup, health-setup, backup-setup.

### Reference-via-setup topics whose agents fold to references
laravel-cashier, laravel-deploy, laravel-cicd, laravel-octane, laravel-queue, laravel-horizon, laravel-scout, laravel-nova, laravel-inertia, laravel-reverb/websocket, laravel-pennant, laravel-ai, laravel-migration, laravel-package, laravel-testing — each becomes a reference skill (slim + `references/`), with a setup utility skill where it has a clear one-shot install action.

> The exact kind for borderline topics (e.g. testing as reference vs utility) is finalized per wave; the pilot proves the pattern first.

---

## 8. Scope of THIS wave: foundation + 3 pilots

### Foundation
1. `docs/architecture/skill-standard.md` — the written contract (this section's tables, frontmatter-per-kind, naming, progressive-disclosure rules, when to fork, eval expectations).
2. `scripts/build-catalog.mjs` (+ `--check`) and the CI guard workflow.
3. `plugin.json` trim (remove arrays + phantom).
4. Fix phantom `laravel-validator` → repoint `laravel-architect.md` and `laravel-review` to `laravel-security`.
5. Delete `skills/SKILLS.md`; generate `CATALOG.md`.
6. Fix `mcp/composer.json` autoload (`tests/`).
7. Lean retained-agent template (frontmatter + focused execution-env system prompt).

### Pilots (one per kind, end-to-end, including `evals/`)
- **Reference — `laravel-database`:** slim `SKILL.md` (411 → ~150) + `references/` (Big-O / N+1 / upgrades / legacy-import depth). No agent.
- **Scaffolder — `laravel-feature`:** task `SKILL.md` with `context: fork`, `agent: laravel-feature`; retained, slimmed `laravel-feature` agent (from the 1405-line `laravel-feature-builder`).
- **Utility — `git-commit`:** from `git:commit`; `disable-model-invocation: true`, `allowed-tools: Bash(git *)`, `` !`git diff HEAD` `` dynamic injection. No agent.

### Review gate
User reviews the three proven patterns + foundation → waves convert the rest per §7, each wave: convert skills, fold agents, run `build-catalog --write`, update CHANGELOG.

---

## 9. Migration & versioning

- **v3.0.0** (breaking: command renames). CHANGELOG gets a migration table mapping every old `/x:y` → new `/laravel-agent:x-y`.
- During pilot, new skills shadow legacy commands (no conflict); legacy `commands/` files are deleted in the waves, not the pilot.
- Ship (commit + tag + push + marketplace re-pull) only after waves complete and the user approves — pushing is an outward action requiring explicit confirmation.

---

## 10. Success criteria

- One `skills/` taxonomy; `commands/` gone; `agents/` ≤ ~10 retained workers.
- `build-catalog --check` passes; every count in the repo matches disk; CI guard active.
- No phantom references anywhere (`grep -r laravel-validator` clean).
- Each pilot: `SKILL.md` ≤ ~150 lines, correct frontmatter for its kind, `evals/evals.json` present, behavior verified against a baseline.
- `plugin.json` minimal; `SKILLS.md` fiction gone.

---

## 11. Out of scope / follow-ups (tracked, not dropped)

- MCP server rewrite (relabel status only now).
- Hooks active-by-default (stays opt-in).
- Real `templates/` scaffolds.
- Wiring `skill-creator` runs into CI (manual for now).
