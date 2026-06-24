# Deep Backup Configuration

## config/backup.php Template

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

## S3 Destination

In `config/filesystems.php`:

```php
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
```

Environment variables for S3:

```env
AWS_BACKUP_ACCESS_KEY_ID=your-key
AWS_BACKUP_SECRET_ACCESS_KEY=your-secret
AWS_BACKUP_DEFAULT_REGION=us-east-1
AWS_BACKUP_BUCKET=your-backup-bucket
```

## GCS Destination

In `config/filesystems.php`:

```php
'gcs-backup' => [
    'driver' => 'gcs',
    'project_id' => env('GOOGLE_CLOUD_PROJECT_ID'),
    'key_file' => env('GOOGLE_CLOUD_KEY_FILE'),
    'bucket' => env('GOOGLE_CLOUD_BACKUP_BUCKET'),
],
```

## Dropbox Destination

In `config/filesystems.php`:

```php
'dropbox-backup' => [
    'driver' => 'dropbox',
    'authorization_token' => env('DROPBOX_BACKUP_TOKEN'),
],
```

## Retention Policies

Standard (default):
- Keep all for 7 days
- Keep daily for 16 days
- Keep weekly for 8 weeks
- Keep monthly for 4 months
- Keep yearly for 2 years

Extended (long-term):
- Keep all for 14 days
- Keep daily for 30 days
- Keep weekly for 16 weeks
- Keep monthly for 12 months
- Keep yearly for 5 years

Minimal (cost-conscious):
- Keep all for 3 days
- Keep daily for 7 days
- Keep weekly for 4 weeks
- Keep monthly for 3 months
