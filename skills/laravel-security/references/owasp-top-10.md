# OWASP Top 10 Coverage for Laravel

How the OWASP Top 10 maps onto Laravel's built-in protections, plus the deeper
implementation patterns (security-header middleware, encrypted attributes,
audit logging) that go beyond the checklist.

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

## Security Headers Middleware

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
