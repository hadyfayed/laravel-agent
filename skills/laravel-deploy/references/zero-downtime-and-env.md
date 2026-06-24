# Laravel Zero-Downtime Deployment, Environment, and CI/CD Reference

Environment templates, traditional server deployment, atomic zero-downtime releases, rollback, health checks, CI/CD pipelines, and Envoy task runner.

## Production .env Template

```env
APP_NAME="Your App"
APP_ENV=production
APP_KEY=base64:...
APP_DEBUG=false
APP_URL=https://yourapp.com

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=your-db-host
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_user
DB_PASSWORD=your_password

BROADCAST_DRIVER=pusher
CACHE_DRIVER=redis
FILESYSTEM_DISK=s3
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_CLIENT=phpredis
REDIS_HOST=your-redis-host
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=ses
MAIL_FROM_ADDRESS="noreply@yourapp.com"
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket
AWS_USE_PATH_STYLE_ENDPOINT=false

# Horizon
HORIZON_MEMORY_LIMIT=128

# Telescope (disabled in production)
TELESCOPE_ENABLED=false

# Feature flags
FEATURE_NEW_DASHBOARD=false
```

### Environment (core production subset)

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

## Traditional Server Deploy Script

```bash
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

## Production Optimization Commands

```bash
# Run before deploy
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

```bash
# Run migrations
php artisan migrate --force

# Seed if needed (careful in production!)
php artisan db:seed --class=ProductionSeeder --force
```

## Queue Workers (Supervisor)

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

## Scheduled Tasks

```cron
# Crontab entry
* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1
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

### Detailed Zero-Downtime (with service reload)

```bash
#!/bin/bash
# deploy.sh - Zero-downtime deployment script

set -e

APP_DIR="/var/www/yoursite.com"
RELEASES_DIR="$APP_DIR/releases"
SHARED_DIR="$APP_DIR/shared"
CURRENT_LINK="$APP_DIR/current"

RELEASE_NAME=$(date +%Y%m%d%H%M%S)
NEW_RELEASE_DIR="$RELEASES_DIR/$RELEASE_NAME"

echo "Creating new release directory..."
mkdir -p "$NEW_RELEASE_DIR"

echo "Cloning repository..."
git clone --depth=1 git@github.com:your/repo.git "$NEW_RELEASE_DIR"

echo "Installing dependencies..."
cd "$NEW_RELEASE_DIR"
composer install --no-dev --optimize-autoloader --no-interaction

echo "Linking shared directories..."
ln -nfs "$SHARED_DIR/.env" "$NEW_RELEASE_DIR/.env"
ln -nfs "$SHARED_DIR/storage" "$NEW_RELEASE_DIR/storage"

echo "Running migrations..."
php artisan migrate --force

echo "Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

echo "Switching to new release..."
ln -nfs "$NEW_RELEASE_DIR" "$CURRENT_LINK"

echo "Restarting services..."
php artisan queue:restart
php artisan octane:reload 2>/dev/null || true

echo "Cleaning old releases..."
cd "$RELEASES_DIR"
ls -t | tail -n +6 | xargs rm -rf

echo "Deployment complete!"
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

### API Health Check (with queue probe)

```php
// routes/api.php
Route::get('/health', function () {
    $checks = [
        'app' => true,
        'database' => false,
        'cache' => false,
        'queue' => false,
    ];

    try {
        DB::connection()->getPdo();
        $checks['database'] = true;
    } catch (\Exception $e) {
        $checks['database'] = false;
    }

    try {
        Cache::store()->get('health-check');
        $checks['cache'] = true;
    } catch (\Exception $e) {
        $checks['cache'] = false;
    }

    try {
        Queue::size();
        $checks['queue'] = true;
    } catch (\Exception $e) {
        $checks['queue'] = false;
    }

    $healthy = !in_array(false, $checks, true);

    return response()->json([
        'status' => $healthy ? 'healthy' : 'unhealthy',
        'checks' => $checks,
        'timestamp' => now()->toIso8601String(),
    ], $healthy ? 200 : 503);
});
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

## GitHub Actions (Complete, test + SSH deploy)

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

## Laravel Envoy (Task Runner)

If `laravel/envoy` is installed:

### Install

```bash
composer require laravel/envoy --dev
```

### Envoy.blade.php

```blade
@servers(['web' => 'user@yourserver.com', 'staging' => 'user@staging.yourserver.com'])

