---
name: laravel-deploy
description: Laravel deployment — Forge, Vapor, Docker, Bref (AWS Lambda), traditional servers, zero-downtime releases, environment/secrets, CI/CD pipelines, and Envoy task runner. Use when deploying, configuring hosting/servers, going to production, or wiring up CI/CD. Triggers: "deploy", "production", "hosting", "server", "Forge", "Vapor", "Docker", "AWS", "Bref", "Lambda", "CI/CD", "release", "go live", "rollback".
---

# Laravel Deploy Skill

Deploy Laravel applications to production across Forge, Vapor, Docker, Bref, or traditional servers.

## When to Use

- Setting up deployment
- Configuring production servers
- Docker containerization
- CI/CD pipeline setup
- Cloud deployment (AWS, GCP, DigitalOcean)
- Zero-downtime releases and rollback
- Environment/secrets management

## Quick Start

```bash
/laravel-agent:deploy:setup <platform>
```

## Conventions Checklist

### Environment
- [ ] `APP_ENV=production`, `APP_DEBUG=false`, valid `APP_URL`
- [ ] Strong `APP_KEY` set; secrets never committed to git
- [ ] `CACHE_DRIVER`, `SESSION_DRIVER`, `QUEUE_CONNECTION` set to redis (not local file)
- [ ] `LOG_LEVEL=error` (not debug) in production
- [ ] `.env` exists and is checked before deploy

### Optimization (run before/after deploy)
- [ ] `composer install --no-dev --optimize-autoloader`
- [ ] `php artisan config:cache`
- [ ] `php artisan route:cache`
- [ ] `php artisan view:cache`
- [ ] `php artisan event:cache`

### Database & Queues
- [ ] Run `php artisan migrate --force` in the deploy script
- [ ] Test migrations on staging first
- [ ] `php artisan queue:restart` after deploy (workers cache old code)
- [ ] Restart Horizon (`horizon:terminate`) / Octane (`octane:reload`) if present

### Zero-Downtime
- [ ] Symlink-based releases (`current` → `releases/<ts>`)
- [ ] Shared `.env` and `storage` linked across releases
- [ ] Keep last 5 releases for instant rollback
- [ ] Health check endpoint (`/health`) returning 200/503

### CI/CD
- [ ] Run tests in CI before deploy (`php artisan test`)
- [ ] Deploy step gated on the main branch
- [ ] Secrets via CI secret store, never in the repo

## Common Pitfalls

1. **Forgetting migrations** — always include `php artisan migrate --force` in the deploy script
2. **Not caching in production** — run ALL cache commands (`config`, `route`, `view`, `event`)
3. **Missing queue restart** — workers cache old code; run `php artisan queue:restart`
4. **Incorrect file permissions** — `chmod -R 775 storage bootstrap/cache`, owned by the web user
5. **Missing environment variables** — verify `.env` exists with required values before deploy
6. **Not testing locally first** — run `php artisan config:cache` + tests locally, then `config:clear`
7. **No rollback strategy** — keep previous releases; use symlinks for instant rollback

## Best Practices

- Always backup before deploying
- Use zero-downtime deployments
- Monitor after each deploy (Pulse, Sentry, New Relic)
- Use environment-specific configs
- Set up health check endpoints and alerting for failures

## Monitoring

- **Laravel Pulse** — Application monitoring
- **Sentry** — Error tracking
- **New Relic** — APM
- **Laravel Telescope** — Debug (dev only)

## Related Commands

- `/laravel-agent:deploy:setup` — Configure deployment
- `/laravel-agent:cicd:setup` — Setup CI/CD pipeline

## Related Agents

- `laravel-deploy` — Deployment specialist
- `cicd-setup` — CI/CD pipeline specialist skill

## Additional references

- Forge deploy script, env vars, supervisor; Vapor config + commands → [references/forge-and-vapor.md](references/forge-and-vapor.md)
- Multi-stage Dockerfile, Nginx, Supervisor, OPcache, docker-compose, Bref (Lambda) → [references/docker.md](references/docker.md)
- Env templates, traditional server deploy, zero-downtime script, rollback, health checks, CI/CD, Envoy → [references/zero-downtime-and-env.md](references/zero-downtime-and-env.md)
