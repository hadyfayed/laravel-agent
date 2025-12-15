---
description: "Configure automated backups using spatie/laravel-backup"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /backup:setup - Configure Automated Backups

Setup comprehensive backup solution using spatie/laravel-backup.

## Input
$ARGUMENTS = `[--destination=<local|s3|gcs|dropbox>] [--notify=<mail|slack|discord>]`

Examples:
- `/backup:setup` - Interactive setup
- `/backup:setup --destination=s3`
- `/backup:setup --destination=s3 --notify=slack`

## Process

1. **Install Package**
   ```bash
   composer require spatie/laravel-backup
   ```

2. **Publish Config**
   ```bash
   php artisan vendor:publish --provider="Spatie\Backup\BackupServiceProvider"
   ```

3. **Configure Backup**
   - Set backup destinations
   - Configure notification channels
   - Setup cleanup strategy
   - Schedule backups

4. **Create Health Checks** (optional)

## Configuration

### config/backup.php
```php
<?php

return [
    'backup' => [
        'name' => env('APP_NAME', 'laravel-backup'),

        'source' => [
            'files' => [
                'include' => [
                    base_path(),
                ],
                'exclude' => [
                    base_path('vendor'),
                    base_path('node_modules'),
                    storage_path('logs'),
                    storage_path('framework'),
                    base_path('.git'),
                ],
                'follow_links' => false,
                'ignore_unreadable_directories' => true,
            ],

            'databases' => [
                'mysql',
            ],
        ],

        'database_dump_compressor' => \Spatie\DbDumper\Compressors\GzipCompressor::class,

        'database_dump_file_extension' => '',

        'destination' => [
            'filename_prefix' => '',

            'disks' => [
                'local',
                // 's3',
            ],
        ],

        'temporary_directory' => storage_path('app/backup-temp'),

        'password' => env('BACKUP_ARCHIVE_PASSWORD'),

        'encryption' => 'default',
    ],

    'notifications' => [
        'notifications' => [
            \Spatie\Backup\Notifications\Notifications\BackupHasFailedNotification::class => ['mail'],
            \Spatie\Backup\Notifications\Notifications\UnhealthyBackupWasFoundNotification::class => ['mail'],
            \Spatie\Backup\Notifications\Notifications\CleanupHasFailedNotification::class => ['mail'],
            \Spatie\Backup\Notifications\Notifications\BackupWasSuccessfulNotification::class => ['mail'],
            \Spatie\Backup\Notifications\Notifications\HealthyBackupWasFoundNotification::class => ['mail'],
            \Spatie\Backup\Notifications\Notifications\CleanupWasSuccessfulNotification::class => ['mail'],
        ],

        'notifiable' => \Spatie\Backup\Notifications\Notifiable::class,

        'mail' => [
            'to' => env('BACKUP_NOTIFICATION_EMAIL', 'your@example.com'),
            'from' => [
                'address' => env('MAIL_FROM_ADDRESS', 'hello@example.com'),
                'name' => env('MAIL_FROM_NAME', 'Example'),
            ],
        ],

        'slack' => [
            'webhook_url' => env('BACKUP_SLACK_WEBHOOK_URL', ''),
            'channel' => null,
            'username' => null,
            'icon' => null,
        ],

        'discord' => [
            'webhook_url' => env('BACKUP_DISCORD_WEBHOOK_URL', ''),
            'username' => null,
            'avatar_url' => null,
        ],
    ],

    'monitor_backups' => [
        [
            'name' => env('APP_NAME', 'laravel-backup'),
            'disks' => ['local'],
            'health_checks' => [
                \Spatie\Backup\Tasks\Monitor\HealthChecks\MaximumAgeInDays::class => 1,
                \Spatie\Backup\Tasks\Monitor\HealthChecks\MaximumStorageInMegabytes::class => 5000,
            ],
        ],
    ],

    'cleanup' => [
        'strategy' => \Spatie\Backup\Tasks\Cleanup\Strategies\DefaultStrategy::class,

        'default_strategy' => [
            'keep_all_backups_for_days' => 7,
            'keep_daily_backups_for_days' => 16,
            'keep_weekly_backups_for_weeks' => 8,
            'keep_monthly_backups_for_months' => 4,
            'keep_yearly_backups_for_years' => 2,
            'delete_oldest_backups_when_using_more_megabytes_than' => 5000,
        ],
    ],
];
```

