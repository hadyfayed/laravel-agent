# v3 rebuild — cleanup & deferred work (durable tracker)

**Status:** living document, updated as waves complete. This is the COMMITTED counterpart to the session ledger (`.superpowers/sdd/progress.md`, which is gitignored scratch). Nothing here is lost if the session ends.

**Cleanup strategy:** *fold-then-delete*. Conversions move agent/command content into skills first and leave the originals on disk; deletion happens in a dedicated cleanup pass once content is verified present. This avoids losing content mid-migration.

---

## A. Redundant agents to DELETE (19) — after verifying content is folded

The 11 RETAINED agents (fork targets for scaffolder skills) must stay: `claude-plugin-builder, laravel-api, laravel-architect, laravel-feature, laravel-filament, laravel-livewire, laravel-module, laravel-review, laravel-security, laravel-testing` (+ `laravel-security` doubles as the audit worker).

Delete these once their content is confirmed in a skill's `references/`:

| Agent | Folded into | Folded? |
| :-- | :-- | :-- |
| laravel-ai | `skills/ai-make/references/` | ✅ |
| laravel-auth | `skills/laravel-auth/references/` | ✅ |
| laravel-cashier | `skills/laravel-cashier/references/` | ✅ |
| laravel-database | `skills/laravel-database/references/` | ✅ |
| laravel-deploy | `skills/laravel-deploy/references/` | ✅ |
| laravel-inertia | `skills/laravel-inertia/references/` | ✅ |
| laravel-nova | `skills/laravel-nova/references/` | ✅ |
| laravel-octane | `skills/laravel-octane/references/` | ✅ |
| laravel-passport | `skills/laravel-auth/references/passport.md` | ✅ |
| laravel-performance | `skills/laravel-performance/references/` | ✅ |
| laravel-queue | `skills/laravel-queue/references/` | ✅ |
| laravel-reverb | `skills/laravel-websocket/references/` | ✅ |
| laravel-scout | `skills/laravel-scout/references/` | ✅ |
| laravel-pennant | `skills/feature-flag-make/references/` | ✅ |
| laravel-cicd | `skills/cicd-setup/references/` | ⏳ pending (U3) |
| laravel-migration | `skills/migrate-from-legacy/` + `skills/upgrade-laravel/` | ⏳ pending (U6) |
| laravel-package | `skills/package-make/references/` | ⏳ pending (U6/U7) |
| laravel-refactor | `skills/laravel-refactor/references/` | ⏳ pending (U6) |
| **laravel-git** | **NOT folded yet — GAP** | ❗ git-commit/pr/release were written fresh; fold `agents/laravel-git.md` git-workflow knowledge into a `references/` of one git utility (or a `laravel-git` reference) before deleting |

**Cleanup-pass procedure (per agent):** confirm its substantive blocks exist in the target `references/` (grep distinctive markers), then `git rm agents/<name>.md`, repoint any remaining source references (architect matrix, relationships.yml), `build-catalog --write`, `--check` 0, commit.

---

## B. Legacy `commands/` (53) to DELETE at ship (breaking v3.0.0)

Every command is now shadowed by a same-named or successor skill. Deleting `commands/` changes user-facing invocation (`/x:y` → `/laravel-agent:<skill>`), so it is the BREAKING step — do only with explicit user go-ahead, paired with the CHANGELOG migration table.

- ~13 commands map to scaffolder skills (api:make, feature:make, filament:make, livewire:make, module:make, service:make, scaffold:app, security:audit, test:make, review:pr/staged/audit, plugin:scaffold).
- ~36 map to utility skills (see §C of the design spec / the utility wave).
- Removed during ship; until then they harmlessly shadow.

---

## C. Accumulated Minor findings (cosmetic / non-blocking)

- `skills/laravel-auth/references/passport.md` — heading `Password Grant (First-Party APPS)` stray all-caps `APPS` (was `Apps`).
- `agents/laravel-filament.md` description says "Filament 3/4" vs skill "v3/v4" (cosmetic).
- `skills/laravel-patterns/SKILL.md` — `app/Builders` ambiguous vs Eloquent query builders; clarify object-builder vs query-builder.
- `skills/laravel-deploy/references/` — near-duplicate blocks (zero-downtime script, GH Actions, health check) preserved verbatim; de-dup safe.
- `skills/laravel-performance/references/profiling-and-scaling.md` — "Pulse Setup" / Octane install repeated; de-dup safe.
- `skills/laravel-security/` — OWASP table rendered both in SKILL.md (richer) and `references/owasp-top-10.md` (intentional progressive disclosure; leave).
- `agents/laravel-api-builder.md`→now `laravel-api.md`: heading `# INTEGRATION WITH FEATURE-BUILDER` stale prose (cosmetic).
- `skills/laravel-inertia/` — agent's `Create.vue` `<InputError>` form variant not folded (dup of Products form; still in retained… no, inertia agent is foldable → ensure folded before deleting laravel-inertia agent).

---

## D. Docs-site wave (separate pass)

The catalog generator owns the prose count lines in README/marketplace/_config/CATALOG and `docs/index.html`/`docs/commands.html` descriptions. STILL STALE / not generator-owned:
- `docs/index.html` hero **stat cards** (lines ~19/23/27): bare numbers `23`/`42`/`12` in separate `<div>`s.
- `docs/commands.html` filter button `All (47)`.
- `docs/agents/*.html`, `docs/commands/*.html`, `docs/skills/*.html` — per-item generated pages still reflect the OLD taxonomy (old agent names incl. `*-builder`, old command list). The whole Jekyll site needs regeneration/restructure against the new `skills/`+`agents/` reality.
Fix approach: drive the stat cards + listings from the generated `CATALOG.md`/a data file, or rebuild the site from disk; then bring under `build-catalog --check`.

---

## E. Other deferred items

- **Eval schema**: pilots/waves use interim `{skill, cases:[{prompt,expect}]}`. Confirm + adopt the official `skill-creator@claude-plugins-official` schema when wiring skill-creator; then optionally add negative-trigger cases (standard doc points to this).
- `docs/_data/relationships.yml` — `module-make` entry has `skills: [laravel-feature]`; should be `[laravel-module]`.
- `scripts/build-catalog.mjs` — `parseFrontmatter` doesn't handle YAML chomping indicators (`>-`,`|-`,`>+`); no skill uses them currently.
- `scripts/build-catalog.mjs` — `applyCounts` silently no-ops if README marker block is removed (false-green for README in `--check`); add a defensive assert.
- **MCP server** (`mcp/`) — still "proposal stage" skeleton; out of v3 scope (separate project). Don't advertise as functional.
- **Hooks** — functional but opt-in (`hooks/hooks.example.json`); decide if a real `hooks/hooks.json` ships or stays opt-in.
- **templates/** — doc-only stubs; real scaffolds are a separate effort.

---

## F. Ship checklist — v3.0.0 (gated on explicit user go-ahead)

1. Finish all utility conversions + the agent-cleanup pass (§A) + docs-site wave (§D).
2. Delete `commands/` (§B).
3. Write the CHANGELOG migration table: every old `/x:y` → new `/laravel-agent:<skill>`.
4. Final whole-branch review (opus or careful pass).
5. Bump `plugin.json` `3.0.0-dev` → `3.0.0`; regenerate catalog; `--check` 0; tests green.
6. Commit, merge `rebuild/skill-standard-v3` → `main`, tag `v3.0.0`, push. (push/tag = outward action, confirm.)
