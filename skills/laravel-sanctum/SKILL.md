---
name: laravel-sanctum
description: >
  Implement API authentication with Laravel Sanctum. Use when the user needs API tokens,
  SPA authentication, mobile app authentication, or token abilities/scopes.
  Triggers: "sanctum", "api token", "spa auth", "bearer token", "personal access token",
  "token authentication", "api auth", "mobile auth".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Sanctum Skill

Implement lightweight API authentication with Laravel Sanctum.

## When to Use

- API token authentication for mobile apps
- SPA (Single Page Application) authentication
- First-party API authentication
- Personal access tokens
- Token abilities/scopes
- Simple API authentication (not OAuth)

## Quick Start

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

## Installation

```bash
# Install Sanctum
composer require laravel/sanctum

# Publish config and migrations
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# Run migrations
php artisan migrate
```

## User Model Setup

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    // ...
}
```

## API Token Authentication

### Issuing Tokens

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class TokenController extends Controller
{
    public function store(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        // Create token with abilities
        $token = $user->createToken(
            $request->device_name ?? 'default',
            ['read', 'write'] // Abilities
        );

        return response()->json([
            'token' => $token->plainTextToken,
            'user' => $user,
        ]);
    }

    public function destroy(): JsonResponse
    {
        // Revoke current token
        request()->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Token revoked']);
    }
}
```

### Protecting Routes

```php
<?php

// routes/api.php
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::apiResource('posts', PostController::class);
});
```

### Using Tokens

```bash
# Include token in Authorization header
curl -X GET https://api.example.com/user \
  -H "Authorization: Bearer 1|abc123..."
```

## Token Abilities (Scopes)

### Creating Tokens with Abilities

```php
// Token with specific abilities
$token = $user->createToken('api-token', ['posts:read', 'posts:write']);

// Token with all abilities
$token = $user->createToken('admin-token', ['*']);
```

### Checking Abilities

```php
<?php

namespace App\Http\Controllers;

class PostController extends Controller
{
    public function index(Request $request)
    {
        // Check if token can read posts
        if (! $request->user()->tokenCan('posts:read')) {
            abort(403, 'Insufficient permissions');
        }

        return Post::all();
    }

    public function store(Request $request)
    {
        if (! $request->user()->tokenCan('posts:write')) {
            abort(403, 'Insufficient permissions');
        }

        return Post::create($request->validated());
    }
}
```

### Middleware for Abilities

```php
// routes/api.php
Route::middleware(['auth:sanctum', 'abilities:posts:read'])->group(function () {
    Route::get('/posts', [PostController::class, 'index']);
});

Route::middleware(['auth:sanctum', 'ability:posts:write'])->group(function () {
    Route::post('/posts', [PostController::class, 'store']);
});
```

## SPA Authentication

### Configuration

```php
<?php

// config/sanctum.php
return [
    'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
        '%s%s',
        'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
        env('APP_URL') ? ','.parse_url(env('APP_URL'), PHP_URL_HOST) : ''
    ))),
];
```

```env
# .env
SANCTUM_STATEFUL_DOMAINS=localhost:3000,localhost:5173,your-spa.com
SESSION_DOMAIN=.your-domain.com
```

### CORS Configuration

```php
<?php

// config/cors.php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_origins' => [env('FRONTEND_URL', 'http://localhost:3000')],
    'supports_credentials' => true,
];
```

### SPA Login Flow

```javascript
// Frontend (Vue/React)
// 1. Get CSRF cookie
await axios.get('/sanctum/csrf-cookie');

// 2. Login (session-based)
await axios.post('/login', {
    email: 'user@example.com',
    password: 'password',
});

// 3. Make authenticated requests
const response = await axios.get('/api/user');
```

### Backend SPA Routes

```php
<?php

// routes/web.php
use App\Http\Controllers\Auth\AuthenticatedSessionController;

Route::post('/login', [AuthenticatedSessionController::class, 'store']);
Route::post('/logout', [AuthenticatedSessionController::class, 'destroy']);
```

