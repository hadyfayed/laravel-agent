# Version-Specific Breaking Changes

## Laravel 10 → 11

### PHP Requirement

**Minimum:** PHP 8.2 (up from 8.1)

```json
{
  "require": {
    "php": "^8.2"
  }
}
```

### Model Casts Property → Method

**Before:**
```php
protected $casts = [
    'email_verified_at' => 'datetime',
    'is_admin' => 'boolean',
];
```

**After:**
```php
protected function casts(): array {
    return [
        'email_verified_at' => 'datetime',
        'is_admin' => 'boolean',
    ];
}
```

### Application Structure (Optional)

New skeleton is slimmer, but old structure still works. Laravel 11 can use either:

**Old (still works):**
```
app/Http/Kernel.php
app/Console/Kernel.php
app/Exceptions/Handler.php
```

**New (recommended):**
```
bootstrap/app.php  # Single file for all
routes/console.php  # Artisan commands
```

### Rate Limiting: Per-Second Available

```php
// Old
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60);
});

// New
RateLimiter::for('api', function (Request $request) {
    return Limit::perSecond(1);  // Per-second throttling
});
```

## Laravel 9 → 10

### Validation Rules: New Interface

**Before:**
```php
class Uppercase implements Rule {
    public function passes($attribute, $value) {
        return strtoupper($value) === $value;
    }

    public function message() {
        return 'Must be uppercase.';
    }
}
```

**After:**
```php
use Illuminate\Contracts\Validation\ValidationRule;

class Uppercase implements ValidationRule {
    public function validate(
        string $attribute,
        mixed $value,
        Closure $fail
    ): void {
        if (strtoupper($value) !== $value) {
            $fail('Must be uppercase.');
        }
    }
}
```

### Process Facade: External Process Handling

**Before:**
```php
exec('node --version', $output);
$version = $output[0];
```

**After:**
```php
use Illuminate\Support\Facades\Process;

$result = Process::run('node --version');
echo $result->output();
```

### Return Type Declarations Required

Many framework methods now require return types on custom implementations:

```php
// Before
public function boot() {
    // ...
}

// After
public function boot(): void {
    // ...
}
```

## Laravel 8 → 9

### PHP 8 Features Adoption

Use modern PHP 8 syntax throughout:

**Type hints:**
```php
// Before
public function process($data) {
    return $this->service->execute($data);
}

// After
public function process(array $data): OrderData {
    return $this->service->execute($data);
}
```

**Named arguments:**
```php
// Now supported
Route::post('users', [UserController::class, 'store']);
```

**Match expressions:**
```php
// Can replace complex if/elseif chains
$status = match($order->state) {
    'pending' => 'Processing',
    'completed' => 'Done',
    'cancelled' => 'Cancelled',
};
```

## PHP 8.1 → 8.2

### Readonly Classes

```php
readonly class UserDTO {
    public function __construct(
        public string $name,
        public string $email,
    ) {}
}
```

### Dynamic Properties Deprecated

```php
// Deprecated in PHP 8.2
$user->customProperty = 'value';

// Solution 1: Use #[AllowDynamicProperties]
#[AllowDynamicProperties]
class User extends Model { }

// Solution 2: Define property
class User extends Model {
    public string $customProperty;
}
```

### String Interpolation Changes

```php
// Deprecated
echo "Hello ${name}";
echo "Hello $obj->prop";

// Use
echo "Hello {$name}";
echo "Hello {$obj->prop}";
```

### Deprecation Notices

```bash
# Run with strict deprecation warnings
php -d error_reporting=E_ALL -d display_errors=1 artisan serve
```

## PHP 8.2 → 8.3

### Typed Constants

```php
class Order {
    public const string STATUS = 'pending';
    public const int MAX = 100;
}
```

### #[Override] Attribute

```php
class Child extends Parent {
    #[\Override]
    public function method(): void {
        // Compiler error if parent doesn't have this method
    }
}
```

### json_validate()

```php
// Before
$data = json_decode($json, true);
if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
    // Invalid JSON
}

// After
if (json_validate($json)) {
    $data = json_decode($json, true);
}
```

## PHP 8.3 → 8.4

### Property Hooks

```php
class User {
    private string $firstName;
    private string $lastName;

    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
        set => [$this->firstName, $this->lastName] = explode(' ', $value, 2);
    }
}
```

### Asymmetric Visibility

```php
class User {
    // Readable anywhere, writable only in this class
    public private(set) string $id;

    // Accessible to public, writable to protected scope
    public protected(set) string $status;
}
```

### New Array Functions

```php
// array_find() — first match
$admin = array_find($users, fn($u) => $u->isAdmin());

// array_any() — any match
$hasAdmin = array_any($users, fn($u) => $u->isAdmin());

// array_all() — all match
$allActive = array_all($users, fn($u) => $u->isActive());
```

### Compound Assignment Operators

```php
// New operators
$a ??= 0;      // Null coalesce assign
$b &&= true;   // And assign
$c ||= false;  // Or assign
```
