# v3 optimization plan (research-backed: Anthropic Agent Skills + coordination sources)

Goal: improve performance / fewer per-fork lines while keeping identical output. Researched via GLM+Exa against the Anthropic Agent Skills engineering post, the official skill best-practices docs, and multi-agent token-budgeting/coordination write-ups.

## Core principle (counterintuitive — do NOT violate)
Progressive disclosure is the design: metadata at startup → SKILL.md on trigger → references on demand. Our **99 reference files / 27k lines are correct** — they load only when needed. **Merging references to "reduce files" would HURT token efficiency.** References and the 85-line-avg SKILL.md layer are OFF-LIMITS for line reduction.

## The real fat (what to optimize)
- **A1 — agents (7,588 lines).** Forked agents reload their FULL prompt every invocation. Move procedural depth into the forking skill's `references/` (resolved via `${CLAUDE_SKILL_DIR}` from the thin SKILL.md task), leave the agent prompt as role + execution framing + explicit "read references/X for Y" pointers. Target ≤~150 lines/agent. Biggest per-fork token win (~−5,000 prompt lines).
- **A2 — hooks (1,280 lines / 9 scripts).** Duplicated Laravel-bootstrap/staged-file/exit logic → extract `hooks/scripts/_lib.sh`. ~−400 lines.
- **B1 — TOCs on the 5 references >600 lines** (passport 1330, batches-chains-events, core-auth, memory-safety-and-config, webhooks-and-invoices). Improves partial-read hit-rate. +~150 load-on-demand lines.
- **B2 — description audit (66 skills).** Zero line cost; tighten what/when/keywords + negative triggers for collision pairs (auth/sanctum/passport/socialite). Improves routing across a 66-skill menu.

## Held
- **C1 — consolidate 66 eval files:** CONFLICTS with the official skill-creator convention (`<skill>/evals/evals.json` per skill). Zero runtime cost as-is. Recommend KEEP per-skill. Pending user override.

## Off-limits (would hurt)
- Merging reference files; inflating SKILL.md; "one agent per task" (the coordination article's anti-pattern — keep 11 consolidated).

Sources: Anthropic "Equipping agents… with Agent Skills"; Claude skill best-practices docs; Ibrahim "context amnesia/coordination"; claudecodeguides token-budgeting & progressive-disclosure.

---

## OUTCOME (2026-06-24)

- **A1 (agents) ✅ DONE** — all 11 agents slimmed: **7,588 → 1,822 lines (−76%)**; deep content relocated to skill `references/` (load-on-demand) or deduped to pointers (`laravel-feature` billing 1118→60, points to `laravel-cashier`). Per-fork prompt cost cut ~76% for scaffolders. Total repo −1,653 lines net.
- **A1 behavioral test ✅ PASS** — simulated the `laravel-feature` fork: agent read `references/templates.md` on demand and produced a complete 18-file feature with zero gaps vs templates. No degradation.
- **B1 (TOCs) ✅** / **B2 (descriptions) ✅** — 5 TOCs; 20 collision-prone descriptions sharpened.
- **A2 (hooks shared lib) ↩️ REVERTED** — empirically added lines; hooks lack compressible duplication.
- **C1 (consolidate evals) — SKIPPED** — keep per-skill `<skill>/evals/evals.json` (official skill-creator convention; zero runtime cost).
- Integrity: 11 scaffolders linked, `--check` 0, tests 11/11.
