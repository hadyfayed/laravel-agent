# Laravel Octane Setup & Servers Reference

Server choice (Swoole/RoadRunner/FrankenPHP), installation, configuration, and deployment for Octane high-performance application servers.

## When to Use

- Need extreme performance (2-4x faster than PHP-FPM)
- High-traffic applications
- Concurrent task execution required
- Microservices with heavy request loads
- API servers with low latency requirements
- WebSocket or real-time features

## Quick Start

```bash
composer require laravel/octane
php artisan octane:install
php artisan octane:start
```

## Environment Check

```bash
# Check for Octane and servers
composer show laravel/octane 2>/dev/null && echo "OCTANE=yes" || echo "OCTANE=no"
php -m | grep -q swoole && echo "SWOOLE=yes" || echo "SWOOLE=no"
which rr 2>/dev/null && echo "ROADRUNNER=yes" || echo "ROADRUNNER=no"
```

## Server Choice: Swoole vs RoadRunner vs FrankenPHP

### Swoole (Recommended for Maximum Performance)

**Best for:** Maximum concurrency, WebSockets, coroutines

**Pros:**
- Fastest performance
- Built-in coroutine support
- WebSocket server included
- HTTP/2 support
- Table and cache features

**Cons:**
- Requires PHP extension (not pure PHP)
- Harder to debug
- More memory usage

**Installation:**
```bash
pecl install swoole
# Or via Docker
FROM php:8.3-cli
RUN pecl install swoole && docker-php-ext-enable swoole

# Install Octane with Swoole
php artisan octane:install --server=swoole
```

### RoadRunner (Pure Go Server)

**Best for:** Easier deployment, no PHP extensions, moderate performance

**Pros:**
- No PHP extension needed (pure Go binary)
- Easy deployment
- Good performance
- HTTP/2 and gRPC support
- Simpler debugging

**Cons:**
- Slightly slower than Swoole
- No coroutines
- Larger binary size

**Installation:**
```bash
# RoadRunner downloads automatically
php artisan octane:install --server=roadrunner

# Manual install
./rr get-binary
```

### FrankenPHP (Modern Alternative)

**Best for:** Modern PHP features, Laravel + Caddy integration

**Pros:**
- Built on Caddy web server
- Automatic HTTPS
- HTTP/2, HTTP/3 support
- Easy deployment
- Worker mode support

**Cons:**
- Newer, less battle-tested
- Still evolving

**Installation:**
```bash
php artisan octane:install --server=frankenphp
```

## Server Selection Table

| Server | Pros | Cons |
|--------|------|------|
| Swoole | Fastest, coroutines, WebSockets | Requires extension |
| RoadRunner | Pure Go, no extension | Slightly slower |
| FrankenPHP | PHP 8.2+, Early Access | Newer, less mature |

## Installation

```bash
# Install Octane
composer require laravel/octane

# Install with Swoole
php artisan octane:install --server=swoole
# Requires: pecl install swoole

# Install with RoadRunner
php artisan octane:install --server=roadrunner
# Downloads RoadRunner binary

# Install with FrankenPHP
php artisan octane:install --server=frankenphp
# Requires FrankenPHP binary

# Start server
php artisan octane:start

# Start with file watching (development)
php artisan octane:start --watch

# Start with specific port/workers
php artisan octane:start --host=0.0.0.0 --port=8000 --workers=4
```

## Configuration

```php
// config/octane.php

return [
    'server' => env('OCTANE_SERVER', 'swoole'),

    'https' => env('OCTANE_HTTPS', false),

    'listeners' => [
        WorkerStarting::class => [
            EnsureUploadedFilesAreValid::class,
            EnsureUploadedFilesCanBeMoved::class,
        ],

        RequestReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
            ...Octane::prepareApplicationForNextRequest(),
        ],

        RequestHandled::class => [],

        RequestTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],

        TaskReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
        ],

        TaskTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],

        TickReceived::class => [
            ...Octane::prepareApplicationForNextOperation(),
        ],

        TickTerminated::class => [
            FlushTemporaryContainerInstances::class,
        ],

        OperationTerminated::class => [
            FlushSessionState::class,
        ],

        WorkerErrorOccurred::class => [
            ReportException::class,
            StopWorkerIfNecessary::class,
        ],

        WorkerStopping::class => [],
    ],

    'warm' => [
        ...Octane::defaultServicesToWarm(),
    ],

    'cache' => [
        'driver' => env('OCTANE_CACHE_DRIVER', 'octane'),
        'table' => env('OCTANE_CACHE_TABLE', 'octane_cache'),
        'rows' => env('OCTANE_CACHE_ROWS', 1000),
        'bytes' => env('OCTANE_CACHE_BYTES', 10000),
    ],

    'tables' => [
        'example:1000' => [
            'name' => ['type' => 'string', 'size' => 1000],
            'votes' => ['type' => 'int'],
        ],
    ],

    'swoole' => [
        'options' => [
            'log_file' => storage_path('logs/swoole_http.log'),
            'package_max_length' => 10 * 1024 * 1024, // 10MB
            'max_request' => 1000, // Restart worker after 1000 requests
            'dispatch_mode' => 2,
            'open_tcp_nodelay' => true,
            'tcp_fastopen' => true,
            'enable_coroutine' => true,
            'task_worker_num' => env('OCTANE_TASK_WORKERS', 4),
        ],
    ],

    'roadrunner' => [
        'rpc_port' => env('OCTANE_RPC_PORT', 6001),
        'rpc_host' => env('OCTANE_RPC_HOST', '127.0.0.1'),
    ],

    'max_execution_time' => 30,
    'garbage_collection' => [
        'interval' => 1000,
    ],
];
```

