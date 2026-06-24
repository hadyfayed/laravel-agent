# OWASP Top 10 (2021) Detailed Catalog

## A01:2021 - Broken Access Control

### Problems to Find
```php
// BAD: Direct object reference without authorization
Route::get('/users/{id}', function ($id) {
    return User::find($id); // No auth check!
});

// BAD: Mass assignment vulnerability
User::create($request->all()); // Accepts any field!

// BAD: Horizontal privilege escalation
$order = Order::find($id); // User can access any order!
```

### Secure Patterns
```php
// GOOD: Authorize resource access
public function show(User $user)
{
    $this->authorize('view', $user);
    return $user;
}

// GOOD: Scope to authenticated user
$order = auth()->user()->orders()->findOrFail($id);

// GOOD: Use guarded/fillable properly
protected $guarded = ['id', 'role', 'is_admin'];

// GOOD: Policy-based authorization
class OrderPolicy
{
    public function view(User $user, Order $order): bool
    {
        return $user->id === $order->user_id
            || $user->hasPermission('view-all-orders');
    }
}
```

## A02:2021 - Cryptographic Failures

### Problems to Find
```php
// BAD: Storing plaintext passwords
$user->password = $request->password;

// BAD: Weak encryption
$encrypted = encrypt($data); // Without proper key rotation

// BAD: Insecure token generation
$token = rand(1000, 9999); // Predictable!
```

### Secure Patterns
```php
// GOOD: Hash passwords with bcrypt/argon2
$user->password = Hash::make($request->password);

// GOOD: Secure token generation
use Illuminate\Support\Str;
$token = Str::random(64);
$token = bin2hex(random_bytes(32));

// GOOD: Use Laravel's encryption
$encrypted = Crypt::encryptString($sensitiveData);
$decrypted = Crypt::decryptString($encrypted);
```

## A03:2021 - Injection

### SQL Injection
```php
// BAD: Raw SQL with user input
DB::select("SELECT * FROM users WHERE email = '$email'");

// BAD: Dynamic column names
$users = User::orderBy($request->column)->get();

// GOOD: Parameterized queries
DB::select('SELECT * FROM users WHERE email = ?', [$email]);

// GOOD: Eloquent (parameterized by default)
User::where('email', $email)->first();

// GOOD: Whitelist column names
$column = in_array($request->column, ['name', 'email', 'created_at'])
    ? $request->column
    : 'created_at';
User::orderBy($column)->get();
```

### Command Injection
```php
// BAD: Shell command with user input
exec("convert {$request->file} output.jpg");

// GOOD: Escapeshellarg
exec("convert " . escapeshellarg($file) . " output.jpg");

// BETTER: Use process builder
Process::run(['convert', $file, 'output.jpg']);
```

### LDAP Injection
```php
// BAD: Direct LDAP query
$filter = "(uid=$username)";

// GOOD: Escape LDAP special characters
$filter = "(uid=" . ldap_escape($username, '', LDAP_ESCAPE_FILTER) . ")";
```

## A04:2021 - Insecure Design

### Security by Design
```php
// Implement rate limiting
Route::middleware(['throttle:api'])->group(function () {
    // API routes
});

// Custom rate limiting
RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip());
});

// Implement timeouts
config(['session.lifetime' => 120]); // 2 hours

// Secure password requirements
Validator::make($request->all(), [
    'password' => [
        'required',
        'confirmed',
        Password::min(8)
            ->mixedCase()
            ->numbers()
            ->symbols()
            ->uncompromised(),
    ],
]);
```

## A05:2021 - Security Misconfiguration

### Production Checklist
```env
# .env.production
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:securely-generated-key

# Secure session
SESSION_DRIVER=redis
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax

# Disable unnecessary features
DEBUGBAR_ENABLED=false
TELESCOPE_ENABLED=false
```

### Security Headers Middleware
```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class SecurityHeaders
{
    public function handle(Request $request, Closure $next)
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');

        if (app()->environment('production')) {
            $response->headers->set(
                'Strict-Transport-Security',
                'max-age=31536000; includeSubDomains'
            );
        }

        return $response;
    }
}
```

## A06:2021 - Vulnerable Components

### Dependency Audit
```bash
# Check for known vulnerabilities
composer audit

# Update dependencies
composer update --prefer-stable

# Check specific package
composer show laravel/framework --all
```

### Automated Scanning
```yaml
# .github/workflows/security.yml
- name: Security audit
  run: composer audit --format=json

- name: Check for secrets
  uses: trufflesecurity/trufflehog@main
```

## A07:2021 - Authentication Failures

