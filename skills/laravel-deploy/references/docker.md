# Laravel Docker Reference

Containerized Laravel deployment with multi-stage Docker, Nginx, Supervisor, OPcache, docker-compose, and Bref (AWS Lambda).

## Production Dockerfile

```dockerfile
# Dockerfile
FROM php:8.3-fpm-alpine as base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    redis \
    supervisor \
    nginx

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip opcache

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Build stage
FROM base as build

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-scripts \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && php artisan event:cache

# Production stage
FROM base as production

COPY --from=build /var/www /var/www

# Set permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Copy configurations
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
```

## Nginx Config

```nginx
# docker/nginx.conf
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;

    sendfile on;
    keepalive_timeout 65;
    gzip on;

    server {
        listen 80;
        server_name _;
        root /var/www/public;
        index index.php;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            include fastcgi_params;
        }

        location ~ /\.(?!well-known).* {
            deny all;
        }
    }
}
```

## Supervisor Config

```ini
# docker/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:php-fpm]
command=/usr/local/sbin/php-fpm -F
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:horizon]
command=php /var/www/artisan horizon
autostart=true
autorestart=true
user=www-data
stdout_logfile=/var/log/horizon.log
stderr_logfile=/var/log/horizon.log
```

## PHP OPcache Config

```ini
# docker/opcache.ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=64
opcache.max_accelerated_files=32531
opcache.validate_timestamps=0
opcache.save_comments=1
opcache.fast_shutdown=0
```

## Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      target: production
    ports:
      - "80:80"
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
    depends_on:
      - mysql
      - redis
    networks:
      - app-network
    volumes:
      - ./storage/app:/var/www/storage/app
      - ./storage/logs:/var/www/storage/logs

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: secret
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - app-network

  redis:
    image: redis:alpine
    networks:
      - app-network

  scheduler:
    build:
      context: .
      target: production
    command: sh -c "while true; do php /var/www/artisan schedule:run --verbose --no-interaction & sleep 60; done"
    depends_on:
      - mysql
      - redis
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  mysql-data:
```

## Bref (AWS Lambda)

```yaml
# serverless.yml
service: your-app

provider:
    name: aws
    region: us-east-1
    runtime: provided.al2
    environment:
        APP_ENV: production
        APP_DEBUG: false
        CACHE_DRIVER: dynamodb
        SESSION_DRIVER: dynamodb
        QUEUE_CONNECTION: sqs
        LOG_CHANNEL: stderr
        FILESYSTEM_DISK: s3
        DYNAMODB_CACHE_TABLE: !Ref CacheTable
        SQS_QUEUE: !Ref Queue

plugins:
    - ./vendor/bref/bref

functions:
    web:
        handler: public/index.php
        runtime: php-83-fpm
        timeout: 28
        events:
            - httpApi: '*'
        vpc:
            securityGroupIds:
                - !Ref LambdaSecurityGroup
            subnetIds:
                - subnet-xxx

    artisan:
        handler: artisan
        runtime: php-83-console
        timeout: 720

    worker:
        handler: Bref\LaravelBridge\Queue\QueueHandler
        runtime: php-83
        timeout: 60
        events:
            - sqs:
                arn: !GetAtt Queue.Arn
                batchSize: 1

resources:
    Resources:
        Queue:
            Type: AWS::SQS::Queue
            Properties:
                QueueName: ${self:service}-${sls:stage}-queue
                VisibilityTimeout: 70

        CacheTable:
            Type: AWS::DynamoDB::Table
            Properties:
                TableName: ${self:service}-${sls:stage}-cache
                BillingMode: PAY_PER_REQUEST
                AttributeDefinitions:
                    - AttributeName: key
                      AttributeType: S
                KeySchema:
                    - AttributeName: key
                      KeyType: HASH
                TimeToLiveSpecification:
                    AttributeName: expires_at
                    Enabled: true

package:
    patterns:
        - '!node_modules/**'
        - '!tests/**'
        - '!storage/**'
        - 'storage/framework/views/**'
```
