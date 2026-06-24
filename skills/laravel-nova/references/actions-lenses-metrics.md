# Laravel Nova Actions, Lenses & Metrics Reference

Actions, lenses, and metrics for Laravel Nova admin panels — bulk operations, custom views, and dashboard analytics.

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

### Action with Notification (PublishPost)
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

final class PublishPost extends Action
{
    use InteractsWithQueue, Queueable;

    public $name = 'Publish Post';

    public function handle(ActionFields $fields, Collection $models)
    {
        foreach ($models as $model) {
            $model->update([
                'status' => 'published',
                'published_at' => now(),
            ]);

            // Optional: Send notification
            if ($fields->notify) {
                $model->author->notify(new PostPublished($model));
            }
        }

        return Action::message('Posts published successfully!');
    }

    public function fields(NovaRequest $request): array
    {
        return [
            Select::make('Notification', 'notify')
                ->options([
                    true => 'Notify Author',
                    false => 'Don\'t Notify',
                ])
                ->default(true),

            Textarea::make('Note')
                ->nullable(),
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

### Most Viewed Posts Lens
```php
<?php

declare(strict_types=1);

namespace App\Nova\Lenses;

use Laravel\Nova\Fields\ID;
use Laravel\Nova\Fields\Number;
use Laravel\Nova\Fields\Text;
use Laravel\Nova\Http\Requests\LensRequest;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Lenses\Lens;

final class MostViewedPosts extends Lens
{
    public function query(LensRequest $request, $query)
    {
        return $request->withOrdering($request->withFilters(
            $query->select(['id', 'title', 'views'])
                ->where('views', '>', 0)
                ->orderBy('views', 'desc')
                ->limit(50)
        ));
    }

    public function fields(NovaRequest $request): array
    {
        return [
            ID::make(),
            Text::make('Title'),
            Number::make('Views')->sortable(),
        ];
    }

    public function uriKey(): string
    {
        return 'most-viewed-posts';
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

### Trend Metric (PostsPerDay with cache)
```php
<?php

declare(strict_types=1);

namespace App\Nova\Metrics;

use App\Models\Post;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Metrics\Trend;

final class PostsPerDay extends Trend
{
    public function calculate(NovaRequest $request)
    {
        return $this->countByDays($request, Post::class);
    }

    public function ranges(): array
    {
        return [
            7 => '7 Days',
            14 => '14 Days',
            30 => '30 Days',
            60 => '60 Days',
            90 => '90 Days',
        ];
    }

    public function cacheFor(): \DateTimeInterface
    {
        return now()->addMinutes(5);
    }

    public function uriKey(): string
    {
        return 'posts-per-day';
    }
}
```

### Value Metric (TotalRevenue with cache)
```php
<?php

declare(strict_types=1);

namespace App\Nova\Metrics;

use App\Models\Order;
use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Metrics\Value;

final class TotalRevenue extends Value
{
    public function calculate(NovaRequest $request)
    {
        return $this->sum($request, Order::class, 'total')
            ->prefix('$')
            ->format('0,0.00');
    }

    public function ranges(): array
    {
        return [
            'TODAY' => 'Today',
            7 => '7 Days',
            30 => '30 Days',
            60 => '60 Days',
            365 => '365 Days',
            'MTD' => 'Month To Date',
            'QTD' => 'Quarter To Date',
            'YTD' => 'Year To Date',
        ];
    }

    public function cacheFor(): \DateTimeInterface
    {
        return now()->addMinutes(5);
    }
}
```

## Custom Dashboard

```php
<?php

declare(strict_types=1);

namespace App\Nova\Dashboards;

use App\Nova\Metrics\PostsPerDay;
use App\Nova\Metrics\TotalRevenue;
use App\Nova\Metrics\UsersPerDay;
use Laravel\Nova\Dashboard;

final class Main extends Dashboard
{
    public function name(): string
    {
        return 'Dashboard';
    }

    public function cards(): array
    {
        return [
            new TotalRevenue,
            new UsersPerDay,
            new PostsPerDay,
        ];
    }

    public function uriKey(): string
    {
        return 'main';
    }
}
```
