# GitHub Actions Pipelines

## CI Pipeline Template (.github/workflows/ci.yml)

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  tests:
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

      redis:
        image: redis:alpine
        ports:
          - 6379:6379
        options: --health-cmd="redis-cli ping" --health-interval=10s --health-timeout=5s --health-retries=3

    strategy:
      fail-fast: true
      matrix:
        php: ['8.2', '8.3']

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: dom, curl, libxml, mbstring, zip, pcntl, pdo, sqlite, pdo_mysql, bcmath, intl, gd, redis
          coverage: xdebug

      - name: Get Composer Cache Directory
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT

      - name: Cache Composer dependencies
        uses: actions/cache@v4
        with:
          path: ${{ steps.composer-cache.outputs.dir }}
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: ${{ runner.os }}-composer-

      - name: Install dependencies
        run: composer install --prefer-dist --no-interaction --no-progress

      - name: Prepare environment
        run: |
          cp .env.example .env
          php artisan key:generate

      - name: Run tests
        run: vendor/bin/pest --parallel --coverage --min=80
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: password
          REDIS_HOST: 127.0.0.1

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        if: matrix.php == '8.3'
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  lint:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'

      - name: Install dependencies
        run: composer install --prefer-dist --no-interaction --no-progress

      - name: Check code style
        run: vendor/bin/pint --test

  static-analysis:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'

      - name: Install dependencies
        run: composer install --prefer-dist --no-interaction --no-progress

      - name: Run Larastan
        run: ./vendor/bin/phpstan analyse --error-format=github

  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          tools: composer:v2

      - name: Security check
        run: composer audit

      - name: Check for exposed secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
```

## Deploy to Forge (.github/workflows/deploy.yml)

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [tests, lint, static-analysis, security]

    steps:
      - name: Deploy to Forge
        uses: jbrooksuk/laravel-forge-action@v1.0.4
        with:
          trigger_url: ${{ secrets.FORGE_DEPLOY_URL }}
```

## Deploy to Vapor (.github/workflows/deploy-vapor.yml)

```yaml
name: Deploy to Vapor

on:
  push:
    branches:
      - main
      - staging

jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [tests, lint]

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'

      - name: Install dependencies
        run: composer install --prefer-dist --no-interaction --no-progress --no-dev

      - name: Install Vapor CLI
        run: composer global require laravel/vapor-cli

      - name: Deploy to staging
        if: github.ref == 'refs/heads/staging'
        run: vapor deploy staging
        env:
          VAPOR_API_TOKEN: ${{ secrets.VAPOR_API_TOKEN }}

      - name: Deploy to production
        if: github.ref == 'refs/heads/main'
        run: vapor deploy production
        env:
          VAPOR_API_TOKEN: ${{ secrets.VAPOR_API_TOKEN }}
```

## Deploy with Docker (.github/workflows/deploy-docker.yml)

```yaml
name: Build and Deploy Docker

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=ref,event=branch

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/app
            docker compose pull
            docker compose up -d --remove-orphans
            docker system prune -f
```

## Branch Protection Rules

Settings > Branches > Branch protection rules

For main branch:
- Require a pull request before merging
- Require status checks to pass before merging
  - Required checks: tests, lint, static-analysis, security
- Require branches to be up to date before merging
- Require conversation resolution before merging
- Do not allow bypassing the above settings

## Required Secrets

| Secret | Description |
|--------|-------------|
| `CODECOV_TOKEN` | Code coverage reporting |
| `FORGE_DEPLOY_URL` | Forge deployment webhook |
| `VAPOR_API_TOKEN` | Laravel Vapor API token |
| `SSH_PRIVATE_KEY` | Server SSH key for Docker deploys |
| `SERVER_HOST` | Deployment server hostname |
| `SERVER_USER` | SSH user for deployment |