### Agent Configuration (config/octane.php)

```php
<?php

// config/octane.php
return [
    'server' => env('OCTANE_SERVER', 'swoole'),

    'https' => env('OCTANE_HTTPS', false),

    'listeners' => [
        // Add custom listeners
    ],

    'warm' => [
        // Services to warm on boot
        \App\Services\CacheService::class,
    ],

    'flush' => [
        // Services to flush between requests
    ],

    'garbage' => 50, // Run GC every N requests

    'max_execution_time' => 30,

    'swoole' => [
        'options' => [
            'log_file' => storage_path('logs/swoole.log'),
            'worker_num' => env('OCTANE_WORKERS', swoole_cpu_num()),
            'task_worker_num' => env('OCTANE_TASK_WORKERS', swoole_cpu_num()),
            'max_request' => env('OCTANE_MAX_REQUESTS', 500),
            'enable_static_handler' => false,
            'document_root' => public_path(),
            'package_max_length' => 10 * 1024 * 1024,
        ],
    ],

    'roadrunner' => [
        'http' => [
            'max_request_size' => 10,
        ],
    ],

    'tables' => [
        // In-memory Swoole tables
        'cache' => [
            'columns' => [
                ['name' => 'value', 'type' => \Laravel\Octane\Octane::TABLE_COLUMN_STRING, 'size' => 10000],
                ['name' => 'expires_at', 'type' => \Laravel\Octane\Octane::TABLE_COLUMN_INT],
            ],
            'rows' => 1000,
        ],
    ],

    'watch' => [
        'app',
        'bootstrap',
        'config',
        'database',
        'public/**/*.php',
        'resources/**/*.php',
        'routes',
        'composer.lock',
        '.env',
    ],
];
```

## Deployment with Octane

### Supervisor Configuration

```ini
# /etc/supervisor/conf.d/octane.conf
[program:octane]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --workers=4 --task-workers=6
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/octane.log
stopwaitsecs=3600
```

### Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/app.conf
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM php:8.3-cli

# Install Swoole
RUN pecl install swoole && docker-php-ext-enable swoole

# Install dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader

# Optimize Laravel
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

EXPOSE 8000

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OCTANE_SERVER=swoole
      - DB_HOST=mysql
      - REDIS_HOST=redis
    depends_on:
      - mysql
      - redis
    restart: unless-stopped

  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: laravel
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine

volumes:
  mysql_data:
```

### Agent Deployment (docker-compose + supervisor)

```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports:
      - "8000:8000"
    command: php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000
    environment:
      - OCTANE_SERVER=swoole
      - OCTANE_WORKERS=4

# supervisor.conf
[program:octane]
process_name=%(program_name)s
command=php /var/www/html/artisan octane:start --server=swoole --host=0.0.0.0 --port=8000
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/octane.log
stopwaitsecs=3600
```

### Hot Reload for Development

```bash
# Install file watcher
npm install --save-dev chokidar

# Watch and reload
php artisan octane:start --watch

# Or manually reload
php artisan octane:reload
```

### Graceful Reload (Zero Downtime)

```bash
# Reload workers without downtime
php artisan octane:reload

# Via Supervisor
supervisorctl restart octane:*
```

### Zero-Downtime Reload (Signal)

```bash
# Reload workers (graceful, no downtime)
php artisan octane:reload

# In deployment script
php artisan octane:reload

# Or with signal
kill -USR1 $(cat storage/octane.pid)
```

## Related Commands

```bash
# Start Octane server
php artisan octane:start

# Start with options
php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --workers=4

# Start with auto-reload on file changes
php artisan octane:start --watch

# Reload workers
php artisan octane:reload

# Stop server
php artisan octane:stop

# Get server status
php artisan octane:status

# Install Octane with server choice
php artisan octane:install --server=swoole
```
