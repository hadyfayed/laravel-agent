---
description: "Configure full-text search with Laravel Scout + Meilisearch/Algolia/Typesense"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /search:setup - Configure Full-Text Search

Setup Laravel Scout with your choice of search engine.

## Input
$ARGUMENTS = `[--driver=<meilisearch|algolia|typesense|database>] [--models=<Model1,Model2>]`

Examples:
- `/search:setup` - Interactive setup
- `/search:setup --driver=meilisearch`
- `/search:setup --driver=algolia --models=Product,Post`

## Process

1. **Install Scout**
   ```bash
   composer require laravel/scout
   php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"
   ```

2. **Install Search Driver**
   ```bash
   # Meilisearch (recommended - free, self-hosted)
   composer require meilisearch/meilisearch-php

   # Algolia (hosted, pay-per-search)
   composer require algolia/algoliasearch-client-php

   # Typesense (free, self-hosted)
   composer require typesense/typesense-php
   composer require typesense/laravel-scout-typesense-driver
   ```

3. **Configure Environment**

4. **Add Searchable Trait to Models**

5. **Import Existing Data**

## Configuration

### config/scout.php
```php
<?php

return [
    'driver' => env('SCOUT_DRIVER', 'meilisearch'),

    'prefix' => env('SCOUT_PREFIX', ''),

    'queue' => env('SCOUT_QUEUE', true),

    'after_commit' => true,

    'chunk' => [
        'searchable' => 500,
        'unsearchable' => 500,
    ],

    'soft_delete' => true,

    'identify' => env('SCOUT_IDENTIFY', false),

    // Meilisearch Configuration
    'meilisearch' => [
        'host' => env('MEILISEARCH_HOST', 'http://localhost:7700'),
        'key' => env('MEILISEARCH_KEY'),
        'index-settings' => [
            'products' => [
                'filterableAttributes' => ['category_id', 'brand_id', 'status', 'price'],
                'sortableAttributes' => ['price', 'created_at', 'name'],
                'searchableAttributes' => ['name', 'description', 'sku'],
            ],
            'posts' => [
                'filterableAttributes' => ['category_id', 'status', 'author_id'],
                'sortableAttributes' => ['published_at', 'title'],
                'searchableAttributes' => ['title', 'content', 'excerpt'],
            ],
        ],
    ],

    // Algolia Configuration
    'algolia' => [
        'id' => env('ALGOLIA_APP_ID', ''),
        'secret' => env('ALGOLIA_SECRET', ''),
    ],

    // Typesense Configuration
    'typesense' => [
        'api_key' => env('TYPESENSE_API_KEY', ''),
        'nodes' => [
            [
                'host' => env('TYPESENSE_HOST', 'localhost'),
                'port' => env('TYPESENSE_PORT', '8108'),
                'protocol' => env('TYPESENSE_PROTOCOL', 'http'),
            ],
        ],
        'nearest_node' => [
            'host' => env('TYPESENSE_HOST', 'localhost'),
            'port' => env('TYPESENSE_PORT', '8108'),
            'protocol' => env('TYPESENSE_PROTOCOL', 'http'),
        ],
        'connection_timeout_seconds' => 2,
        'healthcheck_interval_seconds' => 30,
        'num_retries' => 3,
        'retry_interval_seconds' => 1,
    ],
];
```

### Environment Variables
```env
# Scout
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

## Searchable Model

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Laravel\Scout\Searchable;

final class Product extends Model
{
    use Searchable;

    /**
     * Get the indexable data array for the model.
     */
    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'sku' => $this->sku,
            'price' => $this->price_cents / 100,
            'category_id' => $this->category_id,
            'brand_id' => $this->brand_id,
            'status' => $this->status,
            'created_at' => $this->created_at->timestamp,
        ];
    }

    /**
     * Get the name of the index.
     */
    public function searchableAs(): string
    {
        return 'products';
    }

    /**
     * Determine if the model should be searchable.
     */
    public function shouldBeSearchable(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Modify the query used for Scout search.
     */
    public function makeSearchableUsing($query)
    {
        return $query->with(['category', 'brand']);
    }
}
```

