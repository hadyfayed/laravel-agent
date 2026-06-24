---
name: laravel-inertia
description: Build server-driven single-page apps with Laravel + Inertia.js (Vue 3 or React) — controllers, shared props, useForm, partial reloads, file uploads, SSR. Use when the user mentions Inertia, a Vue/React SPA without an API, server-side routing with client-side rendering, Ziggy, or Breeze inertia.
---

# Laravel Inertia Skill

Build modern single-page applications with Laravel and Inertia.js without building an API. Server-side routing and controllers stay; the client renders Vue 3 or React.

## When to Use

- Building SPAs with server-side routing
- Need Vue 3 or React with a Laravel backend
- Want an SPA experience without API complexity
- Building admin panels or dashboards
- User requests "Inertia", "Vue SPA", or "React SPA"

## Quick Start

```bash
# New project via Breeze
composer require laravel/breeze --dev
php artisan breeze:install vue      # or: react
npm install && npm run dev
```

## Conventions Checklist

### Controllers
- [ ] Render via `Inertia::render('Component', [...props])`
- [ ] Transform models into arrays/DTOs — never pass raw Eloquent to props
- [ ] Eager-load relations (`->with('category')`) to avoid N+1 in props
- [ ] Return redirects with `->with('success', ...)` for mutations

### Shared Data (HandleInertiaRequests)
- [ ] Share `auth.user`, `flash.*`, and `errors` via `share()`
- [ ] Wrap session reads in `fn () => ...` for deferred evaluation
- [ ] Share Ziggy via the middleware or `ZiggyVue` plugin

### Forms
- [ ] Use `useForm({...})` — not a hand-rolled `fetch`
- [ ] `preserveScroll: true` on create/update/delete
- [ ] `form.reset()` on success; display `form.errors` per field
- [ ] `forceFormData: true` for any file upload

### Navigation & Reloads
- [ ] Use `<Link>` or `router.*` — never raw `<a href>`
- [ ] Partial reloads with `only: [...]` for filters/pagination
- [ ] `Inertia::lazy(fn () => ...)` for heavy, on-demand props

## Common Pitfalls

1. **Raw models in props** — exposes sensitive fields; transform to arrays
2. **N+1 in props** — eager-load relations before `through`/`map`
3. **Missing `forceFormData`** — file uploads silently fail
4. **No `preserveScroll`** — user loses position after updates
5. **No `preserveState`** — form input lost on validation errors
6. **Heavy initial props** — use `Inertia::lazy(...)` for deferred data
7. **API routes for Inertia** — use web routes; Inertia is not a JSON API

## Best Practices

- Transform data in controllers; share only necessary user data
- Use partial reloads and lazy props for performance
- Implement loading states (`form.processing`, `form.progress`)
- Add SSR only for SEO-critical pages
- Test with `->assertInertia(fn (Assert $page) => ...)`

## Package Integration

- **tightenco/ziggy** — `route()` helper in JS
- **spatie/laravel-query-builder** — filters/sorts for index props
- **spatie/laravel-medialibrary** — media URLs in transformed props

## Related Commands

- `/laravel-agent:inertia:make` — create Inertia page components
- `/laravel-agent:inertia:install` — set up Inertia with Vue or React
- `/laravel-agent:breeze:install` — install Laravel Breeze with Inertia

## Related Skills

- `laravel-livewire` — alternative reactive framework
- `laravel-feature` — feature structure patterns
- `laravel-testing` — testing strategies

## Additional references

- Install / middleware / root template / Vite → [references/setup.md](references/setup.md)
- Controllers, shared props, partial reloads, lazy props, scroll → [references/pages-and-props.md](references/pages-and-props.md)
- `useForm`, validation errors, file uploads → [references/forms-and-validation.md](references/forms-and-validation.md)
- Vue & React page components, layouts, SEO/head, Ziggy → [references/vue-and-react.md](references/vue-and-react.md)
- SSR, Inertia test assertions, pitfalls, best practices, guardrails → [references/ssr-and-advanced.md](references/ssr-and-advanced.md)