### S3 Destination
```php
// config/filesystems.php
'disks' => [
    's3-backup' => [
        'driver' => 's3',
        'key' => env('AWS_BACKUP_ACCESS_KEY_ID'),
        'secret' => env('AWS_BACKUP_SECRET_ACCESS_KEY'),
        'region' => env('AWS_BACKUP_DEFAULT_REGION', 'us-east-1'),
        'bucket' => env('AWS_BACKUP_BUCKET'),
        'url' => env('AWS_BACKUP_URL'),
        'endpoint' => env('AWS_BACKUP_ENDPOINT'),
        'use_path_style_endpoint' => env('AWS_BACKUP_USE_PATH_STYLE_ENDPOINT', false),
    ],
],
```

### Environment Variables
```env
# Backup configuration
BACKUP_ARCHIVE_PASSWORD=your-secure-password
BACKUP_NOTIFICATION_EMAIL=admin@yoursite.com
BACKUP_SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
BACKUP_DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# S3 Backup destination
AWS_BACKUP_ACCESS_KEY_ID=
AWS_BACKUP_SECRET_ACCESS_KEY=
AWS_BACKUP_DEFAULT_REGION=us-east-1
AWS_BACKUP_BUCKET=your-backup-bucket
```

### Schedule Backups
```php
// app/Console/Kernel.php or bootstrap/app.php
$schedule->command('backup:clean')->daily()->at('01:00');
$schedule->command('backup:run')->daily()->at('01:30');
$schedule->command('backup:monitor')->daily()->at('03:00');

// Or for database only (faster)
$schedule->command('backup:run --only-db')->daily()->at('01:30');
```

## Available Commands

```bash
# Run full backup
php artisan backup:run

# Database only backup
php artisan backup:run --only-db

# Files only backup
php artisan backup:run --only-files

# List all backups
php artisan backup:list

# Check backup health
php artisan backup:monitor

# Clean old backups
php artisan backup:clean
```

## Interactive Prompts

When run without arguments, prompt user for:

1. **Backup destination?**
   - Local storage
   - Amazon S3
   - Google Cloud Storage
   - Dropbox
   - SFTP

2. **What to backup?**
   - Full (files + database)
   - Database only
   - Files only

3. **Notification channel?**
   - Email
   - Slack
   - Discord
   - None

4. **Backup schedule?**
   - Daily (recommended)
   - Every 6 hours
   - Weekly
   - Custom

5. **Retention policy?**
   - Standard (7 daily, 4 weekly, 4 monthly)
   - Minimal (3 daily, 2 weekly)
   - Extended (14 daily, 8 weekly, 12 monthly)

## Output

```markdown
## Backup Configuration Complete

### Package Installed
- spatie/laravel-backup

### Configuration
- **Destination**: S3 (your-backup-bucket)
- **Content**: Full (database + files)
- **Schedule**: Daily at 01:30
- **Notifications**: Slack

### Environment Variables Added
```env
BACKUP_ARCHIVE_PASSWORD=
BACKUP_SLACK_WEBHOOK_URL=
AWS_BACKUP_BUCKET=
```

### Commands Available
```bash
php artisan backup:run          # Run backup now
php artisan backup:run --only-db  # Database only
php artisan backup:list         # List all backups
php artisan backup:monitor      # Check health
php artisan backup:clean        # Clean old backups
```

### Schedule Added
- `backup:clean` - Daily at 01:00
- `backup:run` - Daily at 01:30
- `backup:monitor` - Daily at 03:00

### Next Steps
1. Add credentials to .env
2. Run `php artisan backup:run` to test
3. Verify backup in destination
4. Test restore procedure
```
