---
name: laravel-scout
description: >
  Implement full-text search with Laravel Scout. Use when the user needs search functionality,
  Algolia, Meilisearch, database search, or searchable models.
  Triggers: "scout", "search", "algolia", "meilisearch", "full-text", "searchable",
  "elasticsearch", "typesense".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Scout Skill

Implement powerful full-text search with Laravel Scout using Algolia, Meilisearch, or database drivers.

## When to Use

- Full-text search across models
- Instant search with Algolia or Meilisearch
- Faceted search and filtering
- Typo-tolerant search
- Search result ranking and relevance
- Geo-search capabilities
- Simple database-based search for smaller apps
- Search-as-you-type functionality

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

## Making Models Searchable

### Basic Searchable Model

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Laravel\Scout\Searchable;

class Post extends Model
{
    use Searchable;

    /**
     * Get the indexable data array for the model.
     */
    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'content' => $this->content,
            'excerpt' => $this->excerpt,
            'author' => $this->author->name,
            'status' => $this->status,
            'created_at' => $this->created_at->timestamp,
        ];
    }
}
```

### Conditional Indexing

```php
<?php

class Post extends Model
{
    use Searchable;

    /**
     * Determine if the model should be searchable.
     */
    public function shouldBeSearchable(): bool
    {
        return $this->status === 'published';
    }

    /**
     * Get the value used to index the model.
     */
    public function getScoutKey(): mixed
    {
        return $this->id;
    }

    /**
     * Get the key name used to index the model.
     */
    public function getScoutKeyName(): string
    {
        return 'id';
    }
}
```

### Customizing Index Name

```php
<?php

class Post extends Model
{
    use Searchable;

    /**
     * Get the name of the index associated with the model.
     */
    public function searchableAs(): string
    {
        return 'posts_' . config('app.env');
    }
}
```

### Relationships in Search

```php
<?php

class Post extends Model
{
    use Searchable;

    public function toSearchableArray(): array
    {
        $array = $this->toArray();

        // Load relationships for search
        $array['author'] = $this->author->only(['id', 'name', 'email']);
        $array['categories'] = $this->categories->pluck('name')->toArray();
        $array['tags'] = $this->tags->pluck('slug')->toArray();

        return $array;
    }
}
```

## Indexing

### Import All Records

```bash
# Import all posts
php artisan scout:import "App\Models\Post"

# Import multiple models
php artisan scout:import "App\Models\Post"
php artisan scout:import "App\Models\Product"
```

### Programmatic Indexing

```php
<?php

// Index single model
$post = Post::find(1);
$post->searchable();

// Index collection
$posts = Post::where('status', 'published')->get();
$posts->searchable();

// Queue indexing (for large datasets)
$posts = Post::where('status', 'published')->get();
$posts->searchable();

// Chunk indexing for memory efficiency
Post::where('status', 'published')
    ->chunk(100, function ($posts) {
        $posts->searchable();
    });
```

### Removing from Index

```php
<?php

// Remove single model
$post->unsearchable();

// Remove collection
$posts->unsearchable();

// Flush entire index
php artisan scout:flush "App\Models\Post"
```

### Model Observers (Automatic Indexing)

```php
<?php

// Scout automatically indexes on:
// - created
// - updated
// - deleted (if not using soft deletes)

$post = Post::create([
    'title' => 'New Post',
    'content' => 'Content here',
]); // Automatically indexed

$post->update(['title' => 'Updated']); // Re-indexed

$post->delete(); // Removed from index
```

### Pausing Indexing

```php
<?php

use Laravel\Scout\Facades\Scout;

// Temporarily disable indexing
Scout::withoutSyncingToSearch(function () {
    Post::factory()->count(100)->create();
});

// Or on specific operations
$post->withoutSyncingToSearch(function () use ($post) {
    $post->update(['title' => 'New Title']);
});
```

## Searching

### Basic Search

```php
<?php

// Simple search
$posts = Post::search('laravel')->get();

// Search with pagination
$posts = Post::search('laravel')->paginate(15);

// Get specific attributes
$posts = Post::search('laravel')->get(['id', 'title']);

// Count results
$count = Post::search('laravel')->count();

// Get first result
$post = Post::search('laravel')->first();
```

### Search with Constraints

```php
<?php

// Where clauses (requires filterable attributes)
$posts = Post::search('laravel')
    ->where('status', 'published')
    ->get();

// Multiple constraints
$posts = Post::search('laravel')
    ->where('status', 'published')
    ->where('category_id', 5)
    ->get();

// WhereIn
$posts = Post::search('laravel')
    ->whereIn('category_id', [1, 2, 3])
    ->get();

// Order by
$posts = Post::search('laravel')
    ->orderBy('created_at', 'desc')
    ->get();
```

### Advanced Search Options

```php
<?php

// Custom query callback
$posts = Post::search('laravel', function ($algolia, $query, $options) {
    $options['hitsPerPage'] = 20;
    $options['facets'] = ['status', 'category'];
    $options['filters'] = 'status:published AND category_id:5';

    return $algolia->search($query, $options);
})->get();

