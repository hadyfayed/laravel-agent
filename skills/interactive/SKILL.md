---
name: interactive
description: Guided interactive mode — helps you pick the right laravel-agent skill for what you want to build. Use when unsure which skill or command to run, or when exploring what laravel-agent can do.
disable-model-invocation: true
argument-hint: "[optional: what you want to do]"
---

# Interactive mode — find the right skill

A guided session that asks what you want to do and recommends the exact `/laravel-agent:<skill>` to run. Ported from the original `/interactive` command and kept current against the live catalog.

## Available skills (live catalog)

!`cat "${CLAUDE_SKILL_DIR}/../../CATALOG.md" 2>/dev/null || cat CATALOG.md 2>/dev/null || echo "(catalog not found — list skills with /help)"`

## What this skill does

The user wants help choosing among laravel-agent's skills. Drive a short, friendly back-and-forth:

1. **Greet and orient.** If `$ARGUMENTS` already describes a goal, skip ahead and map it directly. Otherwise ask what they want to do, offering the top-level intents:
   - Build a coordinated unit (a feature/CRUD module, reusable module, service/action, API, admin panel, Livewire component) → **scaffolder** skills
   - Set something up (auth, deployment, CI/CD, search, backups, monitoring, websockets…) → **`*-setup` / `*-make` utility** skills
   - Generate one thing (a job, DTO, notification, PDF, import, migration test…) → **utility** skills
   - Understand or improve existing code (review, security audit, analyze, refactor, optimize) → **review/analysis** skills
   - Learn conventions (database, security, performance, auth, patterns) → **reference** skills (these also auto-trigger)

2. **Narrow with one or two follow-up questions** based on their answer, using the live catalog above to match.

3. **Recommend exactly one skill** by its precise invocation, e.g.:
   - "Build an invoicing feature" → `/laravel-agent:laravel-feature Invoicing with CRUD and PDF export`
   - "Add Stripe billing" → `/laravel-agent:cashier-setup` (and the `laravel-cashier` reference auto-loads)
   - "Review this PR" → `/laravel-agent:laravel-review 123`
   Briefly say what it will do.

4. **Offer to run it now.** If they agree, invoke that skill with their inputs.

## Rules

- Recommend the modern `/laravel-agent:<skill>` form only — there are no colon-style commands in v3.
- Prefer one clear recommendation over a list. If genuinely ambiguous, offer at most two.
- Reference skills auto-trigger, so for "learn X" intents, tell the user they can just ask their question and the relevant reference will load.
- Keep it conversational and short.
