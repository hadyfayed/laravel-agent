---
name: seo-setup
description: Set up SEO infrastructure — sitemaps, meta tags, Open Graph, structured data/schema, robots.txt. Triggers: "SEO", "sitemap", "meta tags", "schema", "Open Graph", "when adding SEO".
disable-model-invocation: true
allowed-tools: Bash(composer *) Bash(php artisan *) Read Write Edit
argument-hint: "[--sitemap] [--meta] [--opengraph] [--schema] [--all]"
---

## Task

Configure comprehensive SEO for your Laravel app. Optionally specify flags via `$ARGUMENTS`; if omitted, run interactively.

## Components

**SEO Infrastructure Setup** covers three main areas:

1. **Sitemap Generation** — Automatic XML sitemaps with model support
2. **Meta Tags & Open Graph** — Dynamic meta tags, Twitter Cards, social sharing
3. **Model-Based SEO** — Per-model SEO data with Filament integration

See `references/sitemap-setup.md`, `references/meta-tags-setup.md`, and `references/model-seo.md` for detailed implementation and code examples.

## Environment Variables

```env
SCOUT_DRIVER=meilisearch  # if using Scout for indexing
```

## Output

Report installed packages, files created/modified, database migrations, and next steps for robots.txt and Google Search Console submission.

## Commands

```bash
php artisan sitemap:generate
php artisan migrate
```

## Reference

Detailed SEO patterns, canonical tags, robots.txt rules, and schema.org markup: see the **laravel-seo** reference skill.
