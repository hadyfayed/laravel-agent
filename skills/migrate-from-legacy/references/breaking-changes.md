# Breaking Changes by Version

## Laravel 10 → 11

### Configuration Structure

**Old:** `app/Http/Kernel.php`
```php
protected $middleware = [
    \App\Http\Middleware\TrustProxies::class,
];
```

**New:** `bootstrap/app.php`
```php
return Application::configure(basePath: dirname(__DIR__))
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->append(TrustProxies::class);
    })
    ->create();
```

### Model Casts

**Old:**
```php
protected $casts = [
    'email_verified_at' => 'datetime',
];
```

**New:**
```php
protected function casts(): array {
    return [
        'email_verified_at' => 'datetime',
    ];
}
```

### Rate Limiting

**Old:**
```php
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60);
});
```

**New:**
```php
RateLimiter::for('api', function (Request $request) {
    return Limit::perSecond(1);  // New per-second option
});
```

## Laravel 9 → 10

### Validation Rules

**Old:**
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

**New:**
```php
class Uppercase implements ValidationRule {
    public function validate(string $attribute, mixed $value, Closure $fail): void {
        if (strtoupper($value) !== $value) {
            $fail('Must be uppercase.');
        }
    }
}
```

### Process Facade

**Old:**
```php
exec('node --version', $output);
$version = $output[0];
```

**New:**
```php
use Illuminate\Support\Facades\Process;
$result = Process::run('node --version');
echo $result->output();
```

### Type Declarations

Many framework methods now have return types. Update custom implementations:
```php
// Old
public function boot() {
    // ...
}

// New
public function boot(): void {
    // ...
}
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
// Deprecated
$user->customProp = 'value';

// Use #[AllowDynamicProperties] or define property
class User extends Model {
    public string $customProp;
}
```

### String Interpolation

```php
// Deprecated
echo "Hello ${name}";

// Use
echo "Hello {$name}";
```

## PHP 8.2 → 8.3

### Typed Constants

```php
class Order {
    public const string STATUS_PENDING = 'pending';
    public const int MAX_ITEMS = 100;
}
```

### #[Override] Attribute

```php
class Child extends Parent {
    #[\Override]
    public function method(): void { }  // Error if parent method doesn't exist
}
```

### json_validate()

```php
if (json_validate($json)) {
    $data = json_decode($json, true);
}
```

## PHP 8.3 → 8.4

### Property Hooks

```php
class User {
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
        set => [$this->firstName, $this->lastName] = explode(' ', $value, 2);
    }
}
```

### Asymmetric Visibility

```php
class User {
    public private(set) string $id;  // Read public, write private
}
```

### array_find() and Similar Functions

```php
$found = array_find($users, fn($u) => $u->isAdmin());
$hasAdmin = array_any($users, fn($u) => $u->isAdmin());
$allActive = array_all($users, fn($u) => $u->isActive());
```
