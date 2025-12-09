---
description: "Migrate from legacy systems or upgrade Laravel versions"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /migrate:from-legacy - Legacy System Migration

Migrate from legacy systems, other frameworks, or upgrade Laravel versions.

## Input
$ARGUMENTS = `<source> [target]`

Examples:
- `/migrate:from-legacy laravel-10` - Upgrade to latest Laravel
- `/migrate:from-legacy laravel-11 laravel-12` - Specific version upgrade
- `/migrate:from-legacy symfony` - Migrate from Symfony
- `/migrate:from-legacy codeigniter` - Migrate from CodeIgniter
- `/migrate:from-legacy php-8.1 php-8.3` - PHP version upgrade
- `/migrate:from-legacy database mysql postgres` - Database migration

## Process

1. **Analyze Current State**
   ```bash
   php -v
   php artisan --version
   composer show laravel/framework
   ```

2. **Identify Migration Type**
   - Laravel version upgrade
   - PHP version upgrade
   - Framework migration
   - Database migration

3. **Invoke Migration Agent**
   ```
   Perform migration:

   Action: <upgrade|migrate-framework|migrate-database>
   From: <source>
   To: <target>
   Focus: <specific areas>
   ```

4. **Report Results**
   ```markdown
   ## Migration: <Source> → <Target>

   ### Analysis
   - Current state: ...
   - Breaking changes: ...
   - Estimated effort: ...

   ### Steps Completed
   - [x] Dependencies updated
   - [x] Config migrated
   - [x] Code modernized
   - [x] Tests passing

   ### Manual Steps Required
   1. ...
   2. ...

   ### Validation
   ```bash
   vendor/bin/pest
   vendor/bin/phpstan analyse
   ```
   ```

## Migration Types

### Laravel Version (`/migrate:from-legacy laravel-10`)
- Updates composer.json
- Applies config changes
- Fixes deprecated methods
- Updates service providers
- Runs automated fixes with Rector

### PHP Version (`/migrate:from-legacy php-8.1 php-8.3`)
- Updates composer.json PHP requirement
- Adopts new language features
- Fixes deprecations
- Adds type declarations

### Framework Migration (`/migrate:from-legacy symfony`)
- Maps framework concepts
- Converts controllers
- Migrates models/entities
- Converts views/templates
- Migrates services

### Database Migration (`/migrate:from-legacy database mysql postgres`)
- Analyzes schema differences
- Creates migration scripts
- Handles data type conversions
- Migrates data safely
