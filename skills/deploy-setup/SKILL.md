---
name: deploy-setup
description: Configure deployment — Forge/Vapor/Docker, env/secrets, zero-downtime, deploy scripts; when setting up deployment.
disable-model-invocation: true
allowed-tools: Bash(composer require) Bash(composer show *) Bash(php artisan *) Read Write Edit
argument-hint: "[forge|vapor|docker|bref] [--with-db] [--with-cache] [--with-queue]"
---

## Environment

Deployment platform checks:
!`composer show laravel/vapor-core 2>/dev/null && echo "vapor=yes" || echo "vapor=no"; composer show bref/laravel-bridge 2>/dev/null && echo "bref=yes" || echo "bref=no"; ls -la Dockerfile 2>/dev/null && echo "docker=exists" || echo "docker=no"`

## Task

Configure deployment for Forge, Vapor, Docker, or Bref. `$ARGUMENTS` specifies the platform and optional service flags (database, cache, queue workers).

## Steps

1. **Select platform** (from argument or interactively):
   - `forge` — Traditional VPS (DigitalOcean, AWS EC2)
   - `vapor` — Serverless AWS Lambda (managed by Laravel)
   - `docker` — Containerized (ECS, Kubernetes)
   - `bref` — Serverless AWS Lambda (self-managed)

2. **Configure environment variables**:
   - Copy `.env.example` to `.env` on the deployment target
   - Set `APP_KEY`, `APP_DEBUG=false`, `LOG_CHANNEL`
   - Database: `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`
   - Cache: `CACHE_DRIVER`, `REDIS_HOST`, `REDIS_PASSWORD`
   - Queue: `QUEUE_DRIVER`, `REDIS_HOST`
   - S3 storage: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `AWS_BUCKET`

3. **Install platform-specific package** (if needed):
   ```bash
   composer require laravel/vapor        # Vapor
   composer require bref/laravel-bridge  # Bref
   ```

4. **Create platform config** (if deploying to Vapor/Bref):
   - Vapor: `vapor.yml` with environment, database, cache, storage config
   - Bref: `serverless.yml` with Lambda functions, RDS, SQS setup

5. **Create Dockerfile** (if deploying to Docker):
   - Multi-stage build for production
   - PHP-FPM + Nginx configuration
   - Production optimizations (no dev dependencies)

6. **Configure deployment script** (if using Forge/traditional):
   - `deploy.sh` for push-based deployments or webhook-triggered deploys
   - Supervisor config for Horizon queue workers
   - SSL/TLS via Let's Encrypt

7. **Set secrets on deployment platform**:
   - GitHub/GitLab: Repository secrets
   - Vapor Dashboard: Environment variables
   - AWS Secrets Manager: For Bref/Lambda
   - Forge: Site environment variables

8. **Test deployment**:
   ```bash
   # Vapor
   vapor deploy staging
   
   # Bref
   serverless deploy
   
   # Docker
   docker build -t app:latest . && docker run -it app:latest
   ```

## Deep references

Deployment platform specifics (Forge/Vapor/Docker/Bref, zero-downtime, env) are owned by the **laravel-deploy** skill — apply its conventions (it auto-loads as a reference).
