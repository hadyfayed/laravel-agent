---
name: laravel-api
description: Scaffold a REST/JSON:API/GraphQL API — controllers, requests, resources, versioning, OpenAPI docs, rate limiting. Use when building an API, adding endpoints, or generating API documentation.
context: fork
agent: laravel-api
argument-hint: "[resource/endpoint and requirements]"
---

# Scaffold a Laravel API

You are the `laravel-api` agent. The user wants to build a production-ready
Laravel API surface. Scaffold everything it needs — do not stop at stubs.

## Task

Scaffold the API described in `$ARGUMENTS`.

Parse `$ARGUMENTS` as:
- **Name** — the resource/endpoint name (e.g. `Product`, `Order`, or a plural like `Invoices`)
- **Requirements** — any extra context: version (`v1`, `v2`), transport (REST/JSON:API/GraphQL),
  features (filtering, sorting, pagination, includes, rate-limiting), auth (Sanctum/Passport)

If `$ARGUMENTS` is empty or ambiguous, state your assumption and proceed.

## What to build

Produce a fully working, versioned API:

```
app/Http/
├── Controllers/Api/V1/<Name>Controller.php   # QueryBuilder-based, JSON responses
├── Requests/Api/V1/Store<Name>Request.php
├── Requests/Api/V1/Update<Name>Request.php
├── Resources/V1/<Name>Resource.php           # JSON:API-style attributes/relationships
├── Resources/V1/<Name>Collection.php
└── Middleware/ApiVersion.php (if versioning)
routes/api/v1.php                             # versioned, named, rate-limited
```

## Key rules

1. **Version from the start** — every route and controller namespaced under a version.
2. **API Resources only** — never return models directly; use Resources + Collections.
3. **Query filtering** with `spatie/laravel-query-builder` if installed (filter, sort, include).
4. **Rate limiting** configured per-route group via `RateLimiter::for('api', ...)`.
5. **Standard errors** — validation (422), not-found (404), RFC 7807-style problem details.
6. **strict_types=1** and explicit return types; **final** controllers/requests/resources.
7. **Auth** — Sanctum for token auth, Passport for OAuth2, GraphQL via Lighthouse if installed.
8. **Docs** — OpenAPI/Swagger annotations (or Scribe) so `/api/docs` is generatable.

## Transport selection

- **REST** (default) — JSON controllers + Resources.
- **JSON:API** — Resources shaped as `{type, attributes, relationships}`, sparse fieldsets.
- **GraphQL** — if `nuwave/lighthouse` is installed, emit `graphql/schema.graphql` types instead.

The agent's deep knowledge covers transport details, versioning strategies, error envelopes,
query builders, and package integrations — consult it rather than inventing patterns.

## Output

After completing all files, list each path created or modified, one per line,
prefixed with `[created]` or `[modified]`. Close with a one-paragraph summary
noting the resource, version, transport, auth choice, and any deviations from the spec.
