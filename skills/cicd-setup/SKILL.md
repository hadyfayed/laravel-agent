---
name: cicd-setup
description: Set up CI/CD pipelines (GitHub Actions/GitLab/Bitbucket) — tests, linting, security scan, deploy stages; when configuring CI/CD.
disable-model-invocation: true
allowed-tools: Bash(composer show *) Bash(php artisan *) Read Write Edit
argument-hint: "[github|gitlab|bitbucket] [--with-deploy] [--with-security] [--with-coverage]"
---

## Environment

Installed testing/CI tools:
!`composer show pestphp/pest 2>/dev/null && echo "pest=yes" || echo "pest=no"; composer show phpunit/phpunit 2>/dev/null && echo "phpunit=yes" || echo "phpunit=no"; composer show larastan/larastan 2>/dev/null && echo "larastan=yes" || echo "larastan=no"; composer show laravel/pint 2>/dev/null && echo "pint=yes" || echo "pint=no"`

Existing CI configs:
!`ls -la .github/workflows/*.yml 2>/dev/null || echo "No GitHub Actions"; ls -la .gitlab-ci.yml 2>/dev/null || echo "No GitLab CI"; ls -la bitbucket-pipelines.yml 2>/dev/null || echo "No Bitbucket Pipelines"`

## Task

Wire up CI/CD pipelines for GitHub Actions, GitLab CI, or Bitbucket Pipelines. `$ARGUMENTS` specifies the platform and optional flags for deployment, security scanning, and coverage.

## Steps

1. **Select platform** (from argument or interactively):
   - `github` — GitHub Actions
   - `gitlab` — GitLab CI
   - `bitbucket` — Bitbucket Pipelines

2. **Create pipeline config file**:
   - GitHub: `.github/workflows/ci.yml` (+ optional `deploy.yml`)
   - GitLab: `.gitlab-ci.yml`
   - Bitbucket: `bitbucket-pipelines.yml`

3. **Configure pipeline stages**:
   - **Build**: Install dependencies, prepare environment
   - **Test**: Run Pest/PHPUnit with services (MySQL, Redis), parallel matrix (PHP 8.2, 8.3)
   - **Lint**: Laravel Pint code style check
   - **Security**: `composer audit` + optional secret scanning (TruffleHog)
   - **Static Analysis**: Larastan (optional)
   - **Deploy**: Forge/Vapor/Docker (optional, `--with-deploy` flag)

4. **Set up service containers**:
   - MySQL 8.0 (testing database)
   - Redis Alpine (cache)
   - Health checks to verify readiness

5. **Add environment variables** in GitHub/GitLab/Bitbucket settings:
   - `DB_CONNECTION`, `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`
   - `REDIS_HOST`
   - Deployment secrets: `FORGE_DEPLOY_URL`, `VAPOR_API_TOKEN`, `SSH_PRIVATE_KEY`
   - Coverage: `CODECOV_TOKEN` (optional)

6. **Configure branch protection** (GitHub):
   - Require PR before merge
   - Require status checks: tests, lint, security
   - Require up-to-date branches

7. **Test the pipeline** by creating a PR or pushing to a branch.

## Deep references

Pipeline templates per platform (GitHub Actions, GitLab CI, Bitbucket), deployment integrations (Forge, Vapor, Docker), and branch protection strategies: see `${CLAUDE_SKILL_DIR}/references/`.
