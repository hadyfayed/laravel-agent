---
name: laravel-deploy
description: >
  Deploy Laravel applications to production with Forge, Vapor, Docker, or traditional
  servers. Use when the user wants to deploy, setup hosting, configure servers, or
  go to production. Triggers: "deploy", "production", "hosting", "server", "Forge",
  "Vapor", "Docker", "AWS", "CI/CD", "release", "go live".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Deploy Skill

Deploy Laravel applications to any environment.

## When to Use

- Setting up deployment
- Configuring production servers
- Docker containerization
- CI/CD pipeline setup
- Cloud deployment (AWS, GCP, DigitalOcean)

## Quick Start

```bash
/laravel-agent:deploy:setup <platform>
```

## Deployment Options

### Laravel Forge (Recommended)

```bash
# Forge handles server provisioning
# Configure in Forge dashboard:
# - PHP version
# - Database
# - SSL certificates
# - Deployment script
```

### Laravel Vapor (Serverless)

```bash
composer require laravel/vapor-cli --dev
vendor/bin/vapor login
vendor/bin/vapor init
vendor/bin/vapor deploy production
```

```yaml
# vapor.yml
id: 12345
name: my-app
environments:
  production:
    memory: 1024
    cli-memory: 512
    runtime: php-8.3:al2
    build:
      - 'composer install --no-dev'
```

### Docker

```dockerfile
# Dockerfile
FROM php:8.3-fpm-alpine

RUN apk add --no-cache \
    nginx supervisor \
    && docker-php-ext-install pdo pdo_mysql opcache

COPY . /var/www/html
WORKDIR /var/www/html

RUN composer install --no-dev --optimize-autoloader

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports:
      - "80:80"
    environment:
      - APP_ENV=production
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:alpine

volumes:
  mysql_data:
```

### Traditional Server

```bash
# Deploy script
#!/bin/bash
cd /var/www/html

git pull origin main
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan queue:restart

sudo systemctl reload php-fpm
```

## Production Checklist

### Environment
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

LOG_CHANNEL=stack
LOG_LEVEL=error

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
```

### Optimization
```bash
# Run before deploy
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

### Database
```bash
# Run migrations
php artisan migrate --force

# Seed if needed (careful in production!)
php artisan db:seed --class=ProductionSeeder --force
```

### Queue Workers
```ini
# /etc/supervisor/conf.d/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=4
```

### Scheduled Tasks
```cron
# Crontab entry
* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1
```

## CI/CD Integration

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'

      - name: Install Dependencies
        run: composer install --no-dev --optimize-autoloader

      - name: Run Tests
        run: php artisan test

      - name: Deploy
        run: |
          # Your deployment command
```

## Monitoring

- **Laravel Pulse** - Application monitoring
- **Sentry** - Error tracking
- **New Relic** - APM
- **Laravel Telescope** - Debug (dev only)

## Best Practices

- Always backup before deploying
- Use zero-downtime deployments
- Monitor after each deploy
- Have rollback strategy ready
- Use environment-specific configs