// Meilisearch custom options
$posts = Post::search('laravel', function ($meilisearch, $query, $options) {
    $options['attributesToHighlight'] = ['title', 'content'];
    $options['attributesToCrop'] = ['content:50'];

    return $meilisearch->search($query, $options);
})->get();
```

### Empty Search (Get All)

```php
<?php

// Search with empty query (returns all)
$posts = Post::search('')->get();

// With filters
$posts = Post::search('')
    ->where('status', 'published')
    ->orderBy('created_at', 'desc')
    ->paginate(15);
```

### Combining with Eloquent

```php
<?php

// Search then apply Eloquent
$posts = Post::search('laravel')
    ->query(fn ($builder) => $builder->with(['author', 'categories']))
    ->get();

// More complex queries
$posts = Post::search('laravel')
    ->query(function ($builder) {
        $builder->with(['author', 'categories'])
            ->withCount('comments')
            ->orderBy('views', 'desc');
    })
    ->paginate(15);
```

## Customizing Indexes

### Algolia Index Settings

```php
<?php

namespace App\Models;

class Post extends Model
{
    use Searchable;

    /**
     * Configure Algolia index settings.
     */
    public function syncWithSearchUsing()
    {
        return [
            'attributesToSnippet' => ['content:50'],
            'snippetEllipsisText' => '…',
            'attributesToHighlight' => ['title', 'content'],
            'highlightPreTag' => '<strong>',
            'highlightPostTag' => '</strong>',
        ];
    }
}
```

### Meilisearch Filterable Attributes

```php
<?php

// Configure in config/scout.php
'meilisearch' => [
    'host' => env('MEILISEARCH_HOST'),
    'key' => env('MEILISEARCH_KEY'),
    'index-settings' => [
        'posts' => [
            'filterableAttributes' => ['status', 'category_id', 'author_id'],
            'sortableAttributes' => ['created_at', 'views', 'likes'],
            'searchableAttributes' => ['title', 'content', 'excerpt'],
            'displayedAttributes' => ['*'],
            'rankingRules' => [
                'words',
                'typo',
                'proximity',
                'attribute',
                'sort',
                'exactness',
                'created_at:desc',
            ],
        ],
    ],
],
```

### Creating Custom Indexes

```bash
# Create index with settings via Artisan
php artisan scout:sync-index-settings
```

```php
<?php

// Programmatically configure index
use Algolia\AlgoliaSearch\SearchClient;

$client = SearchClient::create(
    config('scout.algolia.id'),
    config('scout.algolia.secret')
);

$index = $client->initIndex('posts');

$index->setSettings([
    'searchableAttributes' => [
        'title',
        'content',
        'excerpt',
    ],
    'attributesForFaceting' => [
        'searchable(status)',
        'searchable(category)',
    ],
    'customRanking' => [
        'desc(views)',
        'desc(created_at)',
    ],
]);
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

## Database Driver (Simple Cases)

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

### Search Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function __invoke(Request $request)
    {
        $query = $request->input('q', '');
        $status = $request->input('status');
        $category = $request->input('category');

        $posts = Post::search($query)
            ->when($status, fn ($builder) => $builder->where('status', $status))
            ->when($category, fn ($builder) => $builder->where('category_id', $category))
            ->query(fn ($builder) => $builder->with(['author', 'categories']))
            ->paginate(15)
            ->withQueryString();

        if ($request->wantsJson()) {
            return PostResource::collection($posts);
        }

        return view('search.results', compact('posts', 'query'));
    }
}
```

### API Search Endpoint

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function posts(Request $request)
    {
        $validated = $request->validate([
            'q' => ['sometimes', 'string', 'max:255'],
            'status' => ['sometimes', 'in:draft,published'],
            'category_id' => ['sometimes', 'exists:categories,id'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ]);

        $query = $validated['q'] ?? '';
        $perPage = $validated['per_page'] ?? 15;

        $posts = Post::search($query)
            ->when(
                isset($validated['status']),
                fn ($builder) => $builder->where('status', $validated['status'])
            )
            ->when(
                isset($validated['category_id']),
                fn ($builder) => $builder->where('category_id', $validated['category_id'])
            )
            ->query(fn ($builder) => $builder->with(['author', 'categories']))
            ->paginate($perPage);

        return PostResource::collection($posts);
    }
}
```

## Testing

### Fake Search Results

```php
<?php

use App\Models\Post;
use Laravel\Scout\Facades\Scout;

it('searches posts', function () {
    // Disable Scout temporarily
    Scout::fake();

    $post = Post::factory()->create(['title' => 'Laravel Scout']);

    // Perform search
    $results = Post::search('Laravel')->get();

    // Assert model was indexed
    Scout::assertIndexed($post);
});

it('removes post from search index', function () {
    Scout::fake();

    $post = Post::factory()->create();
    $post->delete();

    Scout::assertNotIndexed($post);
});

it('updates search index on model update', function () {
    Scout::fake();

    $post = Post::factory()->create(['title' => 'Original']);
    $post->update(['title' => 'Updated']);

    Scout::assertIndexed($post);
});
```

