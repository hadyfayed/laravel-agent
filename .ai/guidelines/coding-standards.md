# Laravel Coding Standards

Follow these standards when generating Laravel code.

## PHP Standards

### Strict Types
Always declare strict types at the top of PHP files:

```php
<?php

declare(strict_types=1);
```

### Final Classes
Use `final` for classes that shouldn't be extended:

```php
final class OrderService
{
    // ...
}
```

### Type Declarations
Always use type declarations for parameters and return types:

```php
public function calculateTotal(array $items): float
{
    // ...
}
```

### Named Arguments
Prefer named arguments for clarity:

```php
// Good
User::create(
    name: $request->name,
    email: $request->email,
);

// Avoid for simple cases
str_replace(search: 'a', replace: 'b', subject: $string);
```

## Laravel Conventions

### Controllers
- Use resource controllers for CRUD operations
- Keep controllers thin - delegate to actions/services
- Use Form Requests for validation
- Use API Resources for responses

```php
final class ProductController extends Controller
{
    public function store(StoreProductRequest $request, CreateProductAction $action)
    {
        $product = $action->execute($request->validated());

        return new ProductResource($product);
    }
}
```

### Models
- Define `$fillable` explicitly (not `$guarded = []`)
- Use Enums for status fields
- Define relationships with return types
- Use `casts()` method for attribute casting

```php
final class Product extends Model
{
    protected $fillable = ['name', 'price', 'status'];

    protected function casts(): array
    {
        return [
            'status' => ProductStatus::class,
            'price' => 'decimal:2',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }
}
```

### Migrations
- Use descriptive table and column names
- Add indexes for frequently queried columns
- Use foreign key constraints
- Include `down()` method

```php
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->foreignId('category_id')->constrained()->cascadeOnDelete();
    $table->string('name');
    $table->decimal('price', 10, 2);
    $table->timestamps();

    $table->index('name');
});
```

### Routes
- Use route model binding
- Group routes by feature/domain
- Use named routes
- Apply middleware at group level

```php
Route::middleware(['auth'])->group(function () {
    Route::resource('products', ProductController::class);
});
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Controller | PascalCase + Controller | `ProductController` |
| Model | PascalCase (singular) | `Product` |
| Migration | snake_case (plural) | `create_products_table` |
| Request | PascalCase + Request | `StoreProductRequest` |
| Resource | PascalCase + Resource | `ProductResource` |
| Action | PascalCase + Action | `CreateProductAction` |
| Service | PascalCase + Service | `PaymentService` |
| Event | Past tense | `OrderCreated` |
| Listener | Present tense | `SendOrderNotification` |
| Job | Descriptive verb | `ProcessPayment` |
| Policy | Model + Policy | `ProductPolicy` |

## File Organization

```
app/
├── Actions/           # Single-purpose actions
│   └── Products/
│       └── CreateProductAction.php
├── Http/
│   ├── Controllers/
│   ├── Requests/
│   └── Resources/
├── Models/
├── Services/          # Complex business logic
└── Enums/
```

## Error Handling

- Use custom exceptions for domain errors
- Return appropriate HTTP status codes
- Provide meaningful error messages

```php
// Custom exception
final class InsufficientStockException extends Exception
{
    public function __construct(Product $product)
    {
        parent::__construct("Insufficient stock for {$product->name}");
    }
}

// In controller
try {
    $order = $action->execute($data);
} catch (InsufficientStockException $e) {
    return response()->json(['error' => $e->getMessage()], 422);
}
```
