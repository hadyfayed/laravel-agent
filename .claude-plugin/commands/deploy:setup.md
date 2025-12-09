---
description: "Configure deployment for your Laravel application"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /deploy:setup - Deployment Configuration Wizard

Interactive wizard to set up deployment configuration.

## Input
$ARGUMENTS = `[platform]`

Options:
- `/deploy:setup` - Interactive wizard
- `/deploy:setup forge` - Laravel Forge setup
- `/deploy:setup vapor` - Laravel Vapor setup
- `/deploy:setup docker` - Docker containerization
- `/deploy:setup bref` - AWS Lambda with Bref

## Process

1. **Check Environment**
   ```bash
   composer show laravel/vapor-core 2>/dev/null && echo "VAPOR=yes" || echo "VAPOR=no"
   composer show bref/laravel-bridge 2>/dev/null && echo "BREF=yes" || echo "BREF=no"
   ls -la Dockerfile 2>/dev/null && echo "DOCKER=exists" || echo "DOCKER=no"
   ls -la vapor.yml 2>/dev/null && echo "VAPOR_CONFIG=exists" || echo "VAPOR_CONFIG=no"
   ```

2. **Platform Selection** (if not specified)
   ```
   Which deployment platform do you want to use?
   - Forge: Traditional VPS deployment (DigitalOcean, AWS EC2, etc.)
   - Vapor: Serverless on AWS Lambda (managed by Laravel)
   - Docker: Containerized deployment (ECS, Kubernetes, etc.)
   - Bref: Serverless on AWS Lambda (self-managed)
   - Traditional: Custom server deployment scripts
   ```

3. **Environment Selection**
   ```
   Which environment are you configuring?
   - Production
   - Staging
   - Both
   ```

4. **Services Required**
   ```
   What services does your app need?
   - [ ] MySQL/PostgreSQL database
   - [ ] Redis cache
   - [ ] Queue workers
   - [ ] Scheduled tasks
   - [ ] WebSockets (Pusher/Soketi)
   - [ ] File storage (S3)
   ```

5. **Invoke Deploy Agent**

   Use Task tool with subagent_type `laravel-deploy`:
   ```
   Configure deployment:

   Platform: <forge|vapor|docker|bref|traditional>
   Environment: <production|staging>
   Services: [database, redis, queue, scheduler, websockets, storage]
   Spec: <additional requirements>
   ```

6. **Report Results**
   ```markdown
   ## Deployment Configured: <Platform>

   ### Files Created/Modified
   - [ ] Dockerfile (if Docker)
   - [ ] docker-compose.yml (if Docker)
   - [ ] vapor.yml (if Vapor)
   - [ ] serverless.yml (if Bref)
   - [ ] deploy.sh (if traditional)
   - [ ] .env.example (updated)

   ### Required Secrets
   - APP_KEY
   - DB_PASSWORD
   - REDIS_PASSWORD
   - AWS_ACCESS_KEY_ID (if S3/Vapor/Bref)

   ### Deploy Command
   ```bash
   <platform-specific deploy command>
   ```

   ### Next Steps
   1. Set environment variables on deployment platform
   2. Configure SSL certificate
   3. Set up monitoring
   4. Configure backups
   ```

## Quick Presets

### Forge (`/deploy:setup forge`)
- Creates deployment script
- Configures Supervisor for Horizon
- Sets up SSL with Let's Encrypt
- Configures Nginx optimization

### Vapor (`/deploy:setup vapor`)
- Creates vapor.yml
- Installs vapor-core if missing
- Configures database, cache, storage
- Sets up queue workers

### Docker (`/deploy:setup docker`)
- Creates production Dockerfile
- Creates docker-compose.yml
- Configures Nginx and PHP-FPM
- Sets up multi-stage builds

### Bref (`/deploy:setup bref`)
- Creates serverless.yml
- Installs bref/laravel-bridge if missing
- Configures Lambda functions
- Sets up SQS for queues
