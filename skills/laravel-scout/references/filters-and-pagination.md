# Laravel Scout Filters and Pagination Reference

## Basic Search

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

## Search with Constraints

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

## Advanced Search Options

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

## Search Controller (Meilisearch, from agent)

```php
<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

final class SearchController extends Controller
{
    public function search(Request $request)
    {
        $query = $request->get('q', '');
        $filters = $request->only(['category', 'brand', 'min_price', 'max_price', 'in_stock']);
        $sort = $request->get('sort', 'relevance');

        $search = Product::search($query);

        // Apply filters (Meilisearch)
        if (!empty($filters['category'])) {
            $search->where('category_name', $filters['category']);
        }

        if (!empty($filters['brand'])) {
            $search->where('brand_name', $filters['brand']);
        }

        if (!empty($filters['in_stock'])) {
            $search->where('in_stock', true);
        }

        if (!empty($filters['min_price'])) {
            $search->where('price', '>=', (float) $filters['min_price']);
        }

        if (!empty($filters['max_price'])) {
            $search->where('price', '<=', (float) $filters['max_price']);
        }

        // Apply sorting
        $search = match ($sort) {
            'price_asc' => $search->orderBy('price', 'asc'),
            'price_desc' => $search->orderBy('price', 'desc'),
            'rating' => $search->orderBy('rating', 'desc'),
            'newest' => $search->orderBy('created_at', 'desc'),
            default => $search,
        };

        return $search->paginate(20);
    }

    // Advanced Meilisearch query with facets
    public function advancedSearch(Request $request)
    {
        return Product::search($request->get('q', ''), function ($meilisearch, $query, $options) use ($request) {
            $options['facets'] = ['category_name', 'brand_name', 'in_stock'];
            $options['attributesToHighlight'] = ['name', 'description'];
            $options['highlightPreTag'] = '<mark>';
            $options['highlightPostTag'] = '</mark>';

            if ($request->has('filters')) {
                $options['filter'] = $request->get('filters');
            }

            return $meilisearch->search($query, $options);
        })->paginateRaw(20);
    }
}
```

## Empty Search (Get All)

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

## Combining with Eloquent

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

## Search Controller (database driver)

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

## API Search Endpoint

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

## Livewire Search Component

```php
<?php

namespace App\Livewire;

use App\Models\Product;
use Livewire\Component;
use Livewire\WithPagination;

final class ProductSearch extends Component
{
    use WithPagination;

    public string $query = '';
    public array $filters = [];
    public string $sort = 'relevance';

    protected $queryString = [
        'query' => ['except' => ''],
        'filters' => ['except' => []],
        'sort' => ['except' => 'relevance'],
    ];

    public function updatingQuery(): void
    {
        $this->resetPage();
    }

    public function render()
    {
        $search = Product::search($this->query);

        foreach ($this->filters as $key => $value) {
            if (!empty($value)) {
                $search->where($key, $value);
            }
        }

        return view('livewire.product-search', [
            'products' => $search->paginate(20),
        ]);
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

### Product Search Tests (from agent)

```php
<?php

use App\Models\Product;

describe('Product Search', function () {
    beforeEach(function () {
        // Disable Scout for seeding
        Product::disableSearchSyncing();

        Product::factory()->count(10)->create(['name' => 'Test Laptop']);
        Product::factory()->count(5)->create(['name' => 'Test Phone']);

        Product::enableSearchSyncing();
    });

    it('finds products by name', function () {
        $results = Product::search('laptop')->get();

        expect($results)->toHaveCount(10);
    });

    it('filters by category', function () {
        $results = Product::search('test')
            ->where('category_name', 'Electronics')
            ->get();

        expect($results->every(fn ($p) => $p->category->name === 'Electronics'))->toBeTrue();
    });

    it('respects shouldBeSearchable', function () {
        $unpublished = Product::factory()->create([
            'name' => 'Unpublished Product',
            'is_published' => false,
        ]);

        $results = Product::search('Unpublished')->get();

        expect($results)->not->toContain($unpublished);
    });
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

## Additional Pitfalls (from agent)

- **Not queuing indexing** - Set `queue => true` in config for better performance
- **Missing filterable attributes** - Configure before using `where()` clauses
- **N+1 in toSearchableArray** - Use `makeAllSearchableUsing()` for eager loading
- **Heavy shouldBeSearchable** - Keep this method fast, it runs on every save
- **Indexing sensitive data** - Only include fields needed for search
- **Not syncing settings** - Run `scout:sync-index-settings` after config changes

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

## Guardrails

- **ALWAYS** queue indexing operations in production
- **ALWAYS** configure filterable/sortable attributes before using them
- **ALWAYS** use eager loading in toSearchableArray
- **NEVER** index sensitive personal data
- **NEVER** run sync operations during high traffic
- **NEVER** forget to update index after schema changes
