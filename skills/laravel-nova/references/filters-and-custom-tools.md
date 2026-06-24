# Laravel Nova Filters, Custom Tools & Operations Reference

Filters, custom tools, testing, pitfalls, package integration, and best practices for Laravel Nova admin panels.

## Filters

### Select Filter
```php
<?php

declare(strict_types=1);

namespace App\Nova\Filters;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Laravel\Nova\Filters\Filter;

final class OrderStatus extends Filter
{
    /**
     * Apply the filter to the given query.
     */
    public function apply(Request $request, $query, $value): Builder
    {
        return $query->where('status', $value);
    }

    /**
     * Get the filter's available options.
     */
    public function options(Request $request): array
    {
        return [
            'Pending' => 'pending',
            'Processing' => 'processing',
            'Completed' => 'completed',
            'Cancelled' => 'cancelled',
        ];
    }
}
```

### Date Filter
```php
use Laravel\Nova\Filters\DateFilter;

final class CreatedAt extends DateFilter
{
    public function apply(Request $request, $query, $value): Builder
    {
        return $query->whereDate('created_at', $value);
    }
}
```

### Boolean Filter
```php
use Laravel\Nova\Filters\BooleanFilter;

final class ActiveProducts extends BooleanFilter
{
    public function apply(Request $request, $query, $value): Builder
    {
        if ($value['active']) {
            $query->where('is_active', true);
        }

        if ($value['featured']) {
            $query->where('is_featured', true);
        }

        return $query;
    }

    public function options(Request $request): array
    {
        return [
            'Active' => 'active',
            'Featured' => 'featured',
        ];
    }
}
```

### Post Status Filter
```php
<?php

declare(strict_types=1);

namespace App\Nova\Filters;

use Illuminate\Http\Request;
use Laravel\Nova\Filters\Filter;

final class PostStatus extends Filter
{
    public $name = 'Post Status';

    public function apply(Request $request, $query, $value)
    {
        return $query->where('status', $value);
    }

    public function options(Request $request): array
    {
        return [
            'Draft' => 'draft',
            'Published' => 'published',
            'Archived' => 'archived',
        ];
    }
}
```

## Custom Tools

```php
<?php

declare(strict_types=1);

namespace App\Nova\Tools;

use Illuminate\Http\Request;
use Laravel\Nova\Menu\MenuSection;
use Laravel\Nova\Tool;

final class Analytics extends Tool
{
    /**
     * Perform any tasks that need to happen when the tool is booted.
     */
    public function boot(): void
    {
        Nova::script('analytics', __DIR__.'/../dist/js/tool.js');
        Nova::style('analytics', __DIR__.'/../dist/css/tool.css');
    }

    /**
     * Build the menu that renders the navigation links for the tool.
     */
    public function menu(Request $request): mixed
    {
        return MenuSection::make('Analytics')
            ->path('/analytics')
            ->icon('chart-bar');
    }
}
```

Register in `NovaServiceProvider`:
```php
use App\Nova\Tools\Analytics;

public function tools(): array
{
    return [
        new Analytics,
    ];
}
```

## Custom Field (Inline)

```php
<?php

// Create custom field package or inline

// Inline computed field
Text::make('Full Name', function () {
    return $this->first_name . ' ' . $this->last_name;
})->onlyOnIndex();

// Custom field component
class Status extends Field
{
    public $component = 'status-field';
}
```

## Authorization Gate

```php
<?php

// app/Providers/NovaServiceProvider.php

use Laravel\Nova\Nova;

protected function gate(): void
{
    Gate::define('viewNova', function ($user) {
        return in_array($user->email, [
            'admin@example.com',
        ]) || $user->isAdmin();
    });
}

// Per-resource authorization
public static function authorizable(): bool
{
    return true;
}

// Uses policies automatically:
// app/Policies/PostPolicy.php
```

## Testing Nova Features

