---
name: laravel-security
description: >
  Secure Laravel applications with OWASP best practices, authentication,
  authorization, and security auditing. Use when the user mentions security,
  vulnerabilities, authentication issues, or authorization. Triggers: "security",
  "vulnerability", "XSS", "SQL injection", "CSRF", "auth", "permission", "audit",
  "OWASP", "secure", "hack", "attack".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Security Skill

Implement robust security for Laravel applications.

## When to Use

- Security audits needed
- Authentication/authorization setup
- Fixing vulnerabilities
- Implementing security headers
- Rate limiting and throttling

## Quick Start

```bash
/laravel-agent:security:audit
```

## Security Checklist

### Authentication
```php
// Use built-in features
Auth::attempt($credentials);
Hash::make($password);
Hash::check($password, $hashed);

// Session security
'secure' => true,  // HTTPS only cookies
'http_only' => true,
'same_site' => 'lax',
```

### Authorization
```php
// Gates
Gate::define('edit-post', fn (User $user, Post $post) =>
    $user->id === $post->user_id
);

// Policies
class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}

// In controller
$this->authorize('update', $post);
```

### Input Validation
```php
// Always validate
$validated = $request->validate([
    'email' => 'required|email|max:255',
    'name' => 'required|string|max:255',
]);

// Never trust user input
$user->name = strip_tags($validated['name']);
```

### SQL Injection Prevention
```php
// Use Eloquent or Query Builder (safe)
User::where('email', $email)->first();

// Use bindings for raw queries
DB::select('SELECT * FROM users WHERE email = ?', [$email]);

// NEVER do this
DB::select("SELECT * FROM users WHERE email = '$email'"); // VULNERABLE!
```

### XSS Prevention
```blade
{{-- Auto-escaped (safe) --}}
{{ $userInput }}

{{-- Only use when intentionally rendering HTML --}}
{!! $trustedHtml !!}
```

### CSRF Protection
```blade
<form method="POST">
    @csrf
    <!-- form fields -->
</form>
```

### Security Headers
```php
// In middleware or config
return $response->withHeaders([
    'X-Content-Type-Options' => 'nosniff',
    'X-Frame-Options' => 'DENY',
    'X-XSS-Protection' => '1; mode=block',
    'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy' => "default-src 'self'",
]);
```

### Rate Limiting
```php
// In RouteServiceProvider
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

// In routes
Route::middleware(['throttle:api'])->group(function () {
    // API routes
});
```

## OWASP Top 10 Coverage

| Vulnerability | Laravel Protection |
|--------------|-------------------|
| Injection | Eloquent, Query Builder, Validation |
| Broken Auth | Built-in auth, session management |
| XSS | Blade auto-escaping |
| CSRF | @csrf token |
| Broken Access | Gates, Policies |
| Security Misconfig | .env, config caching |
| Sensitive Data | Encryption, HTTPS |
| Components | Composer audit |
| Logging | Laravel logging |

## Password Rules

```php
use Illuminate\Validation\Rules\Password;

// In Form Request
public function rules(): array
{
    return [
        'password' => [
            'required',
            'confirmed',
            Password::min(8)
                ->letters()
                ->mixedCase()
                ->numbers()
                ->symbols()
                ->uncompromised(), // Check HaveIBeenPwned
        ],
    ];
}

// Set defaults in AppServiceProvider
Password::defaults(function () {
    return app()->isProduction()
        ? Password::min(8)->letters()->mixedCase()->numbers()->symbols()->uncompromised()
        : Password::min(8);
});
```

## Security Middleware

```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

final class SecurityHeaders
{
    public function handle(Request $request, Closure $next)
    {
        $response = $next($request);

        return $response->withHeaders([
            'X-Content-Type-Options' => 'nosniff',
            'X-Frame-Options' => 'DENY',
            'X-XSS-Protection' => '1; mode=block',
            'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
            'Referrer-Policy' => 'strict-origin-when-cross-origin',
            'Permissions-Policy' => 'camera=(), microphone=(), geolocation=()',
            'Content-Security-Policy' => $this->buildCSP(),
        ]);
    }

    private function buildCSP(): string
    {
        return implode('; ', [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline'",
            "style-src 'self' 'unsafe-inline'",
            "img-src 'self' data: https:",
            "font-src 'self'",
            "frame-ancestors 'none'",
        ]);
    }
}
```

## Encrypted Model Attributes

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Support\Facades\Crypt;

final class User extends Model
{
    protected function ssn(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => $value ? Crypt::decryptString($value) : null,
            set: fn ($value) => $value ? Crypt::encryptString($value) : null,
        );
    }

    // Or use built-in cast
    protected function casts(): array
    {
        return [
            'api_key' => 'encrypted',
            'settings' => 'encrypted:array',
        ];
    }
}
```

## Audit Logging

```php
// Log security events
Log::channel('security')->info('User login', [
    'user_id' => $user->id,
    'ip' => $request->ip(),
    'user_agent' => $request->userAgent(),
]);

// Log suspicious activity
Log::channel('security')->warning('Failed login attempt', [
    'email' => $request->email,
    'ip' => $request->ip(),
    'attempts' => RateLimiter::attempts($key),
]);
```

## Common Pitfalls

1. **Using `$guarded = []`** - Allows mass assignment attacks
   ```php
   // Bad
   protected $guarded = [];

   // Good - explicit fillable
   protected $fillable = ['name', 'email'];
   ```

2. **Trusting User Input in Raw Queries**
   ```php
   // DANGEROUS
   DB::statement("UPDATE users SET role = '{$request->role}'");

   // Safe
   DB::statement('UPDATE users SET role = ?', [$request->role]);
   ```

3. **Exposing Sensitive Data in Errors**
   ```php
   // config/app.php - in production
   'debug' => false,

   // Custom error messages
   abort(404, 'Resource not found'); // Don't expose internals
   ```

4. **Missing Authorization Checks**
   ```php
   // Bad - no auth check
   public function update(Request $request, Post $post)
   {
       $post->update($request->all());
   }

   // Good
   public function update(Request $request, Post $post)
   {
       $this->authorize('update', $post);
       $post->update($request->validated());
   }
   ```

5. **Storing Tokens/Secrets in Logs**
   ```php
   // Bad
   Log::info('Payment processed', $request->all());

   // Good
   Log::info('Payment processed', [
       'amount' => $request->amount,
       'card_last4' => substr($request->card_number, -4),
   ]);
   ```

6. **Not Rate Limiting Sensitive Endpoints**
   ```php
   // routes/web.php
   Route::post('/login', [AuthController::class, 'login'])
       ->middleware('throttle:5,1'); // 5 attempts per minute
   ```

7. **Weak Session Configuration**
   ```php
   // config/session.php
   'secure' => true,        // HTTPS only
   'http_only' => true,     // No JS access
   'same_site' => 'strict', // Strict CSRF protection
   'expire_on_close' => true, // For sensitive apps
   ```

## Package Integration

- **spatie/laravel-permission** - Role-based access control
- **spatie/crypto** - Encryption utilities
- **laravel/sanctum** - API token authentication
- **laravel/passport** - OAuth2 server
- **paragonie/ciphersweet** - Searchable encryption

## Best Practices

- Never store secrets in code
- Use .env for sensitive config
- Keep dependencies updated
- Enable HTTPS in production
- Use prepared statements
- Validate all input
- Log security events
- Use Content Security Policy
- Implement proper session management
- Regular security audits with `composer audit`

## Related Commands

- `/laravel-agent:security:audit` - Run security audit

## Related Agents

- `laravel-security` - Security audit specialist

## Related Skills

- `laravel-auth` - Authentication and authorization
