# Laravel Nova Resources & Fields Reference

Resources, field types, relationships, authorization, and customization for Laravel Nova admin panels.

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

## Nova Structure

```
app/Nova/
├── Resources/
│   ├── User.php
│   ├── Post.php
│   └── Comment.php
├── Actions/
│   └── SendEmail.php
├── Filters/
│   └── UserType.php
├── Lenses/
│   └── MostValuableUsers.php
├── Metrics/
│   ├── UsersPerDay.php
│   └── TotalRevenue.php
├── Dashboards/
│   └── Main.php
└── Tools/
    └── CustomTool.php
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
