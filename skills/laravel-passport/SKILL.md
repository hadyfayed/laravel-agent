---
name: laravel-passport
description: >
  Implement OAuth2 server with Laravel Passport. Use when the user needs OAuth2,
  third-party API access, authorization codes, client credentials, or personal access tokens.
  Triggers: "passport", "oauth2 server", "authorization code", "client credentials",
  "access token", "refresh token", "oauth provider".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Passport Skill

Implement full-featured OAuth2 server with Laravel Passport for third-party API access.

## When to Use

Use **Passport** when:
- Building an OAuth2 authorization server
- Third-party applications need to access your API
- Need all OAuth2 grant types (authorization code, client credentials, password, implicit)
- Require refresh tokens with rotation
- Building a platform with API consumers

Use **Sanctum** instead when:
- Building first-party SPAs or mobile apps
- Simple token authentication is sufficient
- Don't need OAuth2 complexity
- Want lighter weight solution

## Quick Start

```bash
composer require laravel/passport
php artisan migrate
php artisan passport:install
```

## Installation

### Step 1: Install Package

```bash
composer require laravel/passport
```

### Step 2: Run Migrations

```bash
# Migrate creates oauth tables
php artisan migrate
```

### Step 3: Install Passport

```bash
# Generate encryption keys and personal access/password grant clients
php artisan passport:install

# Optional: use --uuids for UUID keys instead of auto-increment
php artisan passport:install --uuids
```

Output:
```
Encryption keys generated successfully.
Personal access client created successfully.
Password grant client created successfully.
```

### Step 4: Configure User Model

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Passport\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    // ...
}
```

### Step 5: Configure AuthServiceProvider

```php
<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Laravel\Passport\Passport;

class AuthServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // Optional: Load Passport routes
        // Passport::ignoreRoutes(); // If handling routes manually

        // Token lifetimes
        Passport::tokensExpireIn(now()->addDays(15));
        Passport::refreshTokensExpireIn(now()->addDays(30));
        Passport::personalAccessTokensExpireIn(now()->addMonths(6));

        // Prune revoked tokens and expired tokens
        Passport::pruneRevokedTokens();
    }
}
```

### Step 6: Configure Authentication Guard

```php
<?php

// config/auth.php
return [
    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'passport', // Changed from 'token'
            'provider' => 'users',
            'hash' => false,
        ],
    ],
];
```

### Step 7: Protect API Routes

```php
<?php

// routes/api.php
use Illuminate\Support\Facades\Route;

Route::middleware('auth:api')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());
    Route::apiResource('posts', PostController::class);
});
```

## OAuth2 Grant Types

### 1. Authorization Code Grant (Most Secure)

**Use Case:** Third-party web applications

#### Step 1: Create OAuth Client

```bash
php artisan passport:client
```

Options:
- User ID (leave empty for public client)
- Client name
- Redirect URI

Output:
```
Client ID: 1
Client Secret: abc123...
```

#### Step 2: Authorization Request

```http
GET /oauth/authorize?client_id=1
    &redirect_uri=https://client-app.com/callback
    &response_type=code
    &scope=read-posts write-posts
    &state=random_state_string
```

#### Step 3: User Approves

```blade
<!-- resources/views/vendor/passport/authorize.blade.php -->
@extends('layouts.app')

@section('content')
<div class="container">
    <h2>Authorization Request</h2>
    <p><strong>{{ $client->name }}</strong> is requesting permission to access your account.</p>

    <h4>Scopes:</h4>
    <ul>
        @foreach ($scopes as $scope)
            <li>{{ $scope->description }}</li>
        @endforeach
    </ul>

    <form method="post" action="{{ route('passport.authorizations.approve') }}">
        @csrf
        <input type="hidden" name="state" value="{{ $request->state }}">
        <input type="hidden" name="client_id" value="{{ $client->id }}">
        <input type="hidden" name="auth_token" value="{{ $authToken }}">

        <button type="submit" class="btn btn-success">Authorize</button>
    </form>

    <form method="post" action="{{ route('passport.authorizations.deny') }}">
        @csrf
        @method('DELETE')
        <input type="hidden" name="state" value="{{ $request->state }}">
        <input type="hidden" name="client_id" value="{{ $client->id }}">
        <input type="hidden" name="auth_token" value="{{ $authToken }}">

        <button type="submit" class="btn btn-danger">Cancel</button>
    </form>
