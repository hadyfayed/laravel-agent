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

## Zero-Downtime Deployment

```bash
#!/bin/bash
# deploy.sh - Atomic deployment script

RELEASE_DIR="/var/www/releases/$(date +%Y%m%d%H%M%S)"
SHARED_DIR="/var/www/shared"
CURRENT_LINK="/var/www/current"

# Clone new release
git clone --depth 1 git@github.com:user/repo.git "$RELEASE_DIR"

# Link shared directories
ln -nfs "$SHARED_DIR/.env" "$RELEASE_DIR/.env"
ln -nfs "$SHARED_DIR/storage" "$RELEASE_DIR/storage"

# Install dependencies
cd "$RELEASE_DIR"
composer install --no-dev --optimize-autoloader

# Build assets
npm ci && npm run build

# Run migrations
php artisan migrate --force

# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Atomic switch
ln -nfs "$RELEASE_DIR" "$CURRENT_LINK"

# Reload services
sudo systemctl reload php-fpm
php artisan queue:restart

# Cleanup old releases (keep last 5)
ls -dt /var/www/releases/*/ | tail -n +6 | xargs rm -rf

echo "Deployed successfully: $RELEASE_DIR"
```

## Health Check Endpoint

```php
// routes/web.php
Route::get('/health', function () {
    $checks = [
        'database' => fn () => DB::connection()->getPdo(),
        'cache' => fn () => Cache::store()->get('health'),
        'storage' => fn () => Storage::disk('local')->exists('.gitignore'),
    ];

    $results = [];
    $healthy = true;

    foreach ($checks as $name => $check) {
        try {
            $check();
            $results[$name] = 'ok';
        } catch (\Exception $e) {
            $results[$name] = 'failed';
            $healthy = false;
        }
    }

    return response()->json([
        'status' => $healthy ? 'healthy' : 'unhealthy',
        'checks' => $results,
        'timestamp' => now()->toISOString(),
    ], $healthy ? 200 : 503);
});
```

## GitHub Actions Complete

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: testing
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: mbstring, dom, fileinfo, mysql
          coverage: xdebug

      - name: Install Dependencies
        run: composer install --no-progress --prefer-dist

      - name: Run Tests
        run: php artisan test --coverage --min=80
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: password

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to Production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /var/www/html
            ./deploy.sh
```

## Rollback Script

```bash
#!/bin/bash
# rollback.sh - Quick rollback to previous release

RELEASES_DIR="/var/www/releases"
CURRENT_LINK="/var/www/current"

# Get previous release
PREVIOUS=$(ls -dt "$RELEASES_DIR"/*/ | sed -n '2p')

if [ -z "$PREVIOUS" ]; then
    echo "No previous release found!"
    exit 1
fi

# Atomic rollback
ln -nfs "$PREVIOUS" "$CURRENT_LINK"

# Reload services
sudo systemctl reload php-fpm
php artisan queue:restart

echo "Rolled back to: $PREVIOUS"
```

## Monitoring

- **Laravel Pulse** - Application monitoring
- **Sentry** - Error tracking
- **New Relic** - APM
- **Laravel Telescope** - Debug (dev only)

## Common Pitfalls

1. **Forgetting to Run Migrations**
   ```bash
   # Always include in deploy script
   php artisan migrate --force
   ```

2. **Not Caching in Production**
   ```bash
   # Run ALL cache commands
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   php artisan event:cache
   ```

3. **Missing Queue Restart**
   ```bash
   # Workers cache old code
   php artisan queue:restart
   ```

4. **Incorrect File Permissions**
   ```bash
   # Fix storage permissions
   chmod -R 775 storage bootstrap/cache
   chown -R www-data:www-data storage bootstrap/cache
   ```

5. **Missing Environment Variables**
   ```bash
   # Check .env exists and has required values
   if [ ! -f .env ]; then
       echo "Missing .env file!"
       exit 1
   fi
   ```

6. **Not Testing Locally First**
   ```bash
   # Always test production config locally
   php artisan config:cache
   php artisan test
   php artisan config:clear  # Reset for dev
   ```

7. **No Rollback Strategy**
   ```bash
   # Always keep previous releases
   # Use symlinks for instant rollback
   ```

## Best Practices

- Always backup before deploying
- Use zero-downtime deployments
- Monitor after each deploy
- Have rollback strategy ready
- Use environment-specific configs
- Test migrations on staging first
- Use health check endpoints
- Set up alerting for failures

## Related Commands

- `/laravel-agent:deploy:setup` - Configure deployment
- `/laravel-agent:cicd:setup` - Setup CI/CD pipeline

## Related Agents

- `laravel-deploy` - Deployment specialist
- `laravel-cicd` - CI/CD pipeline specialist