### Testing Search Functionality

```php
<?php

use App\Models\Post;

beforeEach(function () {
    // Import posts to search index for tests
    Post::factory()->count(10)->create()->searchable();
});

it('returns search results', function () {
    $response = $this->getJson('/api/search?q=Laravel');

    $response->assertOk()
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'title', 'content'],
            ],
        ]);
});

it('filters search by status', function () {
    $response = $this->getJson('/api/search?q=Laravel&status=published');

    $response->assertOk();

    foreach ($response->json('data') as $post) {
        expect($post['status'])->toBe('published');
    }
});

it('paginates search results', function () {
    $response = $this->getJson('/api/search?q=Laravel&per_page=5');

    $response->assertOk()
        ->assertJsonCount(5, 'data');
});
```

### Integration Testing

```php
<?php

use App\Models\Post;

it('indexes and searches posts', function () {
    // Create post
    $post = Post::factory()->create([
        'title' => 'Laravel Scout Tutorial',
        'status' => 'published',
    ]);

    // Wait for indexing (Algolia/Meilisearch)
    sleep(1);

    // Search
    $results = Post::search('Scout')->get();

    expect($results)->toHaveCount(1);
    expect($results->first()->id)->toBe($post->id);
});

it('removes deleted posts from search', function () {
    $post = Post::factory()->create(['title' => 'Laravel Scout']);

    sleep(1);

    $post->delete();

    sleep(1);

    $results = Post::search('Scout')->get();

    expect($results)->toHaveCount(0);
});
```

## Common Pitfalls

1. **Forgetting to Import Existing Records**
   ```bash
   # Always import existing records after setup
   php artisan scout:import "App\Models\Post"
   ```

2. **Not Configuring Filterable Attributes**
   ```php
   // Meilisearch: Must configure filterable attributes
   // config/scout.php
   'index-settings' => [
       'posts' => [
           'filterableAttributes' => ['status', 'category_id'],
       ],
   ],

   // Then sync settings
   php artisan scout:sync-index-settings
   ```

3. **Indexing Sensitive Data**
   ```php
   // Never index passwords or sensitive data
   public function toSearchableArray(): array
   {
       return [
           'id' => $this->id,
           'name' => $this->name,
           'email' => $this->email,
           // NEVER include: password, tokens, secrets
       ];
   }
   ```

4. **Not Handling Large Datasets**
   ```php
   // Use chunking for large imports
   Post::chunk(500, function ($posts) {
       $posts->searchable();
   });

   // Enable queuing
   // config/scout.php
   'queue' => true,
   ```

5. **Mixing Search and Database Queries**
   ```php
   // WRONG: This queries database, not search index
   $posts = Post::where('status', 'published')
       ->search('laravel')
       ->get();

   // CORRECT: Search first, then add constraints
   $posts = Post::search('laravel')
       ->where('status', 'published')
       ->get();

   // Or use query callback for Eloquent
   $posts = Post::search('laravel')
       ->query(fn ($builder) => $builder->where('status', 'published'))
       ->get();
   ```

6. **Not Setting Up Index Settings for Meilisearch**
   ```bash
   # Required for filtering and sorting
   php artisan scout:sync-index-settings

   # Check index settings
   curl http://localhost:7700/indexes/posts/settings
   ```

7. **Forgetting to Handle Empty Queries**
   ```php
   // Handle empty search gracefully
   $query = $request->input('q', '');

   if (empty($query)) {
       return Post::latest()->paginate(15);
   }

   return Post::search($query)->paginate(15);
   ```

8. **Not Considering Search Performance**
   ```php
   // Limit searchable attributes
   public function toSearchableArray(): array
   {
       // Only include searchable fields
       return [
           'title' => $this->title,
           'content' => strip_tags($this->content),
           // Don't include heavy relationships unnecessarily
       ];
   }
   ```

## Best Practices

- Use queue for indexing operations on production
- Configure index settings before importing data
- Implement search analytics and tracking
- Add typo tolerance and synonyms (Algolia/Meilisearch)
- Cache frequently searched queries
- Implement search suggestions/autocomplete
- Monitor search performance and relevance
- Use database driver only for simple use cases
- Regularly sync index settings after changes
- Implement faceted search for better UX
- Add search result highlighting
- Use chunking for large dataset imports
- Test search functionality with real data
- Implement search rate limiting
- Consider search costs (Algolia pricing)

## Related Commands

- `php artisan scout:import` - Import models to search index
- `php artisan scout:flush` - Flush models from index
- `php artisan scout:sync-index-settings` - Sync Meilisearch settings
- `php artisan scout:delete-index` - Delete search index

## Related Skills

- `laravel-api` - API development
- `laravel-queue` - Queue configuration
- `laravel-testing` - Testing strategies
- `laravel-performance` - Performance optimization
- `laravel-database` - Database queries
