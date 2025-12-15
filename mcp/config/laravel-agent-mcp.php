<?php

declare(strict_types=1);

return [
    /*
    |--------------------------------------------------------------------------
    | Enabled Tools
    |--------------------------------------------------------------------------
    |
    | Configure which MCP tools are enabled. Set to false to disable specific
    | tools that you don't want exposed to AI assistants.
    |
    */
    'tools' => [
        'testing' => [
            'test:run' => true,
            'test:coverage' => true,
        ],
        'queue' => [
            'queue:status' => true,
            'queue:failed' => true,
        ],
        'cache' => [
            'cache:status' => true,
        ],
        'performance' => [
            'perf:queries' => true,
        ],
        'migrations' => [
            'migrate:status' => true,
        ],
        'events' => [
            'event:list' => true,
        ],
        'schedule' => [
            'schedule:list' => true,
        ],
        'security' => [
            'security:deps' => true,
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Security Settings
    |--------------------------------------------------------------------------
    |
    | Configure security settings for MCP tools.
    |
    */
    'security' => [
        // Maximum number of failed jobs to return
        'max_failed_jobs' => 50,

        // Maximum query log entries to return
        'max_slow_queries' => 20,

        // Redact sensitive data from outputs
        'redact_sensitive' => true,
    ],
];
