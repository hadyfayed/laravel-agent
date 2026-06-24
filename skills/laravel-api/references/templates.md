---
name: laravel-api
description: Code templates and stubs for API resources, controllers, requests, and versioning
---

# API CONTROLLER

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Store<Name>Request;
use App\Http\Requests\Api\V1\Update<Name>Request;
use App\Http\Resources\V1\<Name>Resource;
use App\Http\Resources\V1\<Name>Collection;
use App\Models\<Name>;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

final class <Name>Controller extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(<Name>::class, '<name>');
    }

    /**
     * @OA\Get(
     *     path="/api/v1/<names>",
     *     summary="List all <names>",
     *     tags={"<Names>"},
     *     @OA\Parameter(ref="#/components/parameters/page"),
     *     @OA\Parameter(ref="#/components/parameters/per_page"),
     *     @OA\Parameter(ref="#/components/parameters/filter"),
     *     @OA\Parameter(ref="#/components/parameters/sort"),
     *     @OA\Parameter(ref="#/components/parameters/include"),
     *     @OA\Response(response=200, description="Success", @OA\JsonContent(ref="#/components/schemas/<Name>Collection")),
     *     @OA\Response(response=401, ref="#/components/responses/Unauthenticated"),
     *     @OA\Response(response=403, ref="#/components/responses/Forbidden")
     * )
     */
    public function index(Request $request): <Name>Collection
    {
        $query = <Name>::query()
            ->filter($request->query('filter', []))
            ->sort($request->query('sort', '-created_at'))
            ->with($this->parseIncludes($request));

        return new <Name>Collection(
            $query->paginate($request->integer('per_page', 15))
        );
    }

    /**
     * @OA\Post(
     *     path="/api/v1/<names>",
     *     summary="Create a new <name>",
     *     tags={"<Names>"},
     *     @OA\RequestBody(required=true, @OA\JsonContent(ref="#/components/schemas/Store<Name>Request")),
     *     @OA\Response(response=201, description="Created", @OA\JsonContent(ref="#/components/schemas/<Name>Resource")),
     *     @OA\Response(response=422, ref="#/components/responses/ValidationError")
     * )
     */
    public function store(Store<Name>Request $request): JsonResponse
    {
        $<name> = <Name>::create($request->validated());

        return (new <Name>Resource($<name>))
            ->response()
            ->setStatusCode(Response::HTTP_CREATED);
    }

    /**
     * @OA\Get(
     *     path="/api/v1/<names>/{<name>}",
     *     summary="Get a specific <name>",
     *     tags={"<Names>"},
     *     @OA\Parameter(name="<name>", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Parameter(ref="#/components/parameters/include"),
     *     @OA\Response(response=200, description="Success", @OA\JsonContent(ref="#/components/schemas/<Name>Resource")),
     *     @OA\Response(response=404, ref="#/components/responses/NotFound")
     * )
     */
    public function show(Request $request, <Name> $<name>): <Name>Resource
    {
        return new <Name>Resource(
            $<name>->load($this->parseIncludes($request))
        );
    }

    /**
     * @OA\Put(
     *     path="/api/v1/<names>/{<name>}",
     *     summary="Update a <name>",
     *     tags={"<Names>"},
     *     @OA\Parameter(name="<name>", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\RequestBody(required=true, @OA\JsonContent(ref="#/components/schemas/Update<Name>Request")),
     *     @OA\Response(response=200, description="Success", @OA\JsonContent(ref="#/components/schemas/<Name>Resource")),
     *     @OA\Response(response=422, ref="#/components/responses/ValidationError")
     * )
     */
    public function update(Update<Name>Request $request, <Name> $<name>): <Name>Resource
    {
        $<name>->update($request->validated());

        return new <Name>Resource($<name>->fresh());
    }

    /**
     * @OA\Delete(
     *     path="/api/v1/<names>/{<name>}",
     *     summary="Delete a <name>",
     *     tags={"<Names>"},
     *     @OA\Parameter(name="<name>", in="path", required=true, @OA\Schema(type="integer")),
     *     @OA\Response(response=204, description="No Content"),
     *     @OA\Response(response=404, ref="#/components/responses/NotFound")
     * )
     */
    public function destroy(<Name> $<name>): JsonResponse
    {
        $<name>->delete();

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }

    private function parseIncludes(Request $request): array
    {
        $allowed = ['relation1', 'relation2', 'relation3'];
        $requested = explode(',', $request->query('include', ''));

        return array_intersect($allowed, $requested);
    }
}
```

# API RESOURCE

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @OA\Schema(
 *     schema="<Name>Resource",
 *     @OA\Property(property="id", type="integer"),
 *     @OA\Property(property="type", type="string", example="<names>"),
 *     @OA\Property(property="attributes", type="object",
 *         @OA\Property(property="field1", type="string"),
 *         @OA\Property(property="field2", type="integer"),
 *         @OA\Property(property="created_at", type="string", format="date-time"),
 *         @OA\Property(property="updated_at", type="string", format="date-time")
 *     ),
 *     @OA\Property(property="relationships", type="object"),
 *     @OA\Property(property="links", type="object",
 *         @OA\Property(property="self", type="string")
 *     )
 * )
 */
final class <Name>Resource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => '<names>',
            'attributes' => [
                'field1' => $this->field1,
                'field2' => $this->field2,
                'created_at' => $this->created_at?->toISOString(),
                'updated_at' => $this->updated_at?->toISOString(),
            ],
            'relationships' => [
                'relation' => new RelationResource($this->whenLoaded('relation')),
            ],
            'links' => [
                'self' => route('api.v1.<names>.show', $this->id),
            ],
        ];
    }
}
```