</div>
@endsection
```

#### Step 4: Exchange Code for Token

```http
POST /oauth/token
Content-Type: application/json

{
    "grant_type": "authorization_code",
    "client_id": "1",
    "client_secret": "abc123...",
    "redirect_uri": "https://client-app.com/callback",
    "code": "def456..."
}
```

Response:
```json
{
    "token_type": "Bearer",
    "expires_in": 1296000,
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "def502..."
}
```

#### Step 5: Use Access Token

```http
GET /api/user
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

### 2. Client Credentials Grant (Machine-to-Machine)

**Use Case:** Server-to-server communication, no user context

#### Create Client

```bash
php artisan passport:client --client
```

#### Request Token

```http
POST /oauth/token
Content-Type: application/json

{
    "grant_type": "client_credentials",
    "client_id": "2",
    "client_secret": "xyz789...",
    "scope": "read-data"
}
```

#### Protect Routes

```php
Route::middleware(['client'])->group(function () {
    Route::get('/api/stats', [StatsController::class, 'index']);
});
```

### 3. Password Grant (First-Party Apps)

**Use Case:** Your own mobile/desktop apps (Deprecated in OAuth2.1)

#### Create Password Grant Client

```bash
php artisan passport:client --password
```

#### Request Token

```http
POST /oauth/token
Content-Type: application/json

{
    "grant_type": "password",
    "client_id": "3",
    "client_secret": "secret123...",
    "username": "user@example.com",
    "password": "password",
    "scope": "*"
}
```

**Warning:** Password grant is deprecated. Use Authorization Code with PKCE for mobile apps.

### 4. Implicit Grant (Deprecated)

**Use Case:** JavaScript SPAs (No longer recommended)

```http
GET /oauth/authorize?client_id=4
    &redirect_uri=https://spa.com/callback
    &response_type=token
    &scope=read-posts
```

**Warning:** Implicit grant is insecure. Use Authorization Code with PKCE instead.

### 5. Authorization Code with PKCE (Recommended for SPAs/Mobile)

**Most secure option for public clients**

#### Step 1: Generate Code Verifier and Challenge

```javascript
// Generate random code_verifier
const codeVerifier = generateRandomString(128);

// Generate code_challenge (SHA256 hash)
const codeChallenge = await sha256(codeVerifier);

localStorage.setItem('code_verifier', codeVerifier);
```

#### Step 2: Authorization Request

```http
GET /oauth/authorize?client_id=5
    &redirect_uri=https://app.com/callback
    &response_type=code
    &scope=read-posts
    &code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
    &code_challenge_method=S256
```

#### Step 3: Exchange Code (No Secret Required)

```http
POST /oauth/token

{
    "grant_type": "authorization_code",
    "client_id": "5",
    "redirect_uri": "https://app.com/callback",
    "code": "def456...",
    "code_verifier": "the_original_verifier"
}
```

## Token Scopes

### Define Scopes

```php
<?php

// app/Providers/AuthServiceProvider.php
use Laravel\Passport\Passport;

public function boot(): void
{
    Passport::tokensCan([
        'read-posts' => 'Read posts',
        'write-posts' => 'Create and edit posts',
        'delete-posts' => 'Delete posts',
        'admin' => 'Full administrative access',
    ]);

    Passport::setDefaultScope([
        'read-posts',
    ]);
}
```

### Check Scopes in Controller

```php
<?php

namespace App\Http\Controllers\Api;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function store(Request $request)
    {
        if (! $request->user()->tokenCan('write-posts')) {
            return response()->json(['error' => 'Insufficient permissions'], 403);
        }

        return Post::create($request->validated());
    }

    public function destroy(Request $request, Post $post)
    {
        if (! $request->user()->tokenCan('delete-posts')) {
            abort(403);
        }

        $post->delete();

        return response()->json(['message' => 'Post deleted']);
    }
}
```

### Scope Middleware

```php
// routes/api.php
Route::middleware(['auth:api', 'scope:write-posts'])->group(function () {
    Route::post('/posts', [PostController::class, 'store']);
});

// Multiple scopes (any)
Route::middleware(['auth:api', 'scopes:write-posts,admin'])->group(function () {
    Route::put('/posts/{post}', [PostController::class, 'update']);
});

// Multiple scopes (all required)
Route::middleware(['auth:api', 'scope:write-posts,admin'])->group(function () {
    Route::delete('/posts/{post}', [PostController::class, 'destroy']);
});
```

## Personal Access Tokens

