---
description: "Configure CI/CD pipeline for your Laravel application"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /cicd:setup - CI/CD Pipeline Setup Wizard

Interactive wizard to configure continuous integration and deployment.

## Input
$ARGUMENTS = `[platform]`

Options:
- `/cicd:setup` - Interactive wizard
- `/cicd:setup github` - GitHub Actions
- `/cicd:setup gitlab` - GitLab CI
- `/cicd:setup bitbucket` - Bitbucket Pipelines

## Process

1. **Check Environment**
   ```bash
   # Check testing tools
   composer show pestphp/pest 2>/dev/null && echo "PEST=yes" || echo "PEST=no"
   composer show larastan/larastan 2>/dev/null && echo "LARASTAN=yes" || echo "LARASTAN=no"
   composer show laravel/pint 2>/dev/null && echo "PINT=yes" || echo "PINT=no"

   # Check deployment tools
   composer show laravel/vapor-core 2>/dev/null && echo "VAPOR=yes" || echo "VAPOR=no"
   ls -la Dockerfile 2>/dev/null && echo "DOCKER=yes" || echo "DOCKER=no"
   ```

2. **Platform Selection** (if not specified)
   ```
   Which CI/CD platform are you using?
   - GitHub Actions
   - GitLab CI
   - Bitbucket Pipelines
   ```

3. **Feature Selection**
   ```
   What should the pipeline do?
   - [x] Run tests (Pest/PHPUnit)
   - [x] Code style (Pint)
   - [ ] Static analysis (Larastan)
   - [ ] Security scan (composer audit)
   - [ ] Code coverage (Codecov)
   - [ ] Auto-deploy to staging
   - [ ] Manual deploy to production
   ```

4. **Deploy Target** (if deployment selected)
   ```
   Where should the app be deployed?
   - Forge
   - Vapor
   - Docker (custom server)
   - Bref (AWS Lambda)
   - None (CI only)
   ```

5. **Invoke CI/CD Agent**

   Use Task tool with subagent_type `laravel-cicd`:
   ```
   Configure CI/CD pipeline:

   Platform: <github|gitlab|bitbucket>
   Features: [test, lint, security, deploy]
   DeployTarget: <forge|vapor|docker|bref|none>
   Environments: [staging, production]
   ```

6. **Report Results**
   ```markdown
   ## CI/CD Pipeline Configured: <Platform>

   ### Pipeline Stages
   1. Build - Install dependencies
   2. Test - Run Pest tests with MySQL/Redis
   3. Lint - Laravel Pint code style
   4. Security - Composer audit
   5. Deploy - <target> (staging auto, production manual)

   ### Files Created
   - .github/workflows/ci.yml
   - .github/workflows/deploy.yml

   ### Required Secrets
   Add these to your repository secrets:
   - [ ] FORGE_DEPLOY_URL (or VAPOR_API_TOKEN)
   - [ ] CODECOV_TOKEN (if coverage enabled)

   ### Branch Protection
   Configure these status checks as required:
   - tests
   - lint
   - security

   ### Test Run
   Create a PR to trigger the pipeline.
   ```

## Quick Presets

### GitHub (`/cicd:setup github`)
- Creates .github/workflows/ci.yml
- Matrix testing (PHP 8.2, 8.3)
- MySQL and Redis services
- Parallel lint and security jobs
- Optional Forge/Vapor deployment

### GitLab (`/cicd:setup gitlab`)
- Creates .gitlab-ci.yml
- Stages: build, test, lint, security, deploy
- Services for MySQL and Redis
- Environment-based deployments

### Bitbucket (`/cicd:setup bitbucket`)
- Creates bitbucket-pipelines.yml
- Pull request pipelines
- Branch-specific deployments
- Service containers
