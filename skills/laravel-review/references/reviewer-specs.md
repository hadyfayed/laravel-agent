# Code Reviewer Specifications

## Security Reviewer

**Focus Areas:**

### SQL Injection (Critical)
```php
// DANGEROUS - Flag with 95% confidence
$users = DB::select("SELECT * FROM users WHERE id = $id");
User::whereRaw("id = {$request->id}");

// SAFE - Don't flag
User::where('id', $request->id)->get();
DB::select("SELECT * FROM users WHERE id = ?", [$id]);
```

### XSS (Critical)
```php
// DANGEROUS - Flag with 95% confidence
{!! $userInput !!}
<?= $content ?>
echo $request->input('name');

// SAFE - Don't flag
{{ $userInput }}
{!! $trustedHtml !!} // Only if clearly from admin/trusted source
```

### Mass Assignment (High)
```php
// DANGEROUS - Flag with 90% confidence
User::create($request->all());
$user->fill($request->all());

// SAFE - Don't flag
User::create($request->validated());
User::create($request->only(['name', 'email']));
```

### Authentication (Critical)
```php
// DANGEROUS - Flag with 90% confidence
// Missing auth middleware on sensitive routes
Route::post('/admin/users', [AdminController::class, 'store']);

// Policy/Gate not used for authorization
public function update(User $user) {
    $user->update($request->all()); // No authorization check
}
```

### File Uploads (High)
```php
// DANGEROUS - Flag with 90% confidence
$request->file('document')->move(public_path('uploads'));

// SAFE - Use storage
Storage::disk('private')->put('documents', $request->file('document'));
```

## Quality Reviewer

**Focus Areas:**

### SOLID Violations

**Single Responsibility:**
```php
// VIOLATION - Class does too much
class OrderController {
    public function store() {
        // Validate, Create, Process, Send, Update, Generate all here
    }
}

// SUGGESTION: Extract to actions/services
```

**Open/Closed:**
```php
// VIOLATION - Modifying existing code for new behavior
public function calculateDiscount(Order $order) {
    if ($order->type === 'retail') return $order->total * 0.1;
    elseif ($order->type === 'wholesale') return $order->total * 0.2;
    elseif ($order->type === 'vip') return $order->total * 0.3; // Requires modification
}

// SUGGESTION: Use strategy pattern
```

### DRY Violations
- Flag when same logic appears 3+ times
- Include specific line numbers and extraction suggestion

### Complexity
- Flag methods with cyclomatic complexity > 10
- Flag classes with > 200 lines
- Flag methods with > 20 lines

## Laravel Best Practices Reviewer

**Focus Areas:**

### N+1 Queries
```php
// PROBLEM - Flag with 90% confidence
foreach (Order::all() as $order) {
    echo $order->customer->name; // N+1!
}

// SOLUTION
Order::with('customer')->get();
```

### Big O Complexity Issues
```php
// PROBLEM - Flag with 90% confidence (O(n²) nested loops)
$users = User::all();
$orders = Order::all();
foreach ($users as $user) {
    foreach ($orders as $order) {
        if ($order->user_id === $user->id) {
            // Process - runs n×m times!
        }
    }
}

// SOLUTION: Use relationships or groupBy
$users = User::with('orders')->get();

// PROBLEM - Flag with 90% confidence (contains() in loop)
$existingEmails = User::pluck('email');
foreach ($newUsers as $userData) {
    if (!$existingEmails->contains($userData['email'])) {
        User::create($userData);
    }
}

// SOLUTION: Use flip() for O(1) lookups
$existingEmails = User::pluck('email')->flip();
foreach ($newUsers as $userData) {
    if (!$existingEmails->has($userData['email'])) {
        User::create($userData);
    }
}

// PROBLEM - Flag with 85% confidence (in-loop queries)
foreach ($orderIds as $orderId) {
    $order = Order::find($orderId); // Query per iteration!
}

// SOLUTION: Batch operations
Order::whereIn('id', $orderIds)->update(['status' => 'processed']);
```

### Facade vs Injection
```php
// SUGGESTION (not critical)
// If dependency injection used elsewhere, suggest consistency
public function store() {
    Cache::put('key', 'value'); // Facade
    $this->repository->save(); // Injected
}
```

### Eloquent Best Practices
```php
// PROBLEM - Flag with 85% confidence
User::where('status', 1)->get(); // Magic number

// SOLUTION
User::where('status', UserStatus::Active)->get();
// Or: User::active()->get();
```

### Event-Driven Architecture
```php
// SUGGESTION - Side effects should use events
public function store() {
    $order = Order::create($data);
    Mail::send(new OrderConfirmation($order)); // Should be event
    Slack::notify('New order!'); // Should be event
}

// SUGGESTION: Fire OrderCreated event with listeners
```

## Testing Reviewer

**Focus Areas:**

### Coverage Gaps
- Flag public methods without corresponding tests
- Flag conditional branches not covered
- Flag edge cases not tested

### Assertion Quality
```php
// WEAK - Flag with 80% confidence
public function test_creates_user() {
    $response = $this->post('/users', $data);
    $response->assertOk(); // Only checks status
}

// STRONG
public function test_creates_user() {
    $response = $this->post('/users', $data);
    $response->assertOk();
    $this->assertDatabaseHas('users', ['email' => $data['email']]);
    $response->assertJsonStructure(['data' => ['id', 'email']]);
}
```

### Test Isolation
- Flag tests that depend on each other
- Flag tests that don't use RefreshDatabase
- Flag tests that rely on specific database state

## DevToolbox Integration Commands

```bash
# Comprehensive scan
php artisan dev:scan --all --format=json

# Security issues
php artisan dev:security:unprotected-routes --format=json

# N+1 detection
php artisan dev:db:n1 --format=json

# Unused routes
php artisan dev:routes:unused --format=json

# Model relationships
php artisan dev:model:graph --format=mermaid

# Slow queries
php artisan dev:db:slow --format=json

# Duplicate queries
php artisan dev:db:duplicates --format=json
```

## Devtoolbox Review Checklist

### Database & Performance
- [ ] Run `php artisan dev:db:n1` - Check for N+1 queries
- [ ] Run `php artisan dev:db:slow` - Identify slow queries
- [ ] Run `php artisan dev:db:duplicates` - Find duplicate queries

### Security
- [ ] Run `php artisan dev:security:unprotected-routes` - Find missing auth
- [ ] Run `php artisan dev:security:audit` - General security scan

### Code Quality
- [ ] Run `php artisan dev:routes:unused` - Remove dead routes
- [ ] Run `php artisan dev:models` - Verify model structure
- [ ] Run `php artisan dev:container:dependencies` - Check DI patterns

### Performance
- [ ] Run `php artisan dev:perf:cache` - Cache efficiency
- [ ] Run `php artisan dev:providers:timeline` - Boot time analysis