```php
<?php

declare(strict_types=1);

use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Nova\Fields\Text;
use Laravel\Nova\Http\Requests\NovaRequest;

uses(RefreshDatabase::class);

describe('Nova Product Resource', function () {
    beforeEach(function () {
        $this->admin = User::factory()->admin()->create();
        $this->product = Product::factory()->create();
    });

    it('displays products in index', function () {
        $response = $this->actingAs($this->admin)
            ->get('/nova-api/products')
            ->assertOk()
            ->assertJsonStructure([
                'resources' => [
                    '*' => ['id', 'fields'],
                ],
            ]);
    });

    it('shows product detail', function () {
        $response = $this->actingAs($this->admin)
            ->get("/nova-api/products/{$this->product->id}")
            ->assertOk()
            ->assertJsonPath('resource.id.value', $this->product->id);
    });

    it('creates product', function () {
        $data = [
            'name' => 'New Product',
            'sku' => 'TEST-001',
            'price' => 99.99,
            'status' => 'published',
        ];

        $response = $this->actingAs($this->admin)
            ->post('/nova-api/products', $data)
            ->assertCreated();

        $this->assertDatabaseHas('products', [
            'name' => 'New Product',
            'sku' => 'TEST-001',
        ]);
    });

    it('updates product', function () {
        $response = $this->actingAs($this->admin)
            ->put("/nova-api/products/{$this->product->id}", [
                'name' => 'Updated Name',
            ])
            ->assertOk();

        $this->product->refresh();
        expect($this->product->name)->toBe('Updated Name');
    });

    it('deletes product', function () {
        $response = $this->actingAs($this->admin)
            ->delete("/nova-api/products/{$this->product->id}")
            ->assertOk();

        $this->assertSoftDeleted('products', ['id' => $this->product->id]);
    });
});

describe('Nova Actions', function () {
    it('executes action on models', function () {
        $admin = User::factory()->admin()->create();
        $products = Product::factory()->count(3)->create();

        $response = $this->actingAs($admin)
            ->post('/nova-api/products/action', [
                'action' => 'update-status',
                'resources' => $products->pluck('id')->implode(','),
                'status' => 'archived',
            ])
            ->assertOk();

        foreach ($products as $product) {
            $product->refresh();
            expect($product->status)->toBe('archived');
        }
    });
});

describe('Nova Filters', function () {
    it('filters resources', function () {
        $admin = User::factory()->admin()->create();
        Product::factory()->create(['status' => 'published']);
        Product::factory()->create(['status' => 'draft']);

        $response = $this->actingAs($admin)
            ->get('/nova-api/products?filters=' . base64_encode(json_encode([
                ['class' => 'App\\Nova\\Filters\\ProductStatus', 'value' => 'published']
            ])))
            ->assertOk()
            ->assertJsonCount(1, 'resources');
    });
});
```

### Testing Nova Posts
```php
<?php

use App\Models\Post;
use App\Models\User;

describe('Nova Posts', function () {
    it('lists posts for admin', function () {
        $admin = User::factory()->admin()->create();
        $posts = Post::factory()->count(5)->create();

        $this->actingAs($admin)
            ->get('/nova-api/posts')
            ->assertOk()
            ->assertJsonCount(5, 'resources');
    });

    it('prevents non-admin access', function () {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/nova')
            ->assertRedirect();
    });

    it('can run publish action', function () {
        $admin = User::factory()->admin()->create();
        $post = Post::factory()->draft()->create();

        $this->actingAs($admin)
            ->post('/nova-api/posts/action?action=publish-post', [
                'resources' => [$post->id],
            ])
            ->assertOk();

        expect($post->fresh()->status)->toBe('published');
    });
});
```

## Common Pitfalls

1. **Missing License Configuration** - Must configure Nova composer repository
   ```bash
   composer config repositories.nova composer https://nova.laravel.com
   # Add credentials to auth.json or configure globally
   ```

2. **Not Publishing Nova Assets** - Assets must be published after updates
   ```bash
   php artisan nova:publish
   # Or for development
   npm run dev
   ```

3. **Resource Not Registered** - Resources must be in app/Nova and auto-discovered or manually registered
   ```php
   // In NovaServiceProvider::resources()
   return [
       \App\Nova\Product::class,
   ];
   ```

4. **Missing Authorization** - Always implement authorization methods
   ```php
   public static function authorizedToViewAny(Request $request): bool
   {
       return true; // Or proper check
   }
   ```

5. **Heavy Queries in Fields** - Use eager loading to prevent N+1
   ```php
   // In Resource
   public static $with = ['category', 'variants'];

   // Or use computed fields carefully
   Text::make('Orders Count')->resolveUsing(function () {
       return $this->orders()->count(); // This can be N+1
   }),
   ```

6. **Not Using Unique Validation Rules** - Resources need special validation
   ```php
   Text::make('Email')
       ->creationRules('unique:users,email')
       ->updateRules('unique:users,email,{{resourceId}}'),
   ```

