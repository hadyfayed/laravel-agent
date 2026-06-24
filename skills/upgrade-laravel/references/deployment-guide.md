# Deployment Guide for Version Upgrades

## Pre-Deployment Steps

### 24 Hours Before

```bash
# Verify everything is ready
php artisan test --no-coverage
./vendor/bin/phpstan analyse --level=5
vendor/bin/pint --test
composer validate

# Create backups
git checkout -b pre-upgrade-backup
cp composer.lock composer.lock.backup
```

### Health Check

```bash
# Check current state
php artisan about

# List database migrations
php artisan migrate:status

# Verify queue is empty
php artisan queue:work --stop-when-empty
```

## Deployment Process

### 1. Pull Latest Code

```bash
git pull origin main
git status  # Should be clean
```

### 2. Update Dependencies

```bash
composer install --no-dev
composer dump-autoload -o
```

### 3. Run Migrations

```bash
# Dry run first (if available)
php artisan migrate --pretend

# Actually migrate
php artisan migrate --force
```

### 4. Clear & Warm Caches

```bash
php artisan optimize:clear

# Warm production caches
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### 5. Restart Services

```bash
# Queue workers
php artisan queue:restart

# Horizon (if using)
php artisan horizon:terminate

# Supervisor
supervisorctl restart laravel:*

# Or systemd
systemctl restart laravel
```

### 6. Verify Deployment

```bash
# Check application is running
curl https://app.com/health

# Watch logs
tail -f storage/logs/laravel.log

# Check queue processing
php artisan queue:monitor

# Verify database
php artisan migrate:status
```

## Rollback Plan

### Quick Rollback (if issues detected)

```bash
# Option 1: Git revert
git revert HEAD
git push origin main

# Option 2: Composer rollback
cp composer.lock.backup composer.lock
composer install

# Option 3: Database rollback
php artisan migrate:rollback --step=1
```

### Full System Restore

```bash
# Check backup available
ls -la backups/

# Restore database
php artisan backup:restore --source=local

# Restore application code
git reset --hard pre-upgrade-backup
composer install

# Clear caches
php artisan optimize:clear
```

## Monitoring (First 24 Hours)

### Key Metrics

- Error rate (logs)
- Response time (APM)
- Memory usage (system)
- Database connections
- Queue job count

### Commands to Monitor

```bash
# Watch logs in real-time
tail -f storage/logs/laravel.log | grep -i error

# Monitor queue
watch -n 1 'php artisan queue:monitor'

# Check database
mysql -u root -p -e "SHOW PROCESSLIST;"

# System resources
top  # or htop
```

### Alert Thresholds

- Error rate spike > 5x normal
- Response time > 2s
- Memory usage > 80%
- Database connections maxed out
- Queue jobs backing up

## Post-Deployment Review

### Checklist

- [ ] Application loading normally
- [ ] Authentication working
- [ ] Database queries responsive
- [ ] Queue jobs processing
- [ ] Scheduled tasks running
- [ ] Error logs clean
- [ ] Performance metrics normal
- [ ] No user complaints

### Documentation

```markdown
## Deployment: Laravel 10 → 11

**Date:** [Date]
**Duration:** [Minutes]
**Result:** ✅ Successful

### Changes
- Updated Laravel from 10.x to 11.x
- Migrated Kernel.php to bootstrap/app.php
- Updated model casts properties to methods
- [Other changes]

### Verification
- All tests passing: 156/156
- Error rate: 0.02% (normal)
- Response time: 250ms (normal)
- Queue backlog: 0

### Issues Encountered
- None

### Next Steps
- Monitor for 24 hours
- Get user feedback
- Close ticket
```

## Disaster Recovery

### If Deployment Failed

1. **Immediate action:**
   ```bash
   # Roll back to previous version
   git reset --hard pre-upgrade-backup
   composer install
   php artisan migrate:rollback
   ```

2. **Restore database:**
   ```bash
   php artisan backup:restore --source=local
   ```

3. **Clear everything:**
   ```bash
   php artisan optimize:clear
   ```

4. **Verify:**
   ```bash
   curl https://app.com/health
   ```

5. **Notify team:**
   - Post-mortem meeting
   - Document what went wrong
   - Prevention plan

## Success Criteria

✅ Application running
✅ No errors in logs
✅ Performance normal
✅ All features working
✅ Users report normal experience
✅ Queue processing
✅ Scheduled tasks running
✅ Database healthy
