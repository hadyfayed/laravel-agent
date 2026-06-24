# Laravel Scout Searchable Models Reference

## Basic Searchable Model

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

## Searchable Product Model (extended, from agent)

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Laravel\Scout\Searchable;

final class Product extends Model
{
    use Searchable;

    /**
     * Get the indexable data array for the model.
     *
     * @return array<string, mixed>
     */
    public function toSearchableArray(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'sku' => $this->sku,
            'price' => $this->price,
            'category_name' => $this->category?->name,
            'brand_name' => $this->brand?->name,
            'tags' => $this->tags->pluck('name')->toArray(),
            'in_stock' => $this->in_stock,
            'rating' => $this->average_rating,
            'created_at' => $this->created_at->timestamp,
        ];
    }

    /**
     * Get the name of the index.
     */
    public function searchableAs(): string
    {
        return 'products_'.app()->environment();
    }

    /**
     * Determine if the model should be searchable.
     */
    public function shouldBeSearchable(): bool
    {
        return $this->is_published && $this->is_active;
    }

    /**
     * Modify the query used to retrieve models when making all models searchable.
     */
    public function makeAllSearchableUsing($query)
    {
        return $query->with(['category', 'brand', 'tags']);
    }
}
```

## Conditional Indexing

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

## Customizing Index Name

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

## Relationships in Search

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

## Importing Existing Records

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
