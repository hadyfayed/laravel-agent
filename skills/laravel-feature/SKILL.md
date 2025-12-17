---
name: laravel-feature
description: >
  Build complete Laravel features with CRUD, views, API, and tests. Use when the user
  wants to create a new feature, implement functionality, or build a complete module
  with models, controllers, views, and tests. Triggers: "build feature", "create feature",
  "implement", "new module", "add functionality", "crud", "resource".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Feature Builder Skill

Build self-contained business features in Laravel following best practices.

## When to Use

- User wants to "build a feature" or "create functionality"
- Request involves CRUD operations with UI
- Need models, controllers, views, and tests together
- Building a complete business capability

## Quick Start

```bash
/laravel-agent:feature:make <FeatureName>
```

Or describe what you need and I'll build it.

## Structure Generated

```
app/Features/<Name>/
├── <Name>ServiceProvider.php
├── Domain/
│   ├── Models/<Name>.php
│   ├── Events/<Name>Created.php
│   ├── Actions/Create<Name>Action.php
│   └── Enums/<Name>Status.php
├── Http/
│   ├── Controllers/<Name>Controller.php
│   ├── Requests/Store<Name>Request.php
│   └── Resources/<Name>Resource.php
├── Database/
│   ├── Migrations/
│   └── Factories/
└── Tests/
    └── <Name>FeatureTest.php
```

## Complete Example

### Model with Relationships
```php
<?php

declare(strict_types=1);

namespace App\Features\Products\Domain\Models;

use App\Features\Products\Domain\Enums\ProductStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

final class Product extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'price',
        'category_id',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'status' => ProductStatus::class,
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function variants(): HasMany
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', ProductStatus::Active);
    }

    public function getPriceFormattedAttribute(): string
    {
        return number_format($this->price, 2);
    }
}
```

### Controller with Authorization
```php
<?php

declare(strict_types=1);

namespace App\Features\Products\Http\Controllers;

use App\Features\Products\Domain\Actions\CreateProductAction;
use App\Features\Products\Domain\Models\Product;
use App\Features\Products\Http\Requests\StoreProductRequest;
use App\Features\Products\Http\Requests\UpdateProductRequest;
use App\Features\Products\Http\Resources\ProductResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

final class ProductController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(Product::class, 'product');
    }

    public function index(): View
    {
        $products = Product::query()
            ->with(['category'])
            ->latest()
            ->paginate(15);

        return view('products.index', compact('products'));
    }

    public function store(StoreProductRequest $request, CreateProductAction $action): RedirectResponse
    {
        $product = $action->execute($request->validated());

        return redirect()
            ->route('products.show', $product)
            ->with('success', 'Product created successfully.');
    }

    public function show(Product $product): View
    {
        $product->load(['category', 'variants']);

        return view('products.show', compact('product'));
    }

    public function update(UpdateProductRequest $request, Product $product): RedirectResponse
    {
        $product->update($request->validated());

        return redirect()
            ->route('products.show', $product)
            ->with('success', 'Product updated successfully.');
    }

    public function destroy(Product $product): RedirectResponse
    {
        $product->delete();

        return redirect()
            ->route('products.index')
            ->with('success', 'Product deleted successfully.');
    }
}
```

### Form Request with Validation
```php
<?php

declare(strict_types=1);

namespace App\Features\Products\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', 'unique:products,slug'],
            'description' => ['nullable', 'string', 'max:5000'],
            'price' => ['required', 'numeric', 'min:0', 'max:999999.99'],
            'category_id' => ['required', 'exists:categories,id'],
            'status' => ['required', Rule::enum(ProductStatus::class)],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Product name is required.',
            'price.min' => 'Price cannot be negative.',
        ];
    }
}
```

### Action for Business Logic
```php
<?php

declare(strict_types=1);

namespace App\Features\Products\Domain\Actions;

use App\Features\Products\Domain\Events\ProductCreated;
use App\Features\Products\Domain\Models\Product;

final class CreateProductAction
{
    public function execute(array $data): Product
    {
        $product = Product::create($data);

        event(new ProductCreated($product));

        return $product;
    }
}
```

### Pest Test
```php
<?php

declare(strict_types=1);

use App\Features\Products\Domain\Models\Product;
use App\Models\User;

beforeEach(function () {
    $this->user = User::factory()->create();
    $this->actingAs($this->user);
});

describe('ProductController', function () {
    it('displays products index', function () {
        Product::factory()->count(3)->create();

        $response = $this->get(route('products.index'));

        $response->assertOk();
        $response->assertViewHas('products');
    });

    it('creates a product', function () {
        $data = Product::factory()->make()->toArray();

        $response = $this->post(route('products.store'), $data);

        $response->assertRedirect();
        $this->assertDatabaseHas('products', ['name' => $data['name']]);
    });

    it('validates required fields', function () {
        $response = $this->post(route('products.store'), []);

        $response->assertSessionHasErrors(['name', 'price', 'category_id']);
    });

    it('soft deletes a product', function () {
        $product = Product::factory()->create();

        $this->delete(route('products.destroy', $product));

        $this->assertSoftDeleted('products', ['id' => $product->id]);
    });
});
```

## Decision Matrix

| Request Type | Implementation |
|--------------|----------------|
| CRUD + UI + API | Feature (this skill) |
| Reusable logic only | Module |
| Single operation | Action |
| Business orchestration | Service |

## Common Pitfalls

1. **Fat Controllers** - Move logic to Actions/Services
2. **Missing Authorization** - Always use Policies
3. **N+1 Queries** - Eager load relationships
4. **No Validation** - Use Form Requests
5. **Hardcoded Values** - Use Enums and Config
6. **Missing Tests** - Every feature needs tests

## Package Integration

- **spatie/laravel-sluggable** - Auto-generate slugs
- **spatie/laravel-medialibrary** - Handle file uploads
- **spatie/laravel-activitylog** - Track changes
- **spatie/laravel-tags** - Add tagging

## Best Practices

- Use `final class` for non-inheritable classes
- Declare `strict_types=1`
- Follow SOLID principles
- Max 5 design patterns per project
- Include factory and tests
- Use Enums for status fields
- Implement soft deletes

## Related Commands

- `/laravel-agent:feature:make` - Create a complete Laravel feature
- `/laravel-agent:module:make` - Create a reusable domain module
- `/laravel-agent:service:make` - Create a service class or action

## Related Agents

- `laravel-feature-builder` - Feature creation specialist
- `laravel-architect` - Architecture and planning
