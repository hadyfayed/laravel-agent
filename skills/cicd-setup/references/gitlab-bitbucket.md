# GitLab CI and Bitbucket Pipelines

## GitLab CI (.gitlab-ci.yml)

```yaml
stages:
  - build
  - test
  - lint
  - security
  - deploy

variables:
  MYSQL_ROOT_PASSWORD: password
  MYSQL_DATABASE: testing
  DB_HOST: mysql
  DB_USERNAME: root
  DB_PASSWORD: password
  REDIS_HOST: redis

.php-template: &php-template
  image: php:8.3-cli
  before_script:
    - apt-get update && apt-get install -y git unzip libzip-dev
    - docker-php-ext-install pdo_mysql zip
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    - composer install --prefer-dist --no-interaction --no-progress

build:
  stage: build
  <<: *php-template
  script:
    - cp .env.example .env
    - php artisan key:generate
  artifacts:
    paths:
      - vendor/
      - .env
    expire_in: 1 hour

test:
  stage: test
  <<: *php-template
  services:
    - mysql:8.0
    - redis:alpine
  script:
    - vendor/bin/pest --parallel
  coverage: '/^\s*Lines:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      junit: report.xml

lint:
  stage: lint
  <<: *php-template
  script:
    - vendor/bin/pint --test

phpstan:
  stage: lint
  <<: *php-template
  script:
    - vendor/bin/phpstan analyse
  allow_failure: true

security:
  stage: security
  <<: *php-template
  script:
    - composer audit

deploy_staging:
  stage: deploy
  image: alpine:latest
  rules:
    - if: $CI_COMMIT_BRANCH == "staging"
  script:
    - apk add --no-cache curl
    - curl -X POST "$FORGE_STAGING_WEBHOOK"
  environment:
    name: staging
    url: https://staging.yourapp.com

deploy_production:
  stage: deploy
  image: alpine:latest
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  script:
    - apk add --no-cache curl
    - curl -X POST "$FORGE_PRODUCTION_WEBHOOK"
  environment:
    name: production
    url: https://yourapp.com
  when: manual
```

## Bitbucket Pipelines (bitbucket-pipelines.yml)

```yaml
image: php:8.3-cli

definitions:
  services:
    mysql:
      image: mysql:8.0
      environment:
        MYSQL_ROOT_PASSWORD: password
        MYSQL_DATABASE: testing
    redis:
      image: redis:alpine

  caches:
    composer: ~/.composer/cache

  steps:
    - step: &install
        name: Install dependencies
        caches:
          - composer
        script:
          - apt-get update && apt-get install -y git unzip libzip-dev
          - docker-php-ext-install pdo_mysql zip
          - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
          - composer install --prefer-dist --no-interaction
          - cp .env.example .env
          - php artisan key:generate
        artifacts:
          - vendor/**
          - .env

    - step: &test
        name: Run tests
        services:
          - mysql
          - redis
        script:
          - vendor/bin/pest --parallel
        artifacts:
          - storage/logs/**

    - step: &lint
        name: Code style
        script:
          - vendor/bin/pint --test

    - step: &security
        name: Security audit
        script:
          - composer audit

pipelines:
  pull-requests:
    '**':
      - step: *install
      - parallel:
          - step: *test
          - step: *lint
          - step: *security

  branches:
    main:
      - step: *install
      - parallel:
          - step: *test
          - step: *lint
          - step: *security
      - step:
          name: Deploy to production
          deployment: production
          trigger: manual
          script:
            - curl -X POST "$FORGE_PRODUCTION_WEBHOOK"

    staging:
      - step: *install
      - parallel:
          - step: *test
          - step: *lint
      - step:
          name: Deploy to staging
          deployment: staging
          script:
            - curl -X POST "$FORGE_STAGING_WEBHOOK"
```

## GitLab Protected Branches

Settings > Repository > Protected branches

For main branch:
- Access levels: Maintainers
- Require code owners approval (if .gitlab/CODEOWNERS exists)

## Bitbucket Repository Settings

Repository settings > Branch permissions

For main branch:
- Restrict merges to specific groups
- Require minimum reviewers (e.g., 1 approval)
- Require all status checks to pass

## Environment Variables

### GitHub
Settings > Secrets and variables > Actions > Repository secrets

### GitLab
Settings > CI/CD > Variables

### Bitbucket
Repository settings > Repository variables (or workspace variables for shared secrets)

Variables needed:
- `FORGE_STAGING_WEBHOOK`
- `FORGE_PRODUCTION_WEBHOOK`
- `CODECOV_TOKEN` (if coverage enabled)
