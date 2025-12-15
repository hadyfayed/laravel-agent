---
name: laravel-auth
description: >
  Authentication and authorization for Laravel including guards, policies, permissions,
  and role-based access control. Use when the user needs help with login, registration,
  permissions, roles, or access control. Triggers: "auth", "authentication", "login",
  "permission", "role", "guard", "policy", "authorization", "access control".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Auth Skill

Implement authentication, authorization, and access control.

## When to Use

- Setting up authentication system
- Creating policies and gates
- Implementing role-based access
- Configuring guards
- Adding permissions

## Quick Start

```bash
/laravel-agent:auth:setup
```

## Authentication Options

### Laravel Breeze (Simple)
```bash
composer require laravel/breeze --dev
php artisan breeze:install
```

### Laravel Fortify (Headless)
```bash
composer require laravel/fortify
php artisan fortify:install
```

### Laravel Sanctum (API)
```bash
composer require laravel/sanctum
php artisan sanctum:install
```

## Authorization Patterns

### Policies
```php
final class PostPolicy
{
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id
            || $user->hasRole('admin');
    }

    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

### Gates
```php
Gate::define('access-admin', function (User $user) {
    return $user->hasRole('admin');
});

// Usage
if (Gate::allows('access-admin')) {
    // ...
}
```

### Controller Authorization
```php
public function update(Request $request, Post $post)
{
    $this->authorize('update', $post);

    // Update logic...
}
```

## Role-Based Access (spatie/laravel-permission)

```php
// Assign role
$user->assignRole('editor');

// Check role
$user->hasRole('admin');

// Assign permission
$user->givePermissionTo('edit articles');

// Check permission
$user->can('edit articles');

// Middleware
Route::group(['middleware' => ['role:admin']], function () {
    // Admin routes
});
```

## Guards

```php
// config/auth.php
'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],
    'api' => [
        'driver' => 'sanctum',
        'provider' => 'users',
    ],
    'admin' => [
        'driver' => 'session',
        'provider' => 'admins',
    ],
],
```

## Best Practices

- Use policies for model-based authorization
- Use gates for general abilities
- Implement rate limiting on login
- Add 2FA for sensitive apps
- Log authentication events
- Use secure password requirements

## Package Integration

- **spatie/laravel-permission** - Roles and permissions
- **laravel/fortify** - Headless authentication
- **laravel/sanctum** - API tokens
- **laravel/passport** - OAuth2