@setup
    $repository = 'git@github.com:your/repo.git';
    $releases_dir = '/var/www/yoursite.com/releases';
    $app_dir = '/var/www/yoursite.com';
    $release = date('YmdHis');
    $new_release_dir = $releases_dir .'/'. $release;
@endsetup

@story('deploy')
    clone_repository
    run_composer
    update_symlinks
    run_migrations
    cache_config
    restart_services
    cleanup_old
@endstory

@task('clone_repository', ['on' => 'web'])
    echo 'Cloning repository...'
    [ -d {{ $releases_dir }} ] || mkdir -p {{ $releases_dir }}
    git clone --depth 1 {{ $repository }} {{ $new_release_dir }}
    cd {{ $new_release_dir }}
    git checkout {{ $branch ?? 'main' }}
@endtask

@task('run_composer', ['on' => 'web'])
    echo "Starting deployment ({{ $release }})"
    cd {{ $new_release_dir }}
    composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
@endtask

@task('update_symlinks', ['on' => 'web'])
    echo "Linking storage directory..."
    rm -rf {{ $new_release_dir }}/storage
    ln -nfs {{ $app_dir }}/storage {{ $new_release_dir }}/storage

    echo 'Linking .env file...'
    ln -nfs {{ $app_dir }}/.env {{ $new_release_dir }}/.env

    echo 'Linking current release...'
    ln -nfs {{ $new_release_dir }} {{ $app_dir }}/current
@endtask

@task('run_migrations', ['on' => 'web'])
    echo "Running migrations..."
    cd {{ $new_release_dir }}
    php artisan migrate --force
@endtask

@task('cache_config', ['on' => 'web'])
    echo "Caching configuration..."
    cd {{ $new_release_dir }}
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan event:cache
@endtask

@task('restart_services', ['on' => 'web'])
    echo "Restarting services..."
    cd {{ $new_release_dir }}
    php artisan queue:restart
    php artisan octane:reload 2>/dev/null || true
    sudo supervisorctl restart horizon 2>/dev/null || true
@endtask

@task('cleanup_old', ['on' => 'web'])
    echo "Cleaning up old releases..."
    cd {{ $releases_dir }}
    ls -dt */ | tail -n +6 | xargs -d "\n" rm -rf 2>/dev/null || true
@endtask

@task('rollback', ['on' => 'web'])
    echo "Rolling back to previous release..."
    cd {{ $releases_dir }}
    ln -nfs {{ $releases_dir }}/$(ls -t {{ $releases_dir }} | head -2 | tail -1) {{ $app_dir }}/current
    php artisan cache:clear
@endtask

@task('health_check', ['on' => 'web'])
    curl -sf {{ $app_url ?? 'https://yoursite.com' }}/api/health || exit 1
@endtask

@finished
    @slack('webhook-url', '#deployments', "Deployed {$release} to production!")
@endfinished

@error
    @slack('webhook-url', '#deployments', "Deployment failed!")
@enderror
```

### Run Commands

```bash
# Deploy to production
envoy run deploy

# Deploy with branch
envoy run deploy --branch=feature/new-feature

# Deploy to staging
envoy run deploy --on=staging

# Rollback
envoy run rollback

# Check health
envoy run health_check
```

### Parallel Tasks

```blade
@task('build_assets', ['on' => 'web', 'parallel' => true])
    cd {{ $new_release_dir }}
    npm ci && npm run build
@endtask
```

### Confirmations

```blade
@task('migrate', ['on' => 'web', 'confirm' => true])
    cd {{ $new_release_dir }}
    php artisan migrate --force
@endtask
```
