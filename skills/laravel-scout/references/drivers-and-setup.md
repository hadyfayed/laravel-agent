# Laravel Scout Drivers and Setup Reference

## Quick Start

```bash
# Install Scout
composer require laravel/scout

# Publish configuration
php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"

# For Algolia
composer require algolia/algoliasearch-client-php

# For Meilisearch
composer require meilisearch/meilisearch-php http-interop/http-factory-guzzle
```

## Driver Selection

| Driver | Best For |
|--------|----------|
| Meilisearch | Self-hosted, typo-tolerant, fast setup |
| Algolia | Managed service, analytics, recommendations |
| Typesense | Self-hosted, fast, typo-tolerant |
| Database | Simple cases, no external dependency |

## Installation

### Algolia Setup

```bash
# Install Scout and Algolia
composer require laravel/scout algolia/algoliasearch-client-php

# Publish config
php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"
```

```env
# .env
SCOUT_DRIVER=algolia
ALGOLIA_APP_ID=your-app-id
ALGOLIA_SECRET=your-admin-api-key
```

```php
<?php

// config/scout.php
return [
    'driver' => env('SCOUT_DRIVER', 'algolia'),

    'algolia' => [
        'id' => env('ALGOLIA_APP_ID'),
        'secret' => env('ALGOLIA_SECRET'),
    ],

    'queue' => true, // Queue indexing operations
    'chunk' => [
        'searchable' => 500,
        'unsearchable' => 500,
    ],
];
```

### Meilisearch Setup

```bash
# Install Scout and Meilisearch
composer require laravel/scout meilisearch/meilisearch-php http-interop/http-factory-guzzle

# Run Meilisearch (Docker)
docker run -d -p 7700:7700 getmeili/meilisearch:latest
```

```env
# .env
SCOUT_DRIVER=meilisearch
MEILISEARCH_HOST=http://localhost:7700
MEILISEARCH_KEY=your-master-key
```

```php
<?php

// config/scout.php
return [
    'driver' => env('SCOUT_DRIVER', 'meilisearch'),

    'meilisearch' => [
        'host' => env('MEILISEARCH_HOST', 'http://localhost:7700'),
        'key' => env('MEILISEARCH_KEY'),
        'index-settings' => [
            'posts' => [
                'filterableAttributes' => ['status', 'category_id'],
                'sortableAttributes' => ['created_at'],
                'rankingRules' => [
                    'words',
                    'typo',
                    'proximity',
                    'attribute',
                    'sort',
                    'exactness',
                ],
            ],
        ],
    ],
];
```

### Meilisearch Configuration (extended)

```php
<?php

// config/scout.php
return [
    'driver' => env('SCOUT_DRIVER', 'meilisearch'),

    'queue' => env('SCOUT_QUEUE', true),

    'after_commit' => true,

    'chunk' => [
        'searchable' => 500,
        'unsearchable' => 500,
    ],

    'soft_delete' => true,

    'meilisearch' => [
        'host' => env('MEILISEARCH_HOST', 'http://127.0.0.1:7700'),
        'key' => env('MEILISEARCH_KEY'),
        'index-settings' => [
            Product::class => [
                'filterableAttributes' => [
                    'category_name',
                    'brand_name',
                    'in_stock',
                    'price',
                    'rating',
                ],
                'sortableAttributes' => [
                    'price',
                    'rating',
                    'created_at',
                    'name',
                ],
                'searchableAttributes' => [
                    'name',
                    'description',
                    'sku',
                    'category_name',
                    'brand_name',
                    'tags',
                ],
                'rankingRules' => [
                    'words',
                    'typo',
                    'proximity',
                    'attribute',
                    'sort',
                    'exactness',
                    'rating:desc',
                ],
                'typoTolerance' => [
                    'enabled' => true,
                    'minWordSizeForTypos' => [
                        'oneTypo' => 4,
                        'twoTypos' => 8,
                    ],
                ],
                'pagination' => [
                    'maxTotalHits' => 10000,
                ],
            ],
        ],
    ],
];
```

### Database Driver (Simple Setup)

```env
# .env
SCOUT_DRIVER=database
```

```php
<?php

// config/scout.php
return [
    'driver' => env('SCOUT_DRIVER', 'database'),
];
```

## Queue Configuration

### Enable Queueing

```php
<?php

// config/scout.php
return [
    'queue' => true,

    'chunk' => [
        'searchable' => 500,
        'unsearchable' => 500,
    ],
];
```

### Custom Queue Connection

```php
<?php

namespace App\Models;

use Illuminate\Contracts\Queue\ShouldQueue;

class Post extends Model implements ShouldQueue
{
    use Searchable;

    /**
     * Get the queue connection for Scout.
     */
    public function syncWithSearchUsing(): string
    {
        return 'scout';
    }

    /**
     * Get the queue for Scout jobs.
     */
    public function syncWithSearchUsingQueue(): string
    {
        return 'search-indexing';
    }
}
```

### Monitor Indexing Jobs

```bash
# View queue status
php artisan queue:work

# Monitor failed jobs
php artisan queue:failed

# Retry failed jobs
php artisan queue:retry all
```

## Indexing Commands

```bash
# Import all records
php artisan scout:import "App\Models\Post"

# Import with progress
php artisan scout:import "App\Models\Product" --chunk=100

# Import multiple models
php artisan scout:import "App\Models\Post"
php artisan scout:import "App\Models\Product"

# Flush index
php artisan scout:flush "App\Models\Post"

# Sync index settings (Meilisearch)
php artisan scout:sync-index-settings

# Delete index
php artisan scout:delete-index products_production
```

## Soft Deletes Handling

### Keep Soft Deleted Records

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Scout\Searchable;

class Post extends Model
{
    use SoftDeletes, Searchable;

    /**
     * Determine if the model should be searchable when trashed.
     */
    public function shouldBeSearchable(): bool
    {
        // Keep in index even when soft deleted
        return true;
    }

    /**
     * Include trashed status in search data.
     */
    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'trashed' => $this->trashed(),
        ];
    }
}
```

### Exclude Soft Deleted Records

```php
<?php

class Post extends Model
{
    use SoftDeletes, Searchable;

    public function shouldBeSearchable(): bool
    {
        // Remove from index when soft deleted
        return !$this->trashed();
    }
}

// Search will automatically exclude soft deleted
$posts = Post::search('laravel')->get();

// Include soft deleted in search
$posts = Post::search('laravel')
    ->query(fn ($builder) => $builder->withTrashed())
    ->get();
```

## Database Driver Usage (Simple Cases)

### Configuration

```php
<?php

// config/scout.php
return [
    'driver' => env('SCOUT_DRIVER', 'database'),
];
```

### Usage (Same API)

```php
<?php

// All Scout features work with database driver
$posts = Post::search('laravel')->get();

// Performance considerations
$posts = Post::search('laravel')
    ->take(50) // Limit results
    ->get();

// Database driver uses LIKE queries
// Less powerful than Algolia/Meilisearch
// Good for: small datasets, simple searches
// Not good for: typo tolerance, faceting, relevance ranking
```
