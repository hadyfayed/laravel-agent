# Security Analysis Checklist

## SQL Injection

### Raw queries with user input

```php
// DETECTED: User input directly in query
DB::select("SELECT * FROM orders WHERE user_id = " . $userId);

// FIX: Use parameterized queries
DB::select("SELECT * FROM orders WHERE user_id = ?", [$userId]);
// OR
Order::where('user_id', $userId)->get();
```

### LIKE queries without escaping

```php
// DETECTED: User input in LIKE clause
$search = $_GET['search'];
DB::select("SELECT * FROM users WHERE name LIKE '%" . $search . "%'");

// FIX: Use LIKE with parameter binding
$search = '%' . $input . '%';
User::where('name', 'LIKE', $search)->get();
```

## Cross-Site Scripting (XSS)

### Unescaped output with {!!}

```php
// DETECTED: User data with unescaped output
{{ $post->description !!}}  // Danger if description contains scripts

// FIX: Use {{ }} for HTML escaping
{{ $post->description }}  // HTML entities escaped

// OR: Sanitize on save
$post->description = clean($input, ['p', 'br', 'strong']);
```

### Vue/JavaScript templates

```php
// DETECTED: Vue without v-text or :text binding
<div>{{{ message }}}</div>  // Old Vue 1 syntax — danger!
<div>{{ message }}</div>  <!-- Safe with Vue 3 -->

// DETECTED: Binding HTML attribute
<a href="{{ url }}">Link</a>  <!-- Safe if url is validated -->
<a :href="userUrl">Link</a>  <!-- Safe if userUrl is bound data -->
```

### JavaScript template literals

```php
// DETECTED: User data in script context
<script>
    const user = "{{ auth()->user()->name }}";  // Safe if quoted
    const bio = "{{ auth()->user()->bio }}";    // DANGER if bio has quotes
</script>

// FIX: Use json_encode and @json()
<script>
    const user = @json(auth()->user()->name);  // Properly escaped
</script>
```

## Cross-Site Request Forgery (CSRF)

### Missing CSRF token

```php
// DETECTED: Form without CSRF token
<form method="POST" action="/orders">
    <input type="text" name="item">
</form>

// FIX: Include token
<form method="POST" action="/orders">
    @csrf
    <input type="text" name="item">
</form>
```

### API requests without CSRF

```php
// DETECTED: AJAX without CSRF token
fetch('/api/orders', {
    method: 'POST',
    body: JSON.stringify({item: 'widget'})
});

// FIX: Include token from meta tag or header
fetch('/api/orders', {
    method: 'POST',
    headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({item: 'widget'})
});
```

## Authorization

### Missing policy checks

```php
// DETECTED: No authorization check
public function show(Order $order)
{
    return $order;  // Any user can view any order!
}

// FIX: Use policy
public function show(Order $order)
{
    $this->authorize('view', $order);
    return $order;
}
```

### Authorization in wrong layer

```php
// DETECTED: Auth check in service (too late)
public function updateOrder($orderId, $data)
{
    // If accessible from controller, already too late
    if (!auth()->user()->can('update')) {
        throw new AuthorizationException;
    }
}

// FIX: Check in controller or route middleware
public function update(UpdateOrderRequest $request, Order $order)
{
    $this->authorize('update', $order);  // Early check
    // ...
}
```

### Broken access control on routes

```php
// DETECTED: No authorization on admin routes
Route::get('/admin/users', [UserController::class, 'index']);

// FIX: Protect with middleware
Route::middleware('auth', 'admin')
    ->get('/admin/users', [UserController::class, 'index']);
```

## Mass Assignment

### Model without $fillable or $guarded

```php
// DETECTED: No mass assignment protection
class User extends Model {
    // No $fillable or $guarded = $user->update(request()->all());
}

// FIX: Define protected fields
class User extends Model {
    protected $fillable = ['name', 'email', 'password'];
    // or
    protected $guarded = ['id', 'is_admin', 'role_id'];
}
```