# API COLLECTION WITH META

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\ResourceCollection;

final class <Name>Collection extends ResourceCollection
{
    public $collects = <Name>Resource::class;

    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
            'links' => [
                'self' => $request->fullUrl(),
            ],
            'meta' => [
                'total' => $this->total(),
                'per_page' => $this->perPage(),
                'current_page' => $this->currentPage(),
                'last_page' => $this->lastPage(),
            ],
        ];
    }
}
```

# QUERY FILTERING

```php
<?php

declare(strict_types=1);

namespace App\Filters;

use Illuminate\Database\Eloquent\Builder;

final class <Name>Filter
{
    public function __construct(
        private readonly Builder $query,
        private readonly array $filters,
    ) {}

    public function apply(): Builder
    {
        foreach ($this->filters as $filter => $value) {
            if (method_exists($this, $filter) && $value !== null) {
                $this->{$filter}($value);
            }
        }

        return $this->query;
    }

    private function status(string $value): void
    {
        $this->query->where('status', $value);
    }

    private function search(string $value): void
    {
        $this->query->where(function ($q) use ($value) {
            $q->where('name', 'like', "%{$value}%")
              ->orWhere('description', 'like', "%{$value}%");
        });
    }

    private function created_after(string $value): void
    {
        $this->query->whereDate('created_at', '>=', $value);
    }

    private function created_before(string $value): void
    {
        $this->query->whereDate('created_at', '<=', $value);
    }
}

// Model trait
trait Filterable
{
    public function scopeFilter(Builder $query, array $filters): Builder
    {
        return (new static::$filterClass($query, $filters))->apply();
    }
}
```

# SORTING

```php
// Model trait
trait Sortable
{
    public function scopeSort(Builder $query, string $sort): Builder
    {
        $direction = str_starts_with($sort, '-') ? 'desc' : 'asc';
        $column = ltrim($sort, '-');

        $allowed = static::$sortable ?? ['created_at', 'updated_at'];

        if (in_array($column, $allowed)) {
            $query->orderBy($column, $direction);
        }

        return $query;
    }
}
```

# RATE LIMITING

```php
// bootstrap/app.php or RouteServiceProvider
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

RateLimiter::for('api-heavy', function (Request $request) {
    return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
});

// Routes
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    Route::apiResource('<names>', <Name>Controller::class);
});

