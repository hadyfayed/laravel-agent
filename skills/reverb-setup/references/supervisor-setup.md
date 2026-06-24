# Supervisor Configuration for Reverb

## Installation

```bash
# macOS
brew install supervisor

# Ubuntu/Debian
sudo apt-get install supervisor

# CentOS/RHEL
sudo yum install supervisor
```

## Basic Configuration

Create `/etc/supervisor/conf.d/reverb.conf`:

```ini
[program:laravel-reverb]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/laravel/artisan reverb:start --host=0.0.0.0 --port=8080
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/reverb.log
user=www-data
environment=LARAVEL_ENV="production"
```

## Multi-Process Setup

For high-traffic applications, run multiple Reverb processes:

```ini
[program:laravel-reverb]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/laravel/artisan reverb:start --host=0.0.0.0 --port=808%(process_num)d
autostart=true
autorestart=true
numprocs=4
redirect_stderr=true
stdout_logfile=/var/log/reverb_%(process_num)02d.log
user=www-data
environment=LARAVEL_ENV="production"
```

Use ports 8080, 8081, 8082, 8083 with load balancing.

## Load Balancing with Nginx

```nginx
upstream reverb {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
    server 127.0.0.1:8083;
}

server {
    listen 80;
    server_name your-domain.com;

    location /app {
        proxy_pass http://reverb;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Management

```bash
# Read config
sudo supervisorctl reread

# Update programs
sudo supervisorctl update

# Start Reverb
sudo supervisorctl start laravel-reverb:*

# Stop Reverb
sudo supervisorctl stop laravel-reverb:*

# Restart Reverb
sudo supervisorctl restart laravel-reverb:*

# View status
sudo supervisorctl status

# View logs
sudo tail -f /var/log/reverb.log
```

## Redis Scaling

For multiple servers with Redis scaling:

```ini
[program:laravel-reverb]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/laravel/artisan reverb:start --host=0.0.0.0 --port=808%(process_num)d
autostart=true
autorestart=true
numprocs=4
redirect_stderr=true
stdout_logfile=/var/log/reverb_%(process_num)02d.log
user=www-data
environment=LARAVEL_ENV="production",REVERB_REDIS_HOST="redis.example.com"
```

Ensure `config/reverb.php` has Redis scaling enabled:

```php
'scaling' => [
    'enabled' => true,
    'redis' => [
        'connection' => env('REVERB_REDIS_CONNECTION'),
    ],
],
```

## Health Check

Add a health check endpoint to verify Reverb is running:

```bash
# Test WebSocket connection
php artisan reverb:publish --channel=test --event='TestEvent' --data='{"message":"Hello"}'

# Or curl for status
curl -i http://localhost:8080/
```

## Troubleshooting

### Process keeps restarting

Check logs:
```bash
sudo tail -100 /var/log/reverb.log
```

Ensure Laravel app is properly configured and `.env` is accessible.

### WebSocket connections failing

Verify Nginx proxy headers:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### High memory usage

Monitor with:
```bash
sudo supervisorctl status laravel-reverb:*
ps aux | grep reverb
```

Reduce `--port` or increase server resources.

## Systemd Alternative

Create `/etc/systemd/system/reverb.service`:

```ini
[Unit]
Description=Laravel Reverb WebSocket Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/php /path/to/laravel/artisan reverb:start --host=0.0.0.0 --port=8080
Restart=always
RestartSec=5
User=www-data
WorkingDirectory=/path/to/laravel

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable reverb
sudo systemctl start reverb
sudo systemctl status reverb
```