### Create Token via UI

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PersonalAccessTokenController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'scopes' => ['array'],
        ]);

        $token = $request->user()->createToken(
            $request->name,
            $request->scopes ?? []
        );

        return response()->json([
            'token' => $token->accessToken,
            'token_id' => $token->token->id,
        ]);
    }

    public function index(Request $request)
    {
        return $request->user()->tokens;
    }

    public function destroy(Request $request, string $tokenId)
    {
        $request->user()->tokens()->where('id', $tokenId)->delete();

        return response()->json(['message' => 'Token revoked']);
    }
}
```

### Blade Component for Token Management

```blade
<!-- resources/views/tokens/index.blade.php -->
@extends('layouts.app')

@section('content')
<div class="container">
    <h2>Personal Access Tokens</h2>

    <form method="POST" action="{{ route('tokens.store') }}">
        @csrf
        <input type="text" name="name" placeholder="Token name" required>

        <label>
            <input type="checkbox" name="scopes[]" value="read-posts"> Read Posts
        </label>
        <label>
            <input type="checkbox" name="scopes[]" value="write-posts"> Write Posts
        </label>

        <button type="submit">Create Token</button>
    </form>

    <h3>Your Tokens</h3>
    @foreach ($tokens as $token)
        <div>
            <strong>{{ $token->name }}</strong>
            <small>Created: {{ $token->created_at->diffForHumans() }}</small>

            <form method="POST" action="{{ route('tokens.destroy', $token->id) }}">
                @csrf
                @method('DELETE')
                <button type="submit">Revoke</button>
            </form>
        </div>
    @endforeach
</div>
@endsection
```

## OAuth Client Management

### List User's Clients

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Laravel\Passport\Client;

class OAuthClientController extends Controller
{
    public function index(Request $request)
    {
        return $request->user()->clients;
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'redirect' => ['required', 'url'],
        ]);

        $client = $request->user()->clients()->create([
            'name' => $request->name,
            'redirect' => $request->redirect,
            'personal_access_client' => false,
            'password_client' => false,
            'revoked' => false,
        ]);

        return response()->json($client, 201);
    }

    public function update(Request $request, Client $client)
    {
        $this->authorize('update', $client);

        $client->update($request->validate([
            'name' => ['string', 'max:255'],
            'redirect' => ['url'],
        ]));

        return response()->json($client);
    }

    public function destroy(Request $request, Client $client)
    {
        $this->authorize('delete', $client);

        $client->delete();

        return response()->json(['message' => 'Client deleted']);
    }
}
```

### Client Policy

```php
<?php

namespace App\Policies;

use App\Models\User;
use Laravel\Passport\Client;

class ClientPolicy
{
    public function update(User $user, Client $client): bool
    {
        return $user->id === $client->user_id;
    }

    public function delete(User $user, Client $client): bool
    {
        return $user->id === $client->user_id;
    }
}
```

## Consuming Your Own API

### From JavaScript (First-Party)

```javascript
// Using session-based auth
window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

// Make request
axios.get('/api/user')
    .then(response => console.log(response.data));
```

### From External App (Third-Party)

```javascript
// Using access token
const response = await fetch('https://api.example.com/api/posts', {
    headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Accept': 'application/json',
    }
});

const data = await response.json();
```

### Refresh Tokens

```javascript
async function refreshAccessToken(refreshToken) {
    const response = await fetch('/oauth/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            grant_type: 'refresh_token',
            refresh_token: refreshToken,
            client_id: clientId,
            client_secret: clientSecret,
            scope: '',
        }),
    });

    const data = await response.json();
    return {
        accessToken: data.access_token,
        refreshToken: data.refresh_token,
    };
}
```

## Token Lifetimes

```php
<?php

// app/Providers/AuthServiceProvider.php
use Laravel\Passport\Passport;

public function boot(): void
{
    // Access tokens expire in 15 days
    Passport::tokensExpireIn(now()->addDays(15));

    // Refresh tokens expire in 30 days
    Passport::refreshTokensExpireIn(now()->addDays(30));

    // Personal access tokens expire in 6 months
    Passport::personalAccessTokensExpireIn(now()->addMonths(6));

    // Prune revoked/expired tokens (run in scheduled command)
    Passport::pruneRevokedTokens();
}
```

### Scheduled Token Pruning

```php
<?php

// app/Console/Kernel.php
protected function schedule(Schedule $schedule): void
{
    $schedule->command('passport:purge')->daily();
}
```

