---
name: laravel-nova
description: >
  Build admin panels with Laravel Nova. Use when the user needs Nova resources,
  actions, filters, lenses, metrics, or custom tools.
  Triggers: "nova", "nova resource", "nova action", "nova filter", "nova lens",
  "nova metric", "nova tool", "admin dashboard".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Nova Skill

Build powerful, beautiful admin panels with Laravel Nova - Laravel's premium administration panel.

## When to Use

- Creating premium admin panels with advanced features
- Need for professional UI/UX out of the box
- Complex data relationships and visualization
- Enterprise-level admin requirements
- When budget allows for commercial license
- Official Laravel package with guaranteed support

### Nova vs Filament Comparison

**Choose Nova when:**
- Budget allows ($99/site)
- Need official Laravel package
- Want guaranteed long-term support
- Prefer traditional admin panel approach
- Need proven enterprise stability

**Choose Filament when:**
- Budget is limited (free/open-source)
- Need rapid development
- Want modern TALL stack approach
- Community packages are acceptable
- Prefer more customization flexibility

## Quick Start

```bash
# Note: Requires valid Nova license
composer require laravel/nova
php artisan nova:install
php artisan nova:user
```

## License Requirement

**Important:** Laravel Nova is a paid product requiring a license:
- $99 per site license
- $199 per developer (unlimited sites)
- Purchase at https://nova.laravel.com

Always check license validity before starting Nova projects.

## Installation

```bash
# Install Nova (requires license)
composer config repositories.nova composer https://nova.laravel.com
composer require laravel/nova

# Publish assets and run installer
php artisan nova:install

# Migrate the database
php artisan migrate

# Create first Nova user
php artisan nova:user

# Publish Nova configuration (optional)
php artisan vendor:publish --tag=nova-config
```

## Resource Structure

```php
<?php

declare(strict_types=1);

namespace App\Nova;

use Illuminate\Http\Request;
use Laravel\Nova\Fields\BelongsTo;
use Laravel\Nova\Fields\Boolean;
use Laravel\Nova\Fields\Currency;
use Laravel\Nova\Fields\HasMany;
use Laravel\Nova\Fields\ID;
use Laravel\Nova\Fields\Markdown;
use Laravel\Nova\Fields\Select;
use Laravel\Nova\Fields\Text;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Resource;

final class Product extends Resource
{
    /**
     * The model the resource corresponds to.
     */
    public static string $model = \App\Models\Product::class;

    /**
     * The single value that should be used to represent the resource when being displayed.
     */
    public static $title = 'name';

    /**
     * The columns that should be searched.
     */
    public static $search = [
        'id',
        'name',
        'sku',
    ];

    /**
     * The logical group associated with the resource.
     */
    public static $group = 'Catalog';

    /**
     * Get the fields displayed by the resource.
     */
    public function fields(NovaRequest $request): array
    {
        return [
            ID::make()->sortable(),

            Text::make('Name')
                ->sortable()
                ->rules('required', 'max:255')
                ->creationRules('unique:products,name')
                ->updateRules('unique:products,name,{{resourceId}}'),

            Text::make('SKU')
                ->sortable()
                ->rules('required', 'max:50')
                ->creationRules('unique:products,sku')
                ->updateRules('unique:products,sku,{{resourceId}}'),

            Currency::make('Price')
                ->currency('USD')
                ->sortable()
                ->rules('required', 'numeric', 'min:0'),

            BelongsTo::make('Category')
                ->searchable()
                ->withSubtitles()
                ->showCreateRelationButton(),

            Select::make('Status')
                ->options([
                    'draft' => 'Draft',
                    'published' => 'Published',
                    'archived' => 'Archived',
                ])
                ->displayUsingLabels()
                ->rules('required'),

            Boolean::make('Featured')
                ->default(false),

            Markdown::make('Description')
                ->alwaysShow()
                ->rules('required'),

            HasMany::make('Variants'),
        ];
    }

    /**
     * Get the cards available for the request.
     */
    public function cards(NovaRequest $request): array
    {
        return [];
    }

    /**
     * Get the filters available for the resource.
     */
    public function filters(NovaRequest $request): array
    {
        return [];
    }

    /**
     * Get the lenses available for the resource.
     */
    public function lenses(NovaRequest $request): array
    {
        return [];
    }

    /**
     * Get the actions available for the resource.
     */
    public function actions(NovaRequest $request): array
    {
        return [];
    }
}
```

