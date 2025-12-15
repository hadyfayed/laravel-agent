# Laravel Security Guidelines

Security best practices for Laravel applications.

## Input Validation

### Always Validate Input
Never trust user input. Always validate using Form Requests:

```php
final class StoreProductRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'price' => ['required', 'numeric', 'min:0'],
            'email' => ['required', 'email', 'unique:users'],
        ];
    }
}
```

### Sanitize Output
Blade automatically escapes output. Only use `{!! !!}` when intentional:

```blade
{{-- Safe - automatically escaped --}}
{{ $userInput }}

{{-- Dangerous - use only for trusted HTML --}}
{!! $trustedHtml !!}
```

## SQL Injection Prevention

### Use Eloquent/Query Builder
```php
// GOOD - parameterized
User::where('email', $email)->first();

// GOOD - bindings
DB::select('SELECT * FROM users WHERE email = ?', [$email]);

// BAD - vulnerable
DB::select("SELECT * FROM users WHERE email = '$email'");
```

## Authentication

### Password Hashing
Always use Laravel's Hash facade:

```php
// Hashing
$hashed = Hash::make($password);

// Verification
if (Hash::check($password, $user->password)) {
    // Valid
}
```

### Session Security
```php
// config/session.php
'secure' => true,          // HTTPS only
'http_only' => true,       // No JavaScript access
'same_site' => 'lax',      // CSRF protection
```

### Regenerate Session on Login
```php
public function login(Request $request)
{
    if (Auth::attempt($credentials)) {
        $request->session()->regenerate();
        return redirect()->intended();
    }
}
```

## Authorization

### Always Check Permissions
```php
// In controller
$this->authorize('update', $post);

// Or use policy
if ($user->cannot('update', $post)) {
    abort(403);
}
```

### Use Policies for Models
```php
final class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

## CSRF Protection

### Include Token in Forms
```blade
<form method="POST" action="/posts">
    @csrf
    <!-- form fields -->
</form>
```

### For AJAX Requests
```javascript
// Include in headers
headers: {
    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
}
```

## XSS Prevention

### Content Security Policy
```php
// Middleware
return $response->withHeaders([
    'Content-Security-Policy' => "default-src 'self'",
]);
```

### Escape User Content
```php
// In PHP
$safe = htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8');

// In Blade (automatic)
{{ $userInput }}
```

## Rate Limiting

### Protect Authentication
```php
RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip());
});

// In routes
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:login');
```

### Protect APIs
```php
RateLimiter::for('api', function (Request $request) {
    return $request->user()
        ? Limit::perMinute(60)->by($request->user()->id)
        : Limit::perMinute(10)->by($request->ip());
});
```

## Sensitive Data

### Never Log Secrets
```php
// BAD
Log::info('Payment processed', ['card' => $cardNumber]);

// GOOD
Log::info('Payment processed', ['last4' => substr($cardNumber, -4)]);
```

### Use Environment Variables
```php
// GOOD
$apiKey = config('services.stripe.key');

// BAD
$apiKey = 'sk_live_xxx';
```

### Encrypt Sensitive Data
```php
// Encrypt
$encrypted = Crypt::encryptString($ssn);

// Decrypt
$decrypted = Crypt::decryptString($encrypted);
```

## File Uploads

### Validate File Types
```php
$request->validate([
    'document' => ['required', 'file', 'mimes:pdf,doc,docx', 'max:10240'],
    'image' => ['required', 'image', 'max:5120'],
]);
```

### Store Outside Web Root
```php
// Store in storage, not public
$path = $request->file('document')->store('documents');
```

## HTTPS

### Force HTTPS in Production
```php
// AppServiceProvider
if (app()->isProduction()) {
    URL::forceScheme('https');
}
```

### Secure Cookies
```php
// config/session.php
'secure' => env('SESSION_SECURE_COOKIE', true),
```

## Security Headers

```php
// Middleware
return $response->withHeaders([
    'X-Content-Type-Options' => 'nosniff',
    'X-Frame-Options' => 'DENY',
    'X-XSS-Protection' => '1; mode=block',
    'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
    'Referrer-Policy' => 'strict-origin-when-cross-origin',
]);
```

## Dependency Security

### Regular Audits
```bash
composer audit
```

### Keep Updated
```bash
composer update --with-dependencies
```

## Checklist

- [ ] All input validated
- [ ] Output escaped
- [ ] SQL parameterized
- [ ] CSRF protection enabled
- [ ] Authentication rate limited
- [ ] Passwords properly hashed
- [ ] Sessions secure
- [ ] HTTPS enforced
- [ ] Dependencies audited
- [ ] Sensitive data encrypted