Route::middleware(['auth:sanctum', 'throttle:api-heavy'])->group(function () {
    Route::post('<names>/bulk', [<Name>Controller::class, 'bulkStore']);
});
```

# ERROR HANDLING

```php
// app/Exceptions/Handler.php or bootstrap/app.php
$exceptions->render(function (Throwable $e, Request $request) {
    if ($request->expectsJson()) {
        return match (true) {
            $e instanceof ModelNotFoundException => response()->json([
                'error' => [
                    'status' => 404,
                    'title' => 'Not Found',
                    'detail' => 'The requested resource was not found.',
                ],
            ], 404),

            $e instanceof ValidationException => response()->json([
                'error' => [
                    'status' => 422,
                    'title' => 'Validation Error',
                    'detail' => 'The given data was invalid.',
                    'errors' => $e->errors(),
                ],
            ], 422),

            $e instanceof AuthorizationException => response()->json([
                'error' => [
                    'status' => 403,
                    'title' => 'Forbidden',
                    'detail' => 'You are not authorized to perform this action.',
                ],
            ], 403),

            default => response()->json([
                'error' => [
                    'status' => 500,
                    'title' => 'Server Error',
                    'detail' => config('app.debug') ? $e->getMessage() : 'An error occurred.',
                ],
            ], 500),
        };
    }
});
```

# SPATIE/LARAVEL-FRACTAL (API Transformers)

If `spatie/laravel-fractal` or `spatie/fractalistic` is installed:

## Install
```bash
composer require spatie/laravel-fractal
```

## Create Transformer
```php
<?php

declare(strict_types=1);

namespace App\Transformers;

use App\Models\Order;
use League\Fractal\TransformerAbstract;

final class OrderTransformer extends TransformerAbstract
{
    protected array $availableIncludes = [
        'customer',
        'items',
    ];

    protected array $defaultIncludes = [];

    public function transform(Order $order): array
    {
        return [
            'id' => $order->id,
            'number' => $order->number,
            'status' => $order->status,
            'total' => [
                'amount' => $order->total_cents,
                'formatted' => $order->total_formatted,
                'currency' => $order->currency,
            ],
            'created_at' => $order->created_at->toIso8601String(),
            'updated_at' => $order->updated_at->toIso8601String(),
            'links' => [
                'self' => route('api.orders.show', $order),
            ],
        ];
    }

    public function includeCustomer(Order $order): \League\Fractal\Resource\Item
    {
        return $this->item($order->customer, new CustomerTransformer);
    }

    public function includeItems(Order $order): \League\Fractal\Resource\Collection
    {
        return $this->collection($order->items, new OrderItemTransformer);
    }
}
```

## Use in Controller
```php
use Spatie\Fractal\Fractal;

public function index(): JsonResponse
{
    $orders = Order::with(['customer', 'items'])->paginate();

    return fractal($orders, new OrderTransformer())
        ->parseIncludes(request()->input('include', ''))
        ->respond();
}

public function show(Order $order): JsonResponse
{
    return fractal($order, new OrderTransformer())
        ->parseIncludes(['customer', 'items'])
        ->respond();
}

// Or use the facade
return Fractal::create()
    ->collection($orders)
    ->transformWith(new OrderTransformer)
    ->includeCustomer()
    ->toArray();
```

## Generate Transformer Command
```bash
php artisan make:transformer OrderTransformer
```

## Pagination with Fractal
```php
use League\Fractal\Pagination\IlluminatePaginatorAdapter;

$paginator = Order::paginate(15);

return fractal()
    ->collection($paginator->getCollection())
    ->transformWith(new OrderTransformer)
    ->paginateWith(new IlluminatePaginatorAdapter($paginator))
    ->respond();
```

## Custom Serializers
```php
// config/fractal.php
return [
    'default_serializer' => \League\Fractal\Serializer\DataArraySerializer::class,
    // Or use JSON:API format
    // 'default_serializer' => \League\Fractal\Serializer\JsonApiSerializer::class,
];
```

## Fractal vs Laravel Resources

| Feature | Fractal | Laravel Resources |
|---------|---------|-------------------|
| Includes | Dynamic via URL | Manual loading |
| Transformation | Dedicated classes | Mixed in resources |
| Serializers | Multiple formats | JSON only |
| Nested data | Built-in | Manual |
| Learning curve | Higher | Lower |

**Recommendation**: Use Fractal for complex APIs with deep relationships. Use Laravel Resources for simpler APIs.
