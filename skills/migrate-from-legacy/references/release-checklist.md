# Release Checklist

## Pre-Release (24 hours before)

- [ ] All tests passing: `php artisan test`
- [ ] Code review completed
- [ ] Security audit passed
- [ ] Database migrations tested on staging
- [ ] Performance benchmarks compared (before/after)
- [ ] Documentation updated
- [ ] Changelog entries added
- [ ] Release notes drafted

## Deployment Preparation

- [ ] Create release branch: `git checkout -b release/v1.2.0`
- [ ] Database backup created
- [ ] Rollback procedure documented
- [ ] Monitoring alerts configured
- [ ] Team notified of maintenance window
- [ ] Load balancer health checks verified

## During Deployment

### Step 1: Pre-deployment checks
```bash
composer validate
php artisan migrate:status
php artisan test --no-coverage
```

### Step 2: Deploy application
```bash
git pull origin main
composer install --no-dev
php artisan optimize:clear
```

### Step 3: Migrate database
```bash
php artisan migrate --force
php artisan db:seed  # if needed
```

### Step 4: Warm caches
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Step 5: Restart services
```bash
php artisan queue:restart
php artisan horizon:terminate  # if using Horizon
supervisorctl restart laravel:*
```

## Post-Deployment Validation

- [ ] Application loading (`/health` endpoint)
- [ ] Authentication working
- [ ] Database queries responsive
- [ ] Queue jobs processing
- [ ] Scheduled tasks running
- [ ] Error logs clean
- [ ] Performance metrics normal
- [ ] User-critical features tested

## Monitoring (first 24 hours)

```bash
# Watch error logs
tail -f storage/logs/laravel.log

# Monitor queue
php artisan queue:monitor

# Check system resources
php artisan horizon  # if using Horizon

# Database connections
mysql> SHOW PROCESSLIST;
```

## Issues During Deployment

### Immediate Rollback

```bash
# Option 1: Quick git rollback
git revert HEAD
git push origin main

# Option 2: Database rollback
php artisan migrate:rollback --step=1

# Option 3: Full system restore
# Contact DevOps to restore from backup
```

### Document Issue

```markdown
## Incident Report: [Date]

**What happened:** 
**When discovered:** 
**Root cause:** 
**Resolution:** 
**Prevention:** 
```

## Post-Deployment Review

- [ ] All metrics green
- [ ] No spike in error rates
- [ ] Performance stable
- [ ] User feedback positive
- [ ] Team debriefing scheduled
- [ ] Lessons learned documented

## Success Criteria

✅ All tests pass
✅ No new errors in logs
✅ Performance metrics unchanged
✅ All features working
✅ Users report normal experience