### Secure Authentication
```php
// Rate limit login attempts
Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:5,1'); // 5 attempts per minute

// Account lockout
class LoginController
{
    public function login(Request $request)
    {
        if ($this->hasTooManyLoginAttempts($request)) {
            $this->fireLockoutEvent($request);
            return $this->sendLockoutResponse($request);
        }

        // Authentication logic...
    }
}

// Secure password reset
$token = Password::createToken($user);
// Token expires in 60 minutes by default

// Multi-factor authentication
class User extends Authenticatable
{
    use HasFactory, Notifiable, TwoFactorAuthenticatable;
}
```

## A08:2021 - Software and Data Integrity Failures

### Signed URLs and Routes
```php
// Generate signed URL
$url = URL::signedRoute('unsubscribe', ['user' => $user->id]);
$url = URL::temporarySignedRoute('download', now()->addMinutes(30), ['file' => $fileId]);

// Validate signed route
Route::get('/unsubscribe/{user}', function (Request $request, User $user) {
    if (! $request->hasValidSignature()) {
        abort(401);
    }
    // Process unsubscribe
})->name('unsubscribe')->middleware('signed');
```

### Secure File Uploads
```php
$request->validate([
    'file' => [
        'required',
        'file',
        'mimes:pdf,doc,docx',
        'max:10240', // 10MB
    ],
]);

// Store with random name
$path = $request->file('file')->store('documents', 's3');

// Validate file contents, not just extension
$mimeType = $request->file('file')->getMimeType();
if (!in_array($mimeType, ['application/pdf', 'application/msword'])) {
    abort(422, 'Invalid file type');
}
```

## A09:2021 - Security Logging and Monitoring

### Comprehensive Logging
```php
// Log authentication events
Event::listen(Login::class, function ($event) {
    Log::channel('security')->info('User logged in', [
        'user_id' => $event->user->id,
        'ip' => request()->ip(),
        'user_agent' => request()->userAgent(),
    ]);
});

Event::listen(Failed::class, function ($event) {
    Log::channel('security')->warning('Failed login attempt', [
        'email' => $event->credentials['email'] ?? 'unknown',
        'ip' => request()->ip(),
    ]);
});

// Custom security log channel
// config/logging.php
'channels' => [
    'security' => [
        'driver' => 'daily',
        'path' => storage_path('logs/security.log'),
        'level' => 'debug',
        'days' => 90,
    ],
],
```

## A10:2021 - Server-Side Request Forgery (SSRF)

### Prevent SSRF
```php
// BAD: Fetch arbitrary URL
$response = Http::get($request->url);

// GOOD: Whitelist allowed domains
$allowedDomains = ['api.example.com', 'cdn.example.com'];
$host = parse_url($request->url, PHP_URL_HOST);

if (!in_array($host, $allowedDomains)) {
    abort(403, 'Domain not allowed');
}

// GOOD: Use URL validation
$request->validate([
    'url' => ['required', 'url', 'active_url', new AllowedDomain],
]);
```

## Content Security Policy

If `spatie/laravel-csp` is installed:

```php
// app/Support/Csp/Policies/AppPolicy.php
use Spatie\Csp\Directive;
use Spatie\Csp\Keyword;
use Spatie\Csp\Policies\Basic;

class AppPolicy extends Basic
{
    public function configure()
    {
        parent::configure();

        $this
            ->addDirective(Directive::SCRIPT, Keyword::SELF)
            ->addDirective(Directive::SCRIPT, 'https://cdn.example.com')
            ->addDirective(Directive::STYLE, Keyword::SELF)
            ->addDirective(Directive::STYLE, Keyword::UNSAFE_INLINE) // For Tailwind
            ->addDirective(Directive::IMG, Keyword::SELF)
            ->addDirective(Directive::IMG, 'data:')
            ->addDirective(Directive::FONT, Keyword::SELF)
            ->addDirective(Directive::FONT, 'https://fonts.gstatic.com')
            ->addDirective(Directive::CONNECT, Keyword::SELF)
            ->addDirective(Directive::FRAME_ANCESTORS, Keyword::SELF);
    }
}
```

## CORS Configuration

```php
// config/cors.php
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    'allowed_origins' => [
        env('FRONTEND_URL', 'https://app.example.com'),
    ],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Content-Type', 'Authorization', 'X-Requested-With'],
    'exposed_headers' => [],
    'max_age' => 86400,
    'supports_credentials' => true,
];
```

## Spatie/Crypto (Encryption & Signatures)

If `spatie/crypto` is installed:

```php
use Spatie\Crypto\Rsa\KeyPair;

// Generate key pair
$keyPair = KeyPair::generate();
file_put_contents('private.key', $keyPair->privateKey);
file_put_contents('public.key', $keyPair->publicKey);

// Encrypt/Decrypt
$privateKey = PrivateKey::fromFile('/path/to/private.key');
$encrypted = $privateKey->encrypt('secret data');

$publicKey = PublicKey::fromFile('/path/to/public.key');
$decrypted = $publicKey->decrypt($encrypted);

// Digital Signatures
$signature = $privateKey->sign('data to sign');
$isValid = $publicKey->verify('data to sign', $signature);
```