## Revoking Tokens

### Revoke User's Token

```php
// Revoke current access token
$request->user()->token()->revoke();

// Revoke all user tokens
$user->tokens->each->revoke();

// Revoke specific token by ID
$token = $user->tokens()->find($tokenId);
$token->revoke();
```

### Revoke on Password Change

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Hash;

class PasswordController extends Controller
{
    public function update(Request $request)
    {
        $request->validate([
            'current_password' => ['required', 'current_password'],
            'password' => ['required', 'confirmed', 'min:8'],
        ]);

        $user = $request->user();

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        // Revoke all tokens on password change
        $user->tokens->each->revoke();

        return response()->json(['message' => 'Password updated']);
    }
}
```

### Revoke on Logout

```php
public function logout(Request $request)
{
    // Revoke current token
    $request->user()->token()->revoke();

    // Optional: revoke all refresh tokens
    $request->user()->tokens->each(function ($token) {
        $token->clients->each->revokeTokens();
    });

    return response()->json(['message' => 'Logged out']);
}
```

## Middleware and Guards

### Passport Middleware

```php
<?php

// app/Http/Kernel.php
protected $middlewareAliases = [
    'client' => \Laravel\Passport\Http\Middleware\CheckClientCredentials::class,
    'scope' => \Laravel\Passport\Http\Middleware\CheckForAnyScope::class,
    'scopes' => \Laravel\Passport\Http\Middleware\CheckScopes::class,
];
```

### Multiple Guards

```php
<?php

// Protect with both session and token auth
Route::middleware(['auth:web', 'auth:api'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
});

// Check if user is authenticated via Passport
if (auth('api')->check()) {
    // User authenticated via access token
}
```

### Custom Token Guard

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RequireScope
{
    public function handle(Request $request, Closure $next, string ...$scopes)
    {
        $user = $request->user('api');

        if (! $user) {
            return response()->json(['error' => 'Unauthenticated'], 401);
        }

        foreach ($scopes as $scope) {
            if (! $user->tokenCan($scope)) {
                return response()->json([
                    'error' => "Scope '{$scope}' required",
                ], 403);
            }
        }

        return $next($request);
    }
}
```

## Testing OAuth Flows

### Test Authorization Code Flow

```php
<?php

use App\Models\User;
use Laravel\Passport\Client;
use Laravel\Passport\Passport;

it('authorizes client and issues code', function () {
    $user = User::factory()->create();
    $client = Client::factory()->create(['user_id' => $user->id]);

    $response = $this->actingAs($user)
        ->get('/oauth/authorize?' . http_build_query([
            'client_id' => $client->id,
            'redirect_uri' => $client->redirect,
            'response_type' => 'code',
            'scope' => 'read-posts',
        ]));

    $response->assertOk()
        ->assertViewIs('passport::authorize');
});

it('exchanges authorization code for token', function () {
    $client = Client::factory()->create(['secret' => 'secret']);
    $code = 'authorization_code_here';

    $response = $this->postJson('/oauth/token', [
        'grant_type' => 'authorization_code',
        'client_id' => $client->id,
        'client_secret' => 'secret',
        'redirect_uri' => $client->redirect,
        'code' => $code,
    ]);

    $response->assertOk()
        ->assertJsonStructure([
            'token_type',
            'expires_in',
            'access_token',
            'refresh_token',
        ]);
});
```

### Test Client Credentials

```php
<?php

use Laravel\Passport\Client;

it('issues token for client credentials', function () {
    $client = Client::factory()->create([
        'personal_access_client' => false,
        'password_client' => false,
        'secret' => 'secret',
    ]);

    $response = $this->postJson('/oauth/token', [
        'grant_type' => 'client_credentials',
        'client_id' => $client->id,
        'client_secret' => 'secret',
        'scope' => 'read-data',
    ]);

    $response->assertOk()
        ->assertJsonStructure(['access_token', 'expires_in']);
});
```

### Test Scopes

```php
<?php

use App\Models\User;
use Laravel\Passport\Passport;

it('allows access with correct scope', function () {
    $user = User::factory()->create();

    Passport::actingAs($user, ['write-posts']);

    $response = $this->postJson('/api/posts', [
        'title' => 'Test Post',
        'body' => 'Content',
    ]);

    $response->assertCreated();
});

it('denies access without required scope', function () {
    $user = User::factory()->create();

    Passport::actingAs($user, ['read-posts']); // Missing write-posts

    $response = $this->postJson('/api/posts', [
        'title' => 'Test Post',
    ]);

    $response->assertForbidden();
});
```