## Field Types and Validation

### Basic Fields
```php
use Laravel\Nova\Fields\{
    Text, Textarea, Password, Email, Number,
    Boolean, Date, DateTime, Select, Badge,
    Code, Country, Currency, Heading, ID,
    Image, File, Markdown, Password, Slug,
    Sparkline, Status, Tag, Timezone, Vapor
};

Text::make('Title')
    ->rules('required', 'max:255')
    ->help('Enter the product title'),

Number::make('Stock')
    ->min(0)
    ->max(9999)
    ->step(1),

Date::make('Published At')
    ->format('YYYY-MM-DD')
    ->nullable(),

Select::make('Type')
    ->options([
        'physical' => 'Physical Product',
        'digital' => 'Digital Product',
        'service' => 'Service',
    ])
    ->displayUsingLabels(),

Badge::make('Status')
    ->map([
        'draft' => 'warning',
        'published' => 'success',
        'archived' => 'danger',
    ]),
```

### Relationship Fields
```php
BelongsTo::make('User')
    ->searchable()
    ->withSubtitles()
    ->showCreateRelationButton(),

HasMany::make('Orders')
    ->collapsable(),

BelongsToMany::make('Tags')
    ->searchable()
    ->withSubtitles()
    ->fields(function () {
        return [
            Text::make('Note'),
        ];
    }),

MorphTo::make('Commentable')
    ->types([
        Post::class,
        Video::class,
    ]),
```

### Computed Fields
```php
use Laravel\Nova\Fields\Computed;

Computed::make('Total Revenue', function () {
    return $this->orders->sum('total');
})->currency('USD'),

// Or using accessors
Text::make('Full Name', function () {
    return $this->first_name . ' ' . $this->last_name;
}),
```

### Conditional Fields
```php
Boolean::make('Has Variants')
    ->default(false),

Number::make('Variant Count')
    ->min(1)
    ->dependsOn('has_variants', function (Number $field, NovaRequest $request, $value) {
        if ($value === true) {
            $field->show()->rules('required', 'min:1');
        } else {
            $field->hide();
        }
    }),
```

## Actions

### Standalone Action
```php
<?php

declare(strict_types=1);

namespace App\Nova\Actions;

use Illuminate\Bus\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Collection;
use Laravel\Nova\Actions\Action;
use Laravel\Nova\Fields\ActionFields;
use Laravel\Nova\Fields\Select;
use Laravel\Nova\Fields\Textarea;
use Laravel\Nova\Http\Requests\NovaRequest;

final class UpdateOrderStatus extends Action
{
    use InteractsWithQueue, Queueable;

    /**
     * Perform the action on the given models.
     */
    public function handle(ActionFields $fields, Collection $models)
    {
        foreach ($models as $model) {
            $model->update([
                'status' => $fields->status,
                'notes' => $fields->notes,
            ]);
        }

        return Action::message('Order status updated successfully!');
    }

    /**
     * Get the fields available on the action.
     */
    public function fields(NovaRequest $request): array
    {
        return [
            Select::make('Status')
                ->options([
                    'pending' => 'Pending',
                    'processing' => 'Processing',
                    'completed' => 'Completed',
                    'cancelled' => 'Cancelled',
                ])
                ->rules('required'),

            Textarea::make('Notes')
                ->rules('nullable', 'max:500'),
        ];
    }
}
```

### Destructive Action
```php
final class DeleteProducts extends Action
{
    public $confirmText = 'Are you sure you want to delete these products?';
    public $confirmButtonText = 'Delete';
    public $cancelButtonText = 'Cancel';

    public function handle(ActionFields $fields, Collection $models)
    {
        foreach ($models as $model) {
            $model->delete();
        }

        return Action::message('Products deleted successfully!');
    }
}
```