7. **Actions Without Proper Response** - Always return Action response
   ```php
   // Bad
   public function handle(ActionFields $fields, Collection $models)
   {
       // Do something
   }

   // Good
   public function handle(ActionFields $fields, Collection $models)
   {
       // Do something
       return Action::message('Success!');
       // Or Action::danger(), Action::redirect(), Action::download()
   }
   ```

8. **Forgetting Field Dependencies** - Use dependsOn for conditional logic
   ```php
   Select::make('Type'),

   Text::make('Digital URL')
       ->dependsOn('type', function (Text $field, NovaRequest $request, $value) {
           if ($value === 'digital') {
               $field->show()->rules('required', 'url');
           } else {
               $field->hide();
           }
       }),
   ```

9. **Not Customizing Resource Title** - Make resources identifiable
   ```php
   public static $title = 'name';
   // Or use method
   public function title(): string
   {
       return $this->name . ' (' . $this->sku . ')';
   }
   ```

10. **Missing Soft Delete Handling** - Enable soft delete support
    ```php
    public static $softDeletes = true;

    // Add to fields
    public function fieldsForIndex(NovaRequest $request): array
    {
        return array_merge(parent::fieldsForIndex($request), [
            Text::make('Deleted At')->onlyOnIndex(),
        ]);
    }
    ```

### Additional Pitfalls (from agent)

- **Missing policies** - Nova uses Laravel policies for authorization
- **Heavy index queries** - Use `indexQuery` to optimize
- **Not caching metrics** - Always implement `cacheFor()`
- **Too many fields on index** - Use `hideFromIndex()` liberally
- **Missing search configuration** - Define `$search` for searchable resources

## Package Integration

### Official Nova Packages
- **laravel/nova-log-viewer** - View application logs
- **laravel/nova-dusk-suite** - Browser testing
- **spatie/nova-backup-tool** - Database backups
- **titasgailius/search-relations** - Search relationships
- **nova-kit/nova-packages-tool** - Package management

### Third-Party Packages
- **vyuldashev/nova-permission** - Spatie permissions integration
- **alexbowers/nova-inline-select** - Quick select actions
- **dillingham/nova-button** - Custom action buttons
- **davidpiesse/nova-map** - Map field for locations
- **emilianotisato/nova-tinymce** - Rich text editor

## Best Practices

### Resource Organization
- Group related resources using `$group` property
- Use descriptive navigation labels
- Set appropriate `$priority` for menu ordering
- Keep resources focused and single-purpose

### Performance
- Always eager load relationships using `$with`
- Use lenses for complex queries instead of filters
- Index searchable columns in database
- Cache expensive metric calculations
- Use queued actions for heavy operations

### User Experience
- Provide helpful field descriptions
- Use appropriate field types for data
- Add validation rules with clear messages
- Implement proper authorization
- Add confirmation for destructive actions

### Code Quality
- Use strict types in all Nova classes
- Implement final classes for resources
- Follow Nova naming conventions
- Document custom fields and tools
- Write tests for custom functionality

### Security
- Always implement authorization methods
- Validate all action inputs
- Use policies for model authorization
- Sanitize user inputs in custom fields
- Rate limit Nova routes if public-facing

## Guardrails

- **ALWAYS** implement authorization via policies
- **ALWAYS** cache metrics for performance
- **ALWAYS** optimize index queries with `indexQuery()`
- **NEVER** expose Nova to non-admin users
- **NEVER** skip validation rules on fields
- **NEVER** show sensitive data without authorization checks

## Related Commands

```bash
# Resource management
php artisan nova:resource Product
php artisan nova:resource Product --model=Product

# Actions
php artisan nova:action ApproveOrder
php artisan nova:action ExportData --queued

# Filters
php artisan nova:filter OrderStatus
php artisan nova:filter CreatedAt --date

# Lenses
php artisan nova:lens MostValuableUsers

# Metrics
php artisan nova:metric TotalRevenue --value
php artisan nova:metric OrdersPerDay --trend
php artisan nova:metric OrdersByStatus --partition

# Cards
php artisan nova:card SalesChart

# Tools
php artisan nova:tool Analytics

# Maintenance
php artisan nova:publish
php artisan nova:install
php artisan nova:user

# Assets
php artisan nova:assets
npm run dev # For development
npm run prod # For production
```