### Test Token Refresh

```php
<?php

it('refreshes access token', function () {
    $client = Client::factory()->create(['secret' => 'secret']);
    $refreshToken = 'valid_refresh_token';

    $response = $this->postJson('/oauth/token', [
        'grant_type' => 'refresh_token',
        'refresh_token' => $refreshToken,
        'client_id' => $client->id,
        'client_secret' => 'secret',
        'scope' => '',
    ]);

    $response->assertOk()
        ->assertJsonStructure(['access_token', 'refresh_token']);
});
```

## Common Pitfalls

1. **Not Running passport:install**
   ```bash
   # Must run after migration
   php artisan passport:install

   # This generates encryption keys and default clients
   ```

2. **Wrong Auth Guard Configuration**
   ```php
   // config/auth.php - Must use 'passport' driver
   'api' => [
       'driver' => 'passport', // NOT 'token'
       'provider' => 'users',
   ],
   ```

3. **Missing HasApiTokens Trait**
   ```php
   // User model MUST use Laravel\Passport\HasApiTokens
   use Laravel\Passport\HasApiTokens;

   class User extends Authenticatable
   {
       use HasApiTokens; // Not Laravel\Sanctum\HasApiTokens
   }
   ```

4. **Exposing Client Secrets**
   ```php
   // NEVER expose client_secret in frontend code
   // Use PKCE for public clients (SPAs, mobile apps)

   // Only send client_secret from secure backend
   ```

5. **Not Setting Token Lifetimes**
   ```php
   // Always configure expiration in production
   Passport::tokensExpireIn(now()->addDays(15));
   Passport::refreshTokensExpireIn(now()->addDays(30));

   // Prune old tokens
   Passport::pruneRevokedTokens();
   ```

6. **Using Password Grant for Third-Party Apps**
   ```php
   // NEVER use password grant for third-party apps
   // Password grant = first-party apps only (and it's deprecated)

   // Use Authorization Code Grant for third-party
   ```

7. **Not Validating Redirect URIs**
   ```php
   // Always whitelist exact redirect URIs per client
   // Prevent open redirects and token theft

   $client->redirect = 'https://exact-url.com/callback'; // Exact match
   ```

8. **Forgetting to Revoke Tokens on Security Events**
   ```php
   // Always revoke tokens on:
   // - Password change
   // - Email change
   // - Account compromise
   // - User logout

   $user->tokens->each->revoke();
   ```

9. **Not Using HTTPS in Production**
   ```php
   // OAuth2 REQUIRES HTTPS in production
   // Tokens in URLs/headers must be encrypted

   // Force HTTPS in production
   if (app()->environment('production')) {
       URL::forceScheme('https');
   }
   ```

10. **Not Pruning Revoked Tokens**
    ```php
    // Schedule token cleanup
    // app/Console/Kernel.php
    protected function schedule(Schedule $schedule): void
    {
        $schedule->command('passport:purge')->daily();
    }
    ```

## Best Practices

- Use Authorization Code + PKCE for SPAs and mobile apps
- Use Client Credentials for machine-to-machine
- Never use Password Grant for third-party apps
- Always use HTTPS in production
- Set reasonable token lifetimes
- Implement token refresh logic
- Revoke tokens on security events (password change, etc.)
- Whitelist exact redirect URIs per client
- Use scopes to limit token permissions
- Prune revoked tokens regularly
- Rate limit token endpoints
- Log OAuth authorization events
- Validate state parameter to prevent CSRF
- Store refresh tokens securely
- Never expose client secrets in frontend code
- Use UUIDs for token IDs in high-traffic apps

## Related Commands

```bash
# Install Passport
php artisan passport:install

# Install with UUIDs
php artisan passport:install --uuids

# Create new client
php artisan passport:client

# Create password grant client
php artisan passport:client --password

# Create client credentials client
php artisan passport:client --client

# Create personal access client
php artisan passport:client --personal

# Purge revoked/expired tokens
php artisan passport:purge

# List all clients
php artisan passport:clients

# Generate encryption keys
php artisan passport:keys

# Force regenerate keys
php artisan passport:keys --force
```

## Related Skills

- `laravel-sanctum` - Lightweight API authentication
- `laravel-api` - Building REST APIs
- `laravel-auth` - Authentication and authorization
- `laravel-security` - Security best practices
