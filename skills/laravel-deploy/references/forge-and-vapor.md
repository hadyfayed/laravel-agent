# Laravel Forge and Vapor Reference

Server provisioning and serverless deployment for Laravel via Forge and Vapor.

## Laravel Forge

Server provisioning and deployment for VPS/Cloud. Forge handles server provisioning in its dashboard (PHP version, database, SSL certificates, deployment script).

```bash
# forge.yml (Deployment Script)
cd /home/forge/yoursite.com
git pull origin main
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Restart queue workers
php artisan queue:restart

# Restart Octane if installed
php artisan octane:reload 2>/dev/null || true

# Restart Horizon if installed
php artisan horizon:terminate 2>/dev/null || true
```

**Forge Environment Variables:**
```env
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:...
APP_URL=https://yoursite.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=forge
DB_PASSWORD=your_password

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Horizon specific
HORIZON_PREFIX=your-app-horizon:
```

**Supervisor Config (Horizon):**
```ini
[program:horizon]
process_name=%(program_name)s
command=php /home/forge/yoursite.com/artisan horizon
autostart=true
autorestart=true
user=forge
redirect_stderr=true
stdout_logfile=/home/forge/yoursite.com/storage/logs/horizon.log
stopwaitsecs=3600
```

## Laravel Vapor (Serverless AWS)

```bash
composer require laravel/vapor-cli --dev
vendor/bin/vapor login
vendor/bin/vapor init
vendor/bin/vapor deploy production
```

```yaml
# vapor.yml
id: your-app-id
name: your-app
environments:
    production:
        memory: 1024
        cli-memory: 512
        runtime: 'php-8.3:al2'
        build:
            - 'composer install --no-dev --optimize-autoloader'
            - 'php artisan event:cache'
            - 'php artisan config:cache'
            - 'npm ci && npm run build'
        deploy:
            - 'php artisan migrate --force'
        queues:
            - default
            - notifications
        database: your-database
        cache: your-cache
        storage: your-bucket
        gateway-version: 2
        warm: 10
        concurrency: 50

    staging:
        memory: 512
        cli-memory: 256
        runtime: 'php-8.3:al2'
        build:
            - 'composer install --optimize-autoloader'
            - 'npm ci && npm run build'
        deploy:
            - 'php artisan migrate --force'
        database: your-staging-database
        cache: your-staging-cache
        storage: your-staging-bucket
```

**Vapor Commands:**
```bash
# Deploy to environment
vapor deploy production
vapor deploy staging

# Run commands
vapor command production "php artisan tinker"
vapor command production --command="migrate:status"

# Logs
vapor tail production

# Database tunnel
vapor database:tunnel production

# Manage secrets
vapor secret production SECRET_NAME
vapor env:push production
vapor env:pull production
```