### $guarded = [] (dangerous)

```php
// DETECTED: All fields assignable
class User extends Model {
    protected $guarded = [];  // Allows overwriting is_admin!
}

// FIX: Use $fillable instead
class User extends Model {
    protected $fillable = ['name', 'email'];
}
```

## Authentication

### Hardcoded credentials

```php
// DETECTED: API key in code
$client = new ApiClient('sk_live_12345abcde');

// FIX: Use environment variables
$client = new ApiClient(env('STRIPE_SECRET_KEY'));
```

### Weak password hashing

```php
// DETECTED: Plain md5 or SHA1
$hash = md5($password);  // BROKEN!

// FIX: Use Laravel's Hash facade
$hash = Hash::make($password);
if (Hash::check($password, $hash)) {
    // Authenticated
}
```

### Session fixation

```php
// DETECTED: No session regeneration after login
Auth::login($user);  // Session ID same before/after

// FIX: Regenerate session
Auth::login($user);
session()->regenerate();
```

## Sensitive Data

### Secrets in logs

```php
// DETECTED: Logging sensitive data
Log::info('User login', ['email' => $user->email, 'password' => $request->password]);

// FIX: Don't log sensitive fields
Log::info('User login', ['email' => $user->email]);
```

### PII in error messages

```php
// DETECTED: Stack trace with user data
try {
    // ...
} catch (Exception $e) {
    response()->json($e);  // Shows user data, query, etc.
}

// FIX: Generic error message in production
try {
    // ...
} catch (Exception $e) {
    Log::error('Error', ['exception' => $e]);
    response()->json(['message' => 'An error occurred'], 500);
}
```

## File Uploads

### Missing validation

```php
// DETECTED: Upload without validation
$file = request()->file('avatar');
$path = $file->store('avatars');

// FIX: Validate first
request()->validate([
    'avatar' => 'required|image|max:2048|mimes:jpg,png,gif'
]);
$path = request()->file('avatar')->store('avatars');
```

### Executable file upload

```php
// DETECTED: No mime validation
request()->validate([
    'file' => 'required|file'  // Allows .php, .sh, etc.!
]);

// FIX: Restrict file types
request()->validate([
    'file' => 'required|file|mimes:pdf,doc,docx|max:5120'
]);
```

### Path traversal in uploads

```php
// DETECTED: User-controlled filename
$filename = request()->input('filename');
Storage::put('uploads/' . $filename, $contents);  // Can be ../../etc/passwd

// FIX: Use hash or whitelist
$filename = uniqid() . '.' . $file->extension();
Storage::put('uploads/' . $filename, $file);
```

## Dependencies

### Vulnerable packages

```bash
DETECTED: Run composer audit
composer audit

# Example vulnerable packages:
- vendor/package: CVE-2024-1234 - RCE in template engine
- other/lib: Arbitrary code execution

# FIX: Update or replace
composer update vendor/package
```

### Abandoned packages

```
DETECTED: Package no longer maintained
vendor/old-lib — Last commit 3 years ago, no security updates

FIX: Replace with maintained alternative or fork
```

## Configuration

### Debug mode in production

```
DETECTED: APP_DEBUG=true in .env.production
Risk: Stack traces expose internal structure, secrets in logs

FIX: Set APP_DEBUG=false
```

### Insecure default settings

```php
// DETECTED: Session settings allow fixation
config/session.php — 'secure' => false, 'http_only' => false

// FIX: Enforce security
'secure' => env('SESSION_SECURE_COOKIES', true),
'http_only' => true,
'same_site' => 'strict',
```

### Unencrypted cookies

```
DETECTED: Sensitive data in plain cookies
Cookies stored as text without encryption

FIX: Use Laravel's encrypted cookies or sessions
request()->cookie('auth_token')  // Already encrypted by middleware
```