## Token Management

### List User Tokens

```php
// Get all tokens
$tokens = $user->tokens;

// Get current token
$currentToken = $request->user()->currentAccessToken();
```

### Revoke Tokens

```php
// Revoke specific token
$user->tokens()->where('id', $tokenId)->delete();

// Revoke all tokens
$user->tokens()->delete();

// Revoke current token
$request->user()->currentAccessToken()->delete();

// Revoke all tokens except current
$user->tokens()
    ->where('id', '!=', $request->user()->currentAccessToken()->id)
    ->delete();
```

### Token Expiration

```php
<?php

// config/sanctum.php
return [
    'expiration' => 60 * 24 * 7, // 7 days in minutes
];
```

```php
// Check if token is expired in middleware
public function handle($request, Closure $next)
{
    $token = $request->user()->currentAccessToken();

    if ($token->expires_at && $token->expires_at->isPast()) {
        $token->delete();
        return response()->json(['message' => 'Token expired'], 401);
    }

    return $next($request);
}
```

## API Authentication Controller

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'device_name' => ['required', 'string'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken($validated['device_name']);

        return response()->json([
            'user' => $user,
            'token' => $token->plainTextToken,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
            'device_name' => ['required'],
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        return response()->json([
            'user' => $user,
            'token' => $user->createToken($request->device_name)->plainTextToken,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }

    public function user(Request $request): JsonResponse
    {
        return response()->json($request->user());
    }
}
```

## Testing

```php
<?php

use App\Models\User;
use Laravel\Sanctum\Sanctum;

it('authenticates with token', function () {
    $user = User::factory()->create();

    Sanctum::actingAs($user, ['posts:read']);

    $response = $this->getJson('/api/posts');

    $response->assertOk();
});

it('denies access without proper ability', function () {
    $user = User::factory()->create();

    Sanctum::actingAs($user, ['posts:read']); // No write ability

    $response = $this->postJson('/api/posts', [
        'title' => 'Test Post',
    ]);

    $response->assertForbidden();
});

it('issues token on login', function () {
    $user = User::factory()->create([
        'password' => Hash::make('password'),
    ]);

    $response = $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'test',
    ]);

    $response->assertOk()
        ->assertJsonStructure(['user', 'token']);
});
```

## Common Pitfalls

1. **Missing HasApiTokens Trait**
   ```php
   // User model must use HasApiTokens
   use Laravel\Sanctum\HasApiTokens;

   class User extends Authenticatable
   {
       use HasApiTokens;
   }
   ```

2. **Wrong Middleware for SPA**
   ```php
   // SPA uses session auth, not token auth
   // Ensure EnsureFrontendRequestsAreStateful middleware
   'api' => [
       \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
       'throttle:api',
   ],
   ```

3. **CORS Issues with SPA**
   ```php
   // config/cors.php
   'supports_credentials' => true, // Required!
   ```

4. **Storing Plain Text Token**
   ```php
   // Token is only available once at creation
   $token = $user->createToken('name');
   $plainToken = $token->plainTextToken; // Store this!

   // After creation, only hashed version available
   ```

5. **Not Checking Token Abilities**
   ```php
   // Always check abilities for sensitive operations
   if (! $request->user()->tokenCan('admin')) {
       abort(403);
   }
   ```

6. **Missing CSRF Cookie for SPA**
   ```javascript
   // SPA must request CSRF cookie first
   await axios.get('/sanctum/csrf-cookie');
   await axios.post('/login', credentials);
   ```

## Best Practices

- Use abilities to scope token permissions
- Set token expiration for security
- Revoke tokens on password change
- Use device names to identify tokens
- Implement token refresh mechanism
- Rate limit authentication endpoints
- Log authentication events
- Use HTTPS in production
- Validate token abilities in controllers
- Clean up expired tokens regularly

## Related Commands

- `/laravel-agent:auth:setup` - Setup authentication

## Related Skills

- `laravel-auth` - Authentication and authorization
- `laravel-api` - API development
