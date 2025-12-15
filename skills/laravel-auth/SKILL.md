---
name: laravel-auth
description: >
  Implement authentication and authorization in Laravel applications. Use when the user
  needs login, registration, roles, permissions, or access control. Triggers: "auth",
  "authentication", "login", "register", "permission", "role", "policy", "gate",
  "middleware", "sanctum", "passport".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Auth Skill

Implement authentication and authorization for Laravel applications.

## When to Use

- Setting up user authentication
- Implementing role-based access control
- Creating authorization policies
- API authentication with Sanctum/Passport
- Multi-guard authentication

## Quick Start

```bash
/laravel-agent:auth:setup
```

## User Model with Roles

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

final class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = ['name', 'email', 'password'];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class);
    }

    public function hasRole(string $role): bool
    {
        return $this->roles()->where('name', $role)->exists();
    }

    public function hasPermission(string $permission): bool
    {
        return $this->roles()
            ->whereHas('permissions', fn ($q) => $q->where('name', $permission))
            ->exists();
    }

    public function isAdmin(): bool
    {
        return $this->hasRole('admin');
    }
}
```

## Policy Implementation

```php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

final class PostPolicy
{
    public function before(User $user, string $ability): ?bool
    {
        if ($user->isAdmin()) {
            return true;
        }
        return null;
    }

    public function view(User $user, Post $post): bool
    {
        return $post->published || $user->id === $post->user_id;
    }

    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

## Gates Definition

```php
// app/Providers/AppServiceProvider.php
use Illuminate\Support\Facades\Gate;

public function boot(): void
{
    Gate::define('access-admin', function (User $user) {
        return $user->isAdmin();
    });

    Gate::define('manage-users', function (User $user) {
        return $user->hasPermission('users.manage');
    });
}
```

## API Authentication (Sanctum)

```php
// routes/api.php
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());
    Route::post('/logout', [AuthController::class, 'logout']);
});
```

## Auth Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

final class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        return response()->json([
            'user' => $user,
            'token' => $user->createToken('api')->plainTextToken,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }
}
```

## Controller Authorization

```php
final class PostController extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(Post::class, 'post');
    }

    public function update(Request $request, Post $post)
    {
        // Policy automatically checked
        $post->update($request->validated());
        return redirect()->route('posts.show', $post);
    }
}
```

## Blade Authorization

```blade
@auth
    <p>Welcome, {{ auth()->user()->name }}</p>
@endauth

@can('update', $post)
    <a href="{{ route('posts.edit', $post) }}">Edit</a>
@endcan

@can('access-admin')
    <a href="/admin">Admin Panel</a>
@endcan
```

## Common Pitfalls

1. **Storing Plain Passwords** - Always use Hash::make()
2. **No Policy Registration** - Register in AuthServiceProvider
3. **Missing Middleware** - Protect routes with auth
4. **Token Exposure** - Never log tokens
5. **No Rate Limiting** - Rate limit login attempts
6. **Session Fixation** - Regenerate session after login

## Package Integration

- **laravel/sanctum** - API token authentication
- **laravel/passport** - Full OAuth2 server
- **spatie/laravel-permission** - Role & permission management
- **laravel/fortify** - Authentication backend

## Best Practices

- Use policies for model authorization
- Use gates for general abilities
- Rate limit authentication endpoints
- Use HTTPS in production
- Regenerate session after login
- Implement proper logout
