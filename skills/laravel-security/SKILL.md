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

## Package Integration

- **spatie/laravel-permission** - Role-based access control
- **spatie/crypto** - Encryption utilities
- **laravel/sanctum** - API token authentication
- **laravel/passport** - OAuth2 server

## Best Practices

- Never store secrets in code
- Use .env for sensitive config
- Keep dependencies updated
- Enable HTTPS in production
- Use prepared statements
- Validate all input
- Log security events
