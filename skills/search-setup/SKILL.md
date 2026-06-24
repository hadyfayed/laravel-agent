---
name: search-setup
description: Set up full-text search with Laravel Scout — install and configure Algolia, Meilisearch, Typesense, or database driver; mark models as searchable; index data. Triggers: "search", "Scout", "full-text search", "when adding search".
disable-model-invocation: true
allowed-tools: Bash(composer *) Bash(php artisan *) Read Write Edit
argument-hint: "[--driver=<meilisearch|algolia|typesense|database>] [--models=<Model1,Model2>]"
---

## Environment

!`composer show laravel/scout 2>/dev/null && echo "scout=installed" || echo "scout=missing"`

## Task

Configure Laravel Scout with your chosen search driver. Optionally specify `--driver` and `--models` via `$ARGUMENTS`; if omitted, run interactively.

## Steps

### 1. Install Scout (if not present)

```bash
composer require laravel/scout
php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"
```

### 2. Install Driver

Based on `$ARGUMENTS` or interactive choice:

**Meilisearch** (recommended; free, self-hosted):
```bash
composer require meilisearch/meilisearch-php
```

**Algolia** (hosted, pay-per-search):
```bash
composer require algolia/algoliasearch-client-php
```

**Typesense** (free, self-hosted):
```bash
composer require typesense/typesense-php typesense/laravel-scout-typesense-driver
```

**Database** (simple fallback, no external service):
```bash
# No additional package needed.
```

### 3. Configure Environment Variables

```env
SCOUT_DRIVER=meilisearch
SCOUT_QUEUE=true
SCOUT_PREFIX=prod_

# Meilisearch
MEILISEARCH_HOST=http://localhost:7700
MEILISEARCH_KEY=your-master-key

# OR Algolia
ALGOLIA_APP_ID=your-app-id
ALGOLIA_SECRET=your-admin-api-key

# OR Typesense
TYPESENSE_API_KEY=your-api-key
TYPESENSE_HOST=localhost
TYPESENSE_PORT=8108
```

### 4. Configure Models

For each model in `--models`, add the `Searchable` trait:

```php
<?php
declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Laravel\Scout\Searchable;

final class Product extends Model
{
    use Searchable;

    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            // ... other fields
        ];
    }

    public function searchableAs(): string
    {
        return 'products';  // index name
    }

    public function shouldBeSearchable(): bool
    {
        return $this->status === 'active';
    }
}
```

### 5. Index Existing Data

```bash
php artisan scout:import "App\Models\Product"
php artisan scout:sync-index-settings   # Meilisearch / Typesense
```

## Configuration Reference

See the **laravel-scout** reference skill for detailed driver configuration, model setup conventions, and search patterns.

## Output

Report installed packages, environment keys required, models configured, and commands to run.

## Commands

```bash
# Index models
php artisan scout:import "App\Models\Product"

# Clear and re-index
php artisan scout:flush "App\Models\Product"

# Sync settings (Meilisearch/Typesense)
php artisan scout:sync-index-settings
```
