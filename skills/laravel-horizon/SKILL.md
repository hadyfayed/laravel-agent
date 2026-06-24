---
name: laravel-horizon
description: Laravel Horizon — Redis queue dashboard, supervisors and auto-scaling/balancing, multi-queue worker config, metrics, failed-job management, alerting (Slack/email/wait-time), job tags, and silencing. Use when configuring or monitoring queues with Horizon. Triggers: "horizon", "queue dashboard", "failed jobs", "queue metrics", "worker status", "queue monitoring", "redis queue", "job status".
---

# Laravel Horizon Skill

Monitor and manage Redis queues with Laravel Horizon.

## When to Use

- Setting up queue monitoring dashboard
- Configuring worker processes
- Managing failed jobs
- Monitoring queue metrics
- Balancing queue workers
- Configuring job tags and batches

## Quick Start

```bash
composer require laravel/horizon
php artisan horizon:install
php artisan migrate
# Access dashboard at /horizon
```

## Conventions Checklist

### Setup
- [ ] `QUEUE_CONNECTION=redis`, Redis host/port configured
- [ ] Publish config + assets (`php artisan horizon:install`)
- [ ] Dashboard gated via `HorizonServiceProvider` `viewHorizon` gate (never open)
- [ ] Run Horizon as a daemon via Supervisor (never in the foreground)

### Supervisors & Workers
- [ ] Define `defaults` supervisor in `config/horizon.php`
- [ ] Override per-environment (`production` vs `local`) `maxProcesses`
- [ ] Use `balance: auto` with `autoScalingStrategy: time|size` and `balanceMaxShift`/`balanceCooldown`
- [ ] Separate priority queues (`high`, `default`, `low`) with distinct supervisors
- [ ] Set `memory` (MB) and `tries`/`timeout` per supervisor

### Operations
- [ ] `php artisan horizon:terminate` on every deploy (Supervisor restarts it)
- [ ] Tag jobs (`tags()`) for dashboard filtering
- [ ] Silence noisy jobs (health checks) via `Silenced` contract or config `silenced`
- [ ] Trim recent/failed metrics (`trim` + `metrics.trim_snapshots`)

### Alerting
- [ ] `Horizon::routeSlackNotificationsTo` / `routeMailNotificationsTo`
- [ ] `Horizon::routeLongWaitTimeNotificationsTo` for wait-time alerts

## Common Pitfalls

1. **Not running Horizon as a daemon** — use Supervisor; `php artisan horizon` alone dies in the foreground
2. **Forgetting to terminate on deploy** — add `php artisan horizon:terminate` to the deploy script
3. **Wrong Redis configuration** — ensure `QUEUE_CONNECTION=redis` and Redis host/port are set
4. **Not setting memory limits** — set `memory` (MB) per supervisor
5. **Missing authorization** — Horizon is open to anyone without a `viewHorizon` gate
6. **Not monitoring wait times** — wire up long-wait notifications

## Best Practices

- Use Supervisor for process management
- Configure auto-scaling for production
- Set up Slack/email notifications
- Monitor queue wait times
- Tag jobs for filtering
- Terminate Horizon on deploy
- Set appropriate memory limits
- Use separate queues for priorities
- Silence frequent health-check jobs
- Review failed jobs regularly

## Related Commands

- `/laravel-agent:job:make` — Create queued jobs

## Related Skills

- `laravel-queue` — Queue and job implementation
- `laravel-deploy` — Production deployment

## Additional references

- Install, config, authorization, supervisors, multi-queue, auto-scaling, job tags → [references/supervisors-and-configuration.md](references/supervisors-and-configuration.md)
- Notifications, running Horizon, Supervisor config, deployment, metrics, failed jobs, silencing → [references/operations-and-monitoring.md](references/operations-and-monitoring.md)
