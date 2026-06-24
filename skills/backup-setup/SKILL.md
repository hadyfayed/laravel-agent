---
name: backup-setup
description: Configure automated backups (spatie/laravel-backup) — schedule, storage disks, retention, monitoring/notifications; when setting up backups.
disable-model-invocation: true
allowed-tools: Bash(composer require) Bash(composer show *) Bash(php artisan *) Read Write Edit
argument-hint: "[local|s3|gcs|dropbox] [--notify=mail|slack|discord] [--full|--db-only]"
---

## Environment

Installed backup packages:
!`composer show spatie/laravel-backup 2>/dev/null && echo "backup=yes" || echo "backup=no"`

## Task

Wire up automated backups using spatie/laravel-backup. `$ARGUMENTS` carries the preset (`local`, `s3`, `gcs`, `dropbox`), optional `--notify=` flag for notifications, and optional `--full|--db-only` for backup scope.

## Steps

1. **Install package** (if not already present):
   ```bash
   composer require spatie/laravel-backup
   ```

2. **Publish config and migration**:
   ```bash
   php artisan vendor:publish --provider="Spatie\Backup\BackupServiceProvider"
   php artisan migrate
   ```

3. **Configure backup** in `config/backup.php`:
   - Set source: included/excluded files, databases
   - Destination: local disk or cloud (S3, GCS, Dropbox)
   - Notification channels: mail, Slack, Discord
   - Cleanup strategy: keep daily/weekly/monthly backups per retention policy
   - For cloud storage, update `config/filesystems.php` disk entries per the destination type

4. **Schedule backups** in `app/Console/Kernel.php` (or `bootstrap/app.php` for Laravel 11+):
   ```php
   $schedule->command('backup:clean')->daily()->at('01:00');
   $schedule->command('backup:run')->daily()->at('01:30');
   $schedule->command('backup:monitor')->daily()->at('03:00');
   // Or for database only (faster):
   // $schedule->command('backup:run --only-db')->daily()->at('01:30');
   ```

5. **Set environment variables** in `.env`:
   - `BACKUP_ARCHIVE_PASSWORD` — encryption password
   - `BACKUP_NOTIFICATION_EMAIL` — email destination
   - `BACKUP_SLACK_WEBHOOK_URL` (if Slack) — Slack webhook
   - `BACKUP_DISCORD_WEBHOOK_URL` (if Discord) — Discord webhook
   - Cloud credentials (S3: `AWS_BACKUP_*`, GCS: `GCS_BACKUP_*`, Dropbox: `DROPBOX_BACKUP_TOKEN`)

6. **Test the setup**:
   ```bash
   php artisan backup:run
   php artisan backup:list
   php artisan backup:monitor
   ```

## Available commands

```bash
php artisan backup:run              # Full backup
php artisan backup:run --only-db    # Database only
php artisan backup:run --only-files # Files only
php artisan backup:list             # List all backups
php artisan backup:monitor          # Check health
php artisan backup:clean            # Clean old backups per policy
```

## Reference

Deep configuration details, disk setup per provider, and retention strategies: see `${CLAUDE_SKILL_DIR}/references/backup-config.md`.
