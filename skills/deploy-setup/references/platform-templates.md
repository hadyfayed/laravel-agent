# Deployment Platform Templates

## Forge Deployment Script (deploy.sh)

```bash
#!/bin/bash
set -e

echo "Deploying to production..."

# Update code
git pull origin main

# Install dependencies
composer install --no-dev --prefer-dist

# Run migrations
php artisan migrate --force

# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Run queue workers restart
php artisan queue:restart

echo "Deployment complete!"
```

Forge webhook URL format:
```
https://your-server.com/deploy?token=<secret-token>
```

## Vapor Configuration (vapor.yml)

```yaml
id: <project-id>
name: myapp
runtime: php82fpm

environments:
  staging:
    build:
      - 'composer install'
    runtime: php82fpm
    memory: 1024
    database: aurora-mysql
    cache: redis

  production:
    build:
      - 'composer install --no-dev'
    runtime: php82fpm
    memory: 2048
    database: aurora-mysql
    cache: redis
    database_backup_retention_days: 14
```

## Docker Deployment (Dockerfile)

```dockerfile
# Build stage
FROM php:8.3-fpm as build

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libpq-dev \
    && docker-php-ext-install zip pdo pdo_mysql pdo_pgsql

# Copy composer and install dependencies
COPY composer.* ./
RUN composer install --no-dev --prefer-dist --no-interaction

# Copy application
COPY . .

# Production stage
FROM php:8.3-fpm

WORKDIR /app

# Install production dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev libpq-dev \
    && docker-php-ext-install zip pdo pdo_mysql pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# Copy from build
COPY --from=build /app .

# Set permissions
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]
```

## docker-compose.yml for local development/staging

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DB_HOST=db
      - DB_DATABASE=laravel
      - DB_USERNAME=laravel
      - DB_PASSWORD=secret
      - REDIS_HOST=redis
    depends_on:
      - db
      - redis
    volumes:
      - .:/app

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=laravel
      - MYSQL_USER=laravel
      - MYSQL_PASSWORD=secret
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - .:/app
    depends_on:
      - app

volumes:
  db_data:
```

## Bref Serverless Configuration (serverless.yml)

```yaml
service: myapp

provider:
  name: aws
  runtime: provided.al2
  region: us-east-1
  environment:
    APP_KEY: ${ssm:/myapp/app_key}
    DB_HOST: ${ssm:/myapp/db_host}
    DB_DATABASE: ${ssm:/myapp/db_name}
    CACHE_DRIVER: redis

functions:
  website:
    handler: public/index.php
    runtime: php-82-fpm
    events:
      - http:
          path: /{proxy+}
          method: ANY
      - http:
          path: /
          method: ANY

  artisan:
    handler: artisan
    runtime: php-82-cli
    timeout: 120

plugins:
  - ./vendor/bref/bref
```

## Zero-Downtime Deployment Strategy

1. **Database Migrations**: Always reversible, run before code update
2. **Feature Flags**: Gate new features during rollout
3. **Horizon/Queue**: Graceful shutdown with `queue:restart`
4. **Health Checks**: Verify app readiness before routing traffic
5. **Rollback Plan**: Keep previous release available for quick rollback

Health check endpoint (app/Http/Controllers/HealthController.php):
```php
<?php

namespace App\Http\Controllers;

class HealthController extends Controller
{
    public function __invoke()
    {
        return response()->json([
            'status' => 'ok',
            'version' => config('app.version'),
        ]);
    }
}
```

Register in routes/api.php:
```php
Route::get('/health', HealthController::class);
```

## Environment Variables Checklist

Essential for all deployments:
- [ ] APP_KEY (Laravel encryption key)
- [ ] APP_DEBUG=false (production)
- [ ] APP_ENV=production
- [ ] LOG_CHANNEL=stack

Database:
- [ ] DB_HOST, DB_PORT, DB_DATABASE
- [ ] DB_USERNAME, DB_PASSWORD

Cache & Queue:
- [ ] CACHE_DRIVER, REDIS_HOST, REDIS_PASSWORD
- [ ] QUEUE_DRIVER

File Storage:
- [ ] AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
- [ ] AWS_DEFAULT_REGION, AWS_BUCKET

Optional (based on features):
- [ ] MAIL_HOST, MAIL_USERNAME, MAIL_PASSWORD (if using email)
- [ ] STRIPE_SECRET_KEY (if using Stripe)
- [ ] PUSHER_APP_KEY (if using WebSockets)