## Search Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

final class SearchController extends Controller
{
    public function search(Request $request)
    {
        $request->validate([
            'q' => 'required|string|min:2|max:100',
            'category' => 'nullable|integer',
            'min_price' => 'nullable|numeric|min:0',
            'max_price' => 'nullable|numeric|min:0',
            'sort' => 'nullable|in:relevance,price_asc,price_desc,newest',
        ]);

        $query = Product::search($request->input('q'));

        // Meilisearch filters
        if ($request->filled('category')) {
            $query->where('category_id', $request->integer('category'));
        }

        if ($request->filled('min_price')) {
            $query->where('price', '>=', $request->float('min_price'));
        }

        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->float('max_price'));
        }

        // Sorting
        match ($request->input('sort')) {
            'price_asc' => $query->orderBy('price', 'asc'),
            'price_desc' => $query->orderBy('price', 'desc'),
            'newest' => $query->orderBy('created_at', 'desc'),
            default => null, // relevance (default)
        };

        return $query->paginate(20);
    }

    /**
     * Instant search for autocomplete.
     */
    public function instant(Request $request)
    {
        $request->validate([
            'q' => 'required|string|min:1|max:50',
        ]);

        $results = Product::search($request->input('q'))
            ->take(5)
            ->get()
            ->map(fn ($product) => [
                'id' => $product->id,
                'name' => $product->name,
                'url' => route('products.show', $product),
                'image' => $product->thumbnail_url,
            ]);

        return response()->json(['results' => $results]);
    }
}
```

## Docker Compose (Meilisearch)

```yaml
# docker-compose.yml
services:
  meilisearch:
    image: getmeili/meilisearch:latest
    ports:
      - "7700:7700"
    volumes:
      - meilisearch-data:/meili_data
    environment:
      - MEILI_MASTER_KEY=your-master-key
      - MEILI_ENV=development

volumes:
  meilisearch-data:
```

## Commands

```bash
# Import all records
php artisan scout:import "App\Models\Product"

# Import with fresh index
php artisan scout:flush "App\Models\Product"
php artisan scout:import "App\Models\Product"

# Sync index settings (Meilisearch)
php artisan scout:sync-index-settings

# Queue all models for indexing
php artisan scout:import "App\Models\Product" --chunk=500
```

## Interactive Prompts

When run without arguments, prompt user for:

1. **Search engine?**
   - Meilisearch (recommended - free, self-hosted)
   - Algolia (hosted, pay-per-search)
   - Typesense (free, self-hosted)
   - Database (simple, no dependencies)

2. **Which models to make searchable?** (multi-select from existing models)
   - [x] Product
   - [x] Post
   - [ ] User
   - [ ] Order

3. **Queue indexing operations?**
   - Yes (recommended for production)
   - No (immediate, for development)

4. **Generate Docker Compose?** (for Meilisearch/Typesense)
   - Yes
   - No

## Output

```markdown
## Search Setup Complete

### Packages Installed
- laravel/scout
- meilisearch/meilisearch-php

### Driver: Meilisearch

### Models Configured
| Model | Index | Searchable Fields |
|-------|-------|-------------------|
| Product | products | name, description, sku |
| Post | posts | title, content, excerpt |

### Environment Variables
```env
SCOUT_DRIVER=meilisearch
MEILISEARCH_HOST=http://localhost:7700
MEILISEARCH_KEY=
```

### Files Created
- docker-compose.yml (Meilisearch service)
- app/Http/Controllers/SearchController.php

### Commands to Run
```bash
# Start Meilisearch
docker-compose up -d meilisearch

# Import existing data
php artisan scout:import "App\Models\Product"
php artisan scout:import "App\Models\Post"

# Sync index settings
php artisan scout:sync-index-settings
```

### Search Usage
```php
// Basic search
Product::search('laptop')->get();

// With filters
Product::search('laptop')
    ->where('category_id', 5)
    ->where('price', '<=', 1000)
    ->get();
```

### Next Steps
1. Start Meilisearch with `docker-compose up -d`
2. Add MEILISEARCH_KEY to .env
3. Import existing records
4. Test search at /search?q=test
```