### Queued Action
```php
final class ExportOrders extends Action
{
    use InteractsWithQueue, Queueable;

    public $onQueue = 'exports';
    public $connection = 'redis';

    public function handle(ActionFields $fields, Collection $models)
    {
        // Heavy export logic
        \Excel::store(
            new OrdersExport($models),
            'exports/orders-' . now()->timestamp . '.xlsx'
        );

        return Action::download(
            storage_path('app/exports/orders-' . now()->timestamp . '.xlsx'),
            'orders.xlsx'
        );
    }
}
```

### Action with Authorization
```php
public function authorizedToRun(NovaRequest $request, $model): bool
{
    return $request->user()->can('update', $model);
}

public function authorizedToSee(Request $request): bool
{
    return $request->user()->isAdmin();
}
```

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

## Lenses

```php
<?php

declare(strict_types=1);

namespace App\Nova\Lenses;

use App\Nova\Filters\OrderStatus;
use Illuminate\Database\Eloquent\Builder;
use Laravel\Nova\Fields\Currency;
use Laravel\Nova\Fields\ID;
use Laravel\Nova\Fields\Text;
use Laravel\Nova\Http\Requests\LensRequest;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Lenses\Lens;

final class MostValuableOrders extends Lens
{
    /**
     * Get the query builder / paginator for the lens.
     */
    public static function query(LensRequest $request, $query): Builder
    {
        return $request->withOrdering($request->withFilters(
            $query->where('total', '>', 1000)
                ->orderBy('total', 'desc')
        ));
    }

    /**
     * Get the fields available to the lens.
     */
    public function fields(NovaRequest $request): array
    {
        return [
            ID::make()->sortable(),

            Text::make('Order Number')
                ->sortable(),

            Text::make('Customer', 'user.name')
                ->sortable(),

            Currency::make('Total')
                ->currency('USD')
                ->sortable(),

            Text::make('Status')
                ->sortable(),
        ];
    }

    /**
     * Get the filters available for the lens.
     */
    public function filters(NovaRequest $request): array
    {
        return [
            new OrderStatus,
        ];
    }

    /**
     * Get the URI key for the lens.
     */
    public function uriKey(): string
    {
        return 'most-valuable-orders';
    }
}
```

## Metrics

### Value Metric
```php
<?php

declare(strict_types=1);

namespace App\Nova\Metrics;

use App\Models\Order;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Metrics\Value;

final class TotalRevenue extends Value
{
    /**
     * Calculate the value of the metric.
     */
    public function calculate(NovaRequest $request): mixed
    {
        return $this->sum($request, Order::class, 'total')
            ->currency('USD')
            ->format('0,0.00');
    }

    /**
     * Get the ranges available for the metric.
     */
    public function ranges(): array
    {
        return [
            30 => '30 Days',
            60 => '60 Days',
            90 => '90 Days',
            365 => '365 Days',
            'TODAY' => 'Today',
            'MTD' => 'Month To Date',
            'QTD' => 'Quarter To Date',
            'YTD' => 'Year To Date',
        ];
    }

    /**
     * Get the URI key for the metric.
     */
    public function uriKey(): string
    {
        return 'total-revenue';
    }
}
```

### Trend Metric
```php
<?php

declare(strict_types=1);

namespace App\Nova\Metrics;

use App\Models\Order;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Metrics\Trend;

final class OrdersPerDay extends Trend
{
    /**
     * Calculate the value of the metric.
     */
    public function calculate(NovaRequest $request): mixed
    {
        return $this->countByDays($request, Order::class);
    }

    /**
     * Get the ranges available for the metric.
     */
    public function ranges(): array
    {
        return [
            7 => '7 Days',
            30 => '30 Days',
            60 => '60 Days',
            90 => '90 Days',
        ];
    }

    /**
     * Get the URI key for the metric.
     */
    public function uriKey(): string
    {
        return 'orders-per-day';
    }
}
```

### Partition Metric
```php
<?php

declare(strict_types=1);

namespace App\Nova\Metrics;

use App\Models\Order;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Metrics\Partition;

final class OrdersByStatus extends Partition
{
    /**
     * Calculate the value of the metric.
     */
    public function calculate(NovaRequest $request): mixed
    {
        return $this->count($request, Order::class, 'status')
            ->colors([
                'pending' => '#F59E0B',
                'processing' => '#3B82F6',
                'completed' => '#10B981',
                'cancelled' => '#EF4444',
            ]);
    }

    /**
     * Get the URI key for the metric.
     */
    public function uriKey(): string
    {
        return 'orders-by-status';
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

## Authorization

### Resource Authorization
```php
// In Nova Resource
public static function authorizedToViewAny(Request $request): bool
{
    return $request->user()->can('viewAny', static::$model);
}

public function authorizedToView(Request $request): bool
{
    return $request->user()->can('view', $this->resource);
}

public function authorizedToCreate(Request $request): bool
{
    return $request->user()->can('create', static::$model);
}

public function authorizedToUpdate(Request $request): bool
{
    return $request->user()->can('update', $this->resource);
}

public function authorizedToDelete(Request $request): bool
{
    return $request->user()->can('delete', $this->resource);
}

public function authorizedToRestore(Request $request): bool
{
    return $request->user()->can('restore', $this->resource);
}

public function authorizedToForceDelete(Request $request): bool
{
    return $request->user()->can('forceDelete', $this->resource);
}
```

### Field Authorization
```php
Text::make('Internal Notes')
    ->canSee(function ($request) {
        return $request->user()->isAdmin();
    }),

Currency::make('Cost Price')
    ->hideFromIndex()
    ->canSee(function ($request) {
        return $request->user()->can('view-costs');
    }),
```

### Policy Integration
```php
// app/Policies/ProductPolicy.php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Product;
use App\Models\User;

final class ProductPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermission('view-products');
    }

    public function view(User $user, Product $product): bool
    {
        return $user->hasPermission('view-products');
    }

    public function create(User $user): bool
    {
        return $user->hasPermission('create-products');
    }

    public function update(User $user, Product $product): bool
    {
        return $user->hasPermission('update-products');
    }

    public function delete(User $user, Product $product): bool
    {
        return $user->hasPermission('delete-products') && !$product->orders()->exists();
    }

    public function restore(User $user, Product $product): bool
    {
        return $user->hasPermission('restore-products');
    }

    public function forceDelete(User $user, Product $product): bool
    {
        return $user->isAdmin();
    }
}
```

## Customization

### Custom Cards
```php
<?php

declare(strict_types=1);

namespace App\Nova\Cards;

use Laravel\Nova\Card;

final class RevenueChart extends Card
{
    public $width = '1/3';

    public function component(): string
    {
        return 'revenue-chart';
    }

    public function withData(array $data): self
    {
        return $this->withMeta(['data' => $data]);
    }
}
```

### Custom Fields
```php
<?php

declare(strict_types=1);

namespace App\Nova\Fields;

use Laravel\Nova\Fields\Field;

final class ColorPicker extends Field
{
    public $component = 'color-picker';

    public function default($value): self
    {
        return $this->withMeta(['value' => $value]);
    }
}
```

### Resource Groups
```php
// In Resource
public static $group = 'Catalog';

// In NovaServiceProvider
use Laravel\Nova\Nova;

Nova::sortResourcesBy(function ($resource) {
    return $resource::$priority ?? 99;
});
```

### Global Search
```php
public static $globallySearchable = true;

public static $search = [
    'id',
    'name',
    'email',
    'user.name', // Search relationships
];

public static function searchableColumns(): array
{
    return ['id', 'name', new SearchableText('bio')];
}
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

## Related Agents

- `laravel-architect` - Overall feature architecture
- `laravel-engineer` - Implementation of Nova resources
- `laravel-filament` - Alternative admin panel (for comparison)

## Related Skills

- `laravel-feature` - Feature-based organization
- `laravel-api` - API endpoints for Nova
- `laravel-testing` - Testing Nova functionality
- `laravel-auth` - User authentication for Nova
- `laravel-database` - Database optimization for Nova queries
