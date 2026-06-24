# Core Auth — Guards, Policies, Gates, Roles & Permissions, 2FA

Authentication and authorization conventions using Laravel's built-in features, Laratrust, or Spatie Permission.

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

## Best Practices

- Use policies for model authorization
- Use gates for general abilities
- Rate limit authentication endpoints
- Use HTTPS in production
- Regenerate session after login
- Implement proper logout

## Package Integration

- **laravel/sanctum** - API token authentication
- **laravel/passport** - Full OAuth2 server
- **spatie/laravel-permission** - Role & permission management
- **laravel/fortify** - Authentication backend

---

# Package Choice: Laratrust vs Spatie Permission

| Feature | Laratrust | Spatie Permission |
|---------|-----------|-------------------|
| Teams/Multi-tenancy | Built-in | Manual |
| Permissions | Role + Direct | Role + Direct |
| Blade directives | @role, @permission | @role, @can |
| Middleware | role, permission | role, permission |
| Cache | Built-in | Built-in |
| Installation | More setup | Simpler |

**Choose Laratrust** for: Team-based permissions, multi-tenant apps
**Choose Spatie** for: Simpler setup, most common use cases

## Environment Check

```bash
# Check for auth packages
composer show santigarcor/laratrust 2>/dev/null && echo "LARATRUST=yes" || echo "LARATRUST=no"
composer show spatie/laravel-permission 2>/dev/null && echo "SPATIE_PERMISSION=yes" || echo "SPATIE_PERMISSION=no"
composer show laravel/sanctum 2>/dev/null && echo "SANCTUM=yes" || echo "SANCTUM=no"
composer show laravel/passport 2>/dev/null && echo "PASSPORT=yes" || echo "PASSPORT=no"
composer show socialiteproviders/manager 2>/dev/null && echo "SOCIALITE_PROVIDERS=yes" || echo "SOCIALITE_PROVIDERS=no"
composer show laravel/fortify 2>/dev/null && echo "FORTIFY=yes" || echo "FORTIFY=no"
```

---

# Spatie Permission Setup

If `spatie/laravel-permission` is installed:

## Installation
```bash
composer require spatie/laravel-permission
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan migrate
```

## User Model Setup
```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasRoles;
}
```

## Creating Roles & Permissions
```php
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

// Create permissions
Permission::create(['name' => 'edit articles']);
Permission::create(['name' => 'delete articles']);
Permission::create(['name' => 'publish articles']);

// Create roles and assign permissions
$admin = Role::create(['name' => 'admin']);
$admin->givePermissionTo(Permission::all());

$editor = Role::create(['name' => 'editor']);
$editor->givePermissionTo(['edit articles', 'publish articles']);

$writer = Role::create(['name' => 'writer']);
$writer->givePermissionTo('edit articles');
```

## Assigning Roles to Users
```php
// Assign role
$user->assignRole('editor');
$user->assignRole(['editor', 'writer']);

// Remove role
$user->removeRole('editor');

// Sync roles (replaces all)
$user->syncRoles(['editor']);

// Direct permissions
$user->givePermissionTo('edit articles');
$user->revokePermissionTo('edit articles');
```

## Checking Permissions
```php
// Check role
$user->hasRole('editor');
$user->hasAnyRole(['editor', 'admin']);
$user->hasAllRoles(['editor', 'admin']);

// Check permission
$user->can('edit articles');
$user->hasPermissionTo('edit articles');
$user->hasAnyPermission(['edit articles', 'publish articles']);

// Via role
$user->hasPermissionViaRole('edit articles');
```

## Blade Directives (Spatie)
```blade
@role('admin')
    Admin content
@endrole

@hasrole('admin')
    Admin content
@endhasrole

@can('edit articles')
    Edit button
@endcan

@hasanyrole('admin|editor')
    Editor tools
@endhasanyrole

@unlessrole('admin')
    Non-admin content
@endunlessrole
```

## Middleware (Spatie)
```php
// routes/web.php
Route::middleware(['role:admin'])->group(function () {
    Route::get('/admin', [AdminController::class, 'index']);
});

Route::middleware(['permission:edit articles'])->group(function () {
    Route::get('/articles/edit', [ArticleController::class, 'edit']);
});

Route::middleware(['role_or_permission:admin|edit articles'])->group(...);
```

---

# Laratrust Setup

## Installation
```bash
composer require santigarcor/laratrust
php artisan vendor:publish --tag=laratrust
php artisan laratrust:setup
php artisan migrate
```

## Configuration (config/laratrust.php)
```php
'user_models' => [
    'users' => \App\Models\User::class,
],
'models' => [
    'role' => \App\Models\Role::class,
    'permission' => \App\Models\Permission::class,
    'team' => \App\Models\Team::class, // If using teams
],
'use_teams' => true, // Enable team-based permissions
```

## User Model Setup
```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laratrust\Contracts\LaratrustUser;
use Laratrust\Traits\HasRolesAndPermissions;

class User extends Authenticatable implements LaratrustUser
{
    use HasRolesAndPermissions;

    // For API authentication
    use HasApiTokens;
}
```

---

# Permission Naming Convention

Pattern: `<action>-<resource>`

```php
// Standard CRUD
'read-users'
'create-users'
'update-users'
'delete-users'

// Special actions
'export-users'
'import-users'
'impersonate-users'

// Feature-specific
'approve-orders'
'cancel-orders'
'refund-orders'
```

---

# Policy Implementation (with Permissions & Tenant Isolation)

```php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Order;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

final class OrderPolicy
{
    use HandlesAuthorization;

    /**
     * Run before all other checks.
     * Return null to fall through to specific methods.
     */
    public function before(User $user, string $ability): ?bool
    {
        // Super admin can do anything
        if ($user->hasRole('super-admin')) {
            return true;
        }

        return null;
    }

    public function viewAny(User $user): bool
    {
        return $user->hasPermission('read-orders');
    }

    public function view(User $user, Order $order): bool
    {
        if (! $user->hasPermission('read-orders')) {
            return false;
        }

        // Tenant isolation
        return $order->created_for_id === $user->current_tenant_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermission('create-orders');
    }

    public function update(User $user, Order $order): bool
    {
        if (! $user->hasPermission('update-orders')) {
            return false;
        }

        // Can't update completed orders
        if ($order->status === 'completed') {
            return false;
        }

        return $order->created_for_id === $user->current_tenant_id;
    }

    public function delete(User $user, Order $order): bool
    {
        if (! $user->hasPermission('delete-orders')) {
            return false;
        }

        // Can't delete completed orders
        if ($order->status === 'completed') {
            return false;
        }

        return $order->created_for_id === $user->current_tenant_id;
    }

    public function restore(User $user, Order $order): bool
    {
        return $user->hasPermission('delete-orders')
            && $order->created_for_id === $user->current_tenant_id;
    }

    public function forceDelete(User $user, Order $order): bool
    {
        return false; // Never allow permanent deletion
    }

    // Custom policy methods
    public function approve(User $user, Order $order): bool
    {
        return $user->hasPermission('approve-orders')
            && $order->status === 'pending'
            && $order->created_for_id === $user->current_tenant_id;
    }

    public function cancel(User $user, Order $order): bool
    {
        return $user->hasPermission('cancel-orders')
            && in_array($order->status, ['pending', 'processing'])
            && $order->created_for_id === $user->current_tenant_id;
    }
}
```

# Registering Policies

```php
// app/Providers/AuthServiceProvider.php or bootstrap/app.php
protected $policies = [
    Order::class => OrderPolicy::class,
    Invoice::class => InvoicePolicy::class,
];

// Or auto-discovery (Laravel 10+)
// Policies in App\Policies\{Model}Policy are auto-discovered
```

# Using Authorization

## In Controllers
```php
// Automatic via authorizeResource
public function __construct()
{
    $this->authorizeResource(Order::class, 'order');
}

// Manual
public function approve(Order $order)
{
    $this->authorize('approve', $order);
    // ...
}

// Inline check
public function show(Order $order)
{
    if ($user->cannot('view', $order)) {
        abort(403);
    }
}
```

## In Blade
```blade
@can('create', App\Models\Order::class)
    <a href="{{ route('orders.create') }}">New Order</a>
@endcan

@can('update', $order)
    <a href="{{ route('orders.edit', $order) }}">Edit</a>
@endcan

@canany(['update', 'delete'], $order)
    <div class="actions">...</div>
@endcanany

{{-- Laratrust specific --}}
@role('admin')
    <a href="/admin">Admin Panel</a>
@endrole

@permission('export-orders')
    <button>Export</button>
@endpermission
```

## In Routes
```php
Route::middleware(['auth', 'permission:read-orders'])->group(function () {
    Route::get('/orders', [OrderController::class, 'index']);
});

Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/admin', [AdminController::class, 'index']);
});
```

---

# Gates for Complex Logic

```php
// AuthServiceProvider or bootstrap/app.php
Gate::define('access-dashboard', function (User $user) {
    return $user->hasAnyRole(['admin', 'manager'])
        || $user->hasPermission('access-dashboard');
});

Gate::define('manage-team', function (User $user, Team $team) {
    return $user->id === $team->owner_id
        || $team->members()->where('user_id', $user->id)->where('role', 'admin')->exists();
});

// Usage
if (Gate::allows('access-dashboard')) { ... }
if (Gate::denies('manage-team', $team)) { abort(403); }

// In Blade
@can('access-dashboard')
    <a href="/dashboard">Dashboard</a>
@endcan
```

---

# Two-Factor Authentication

Using Laravel Fortify:

```bash
composer require laravel/fortify
php artisan fortify:install
```

```php
// config/fortify.php
'features' => [
    Features::registration(),
    Features::resetPasswords(),
    Features::emailVerification(),
    Features::updateProfileInformation(),
    Features::updatePasswords(),
    Features::twoFactorAuthentication([
        'confirm' => true,
        'confirmPassword' => true,
    ]),
],
```

---

# Permission Seeder

```php
<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Seeder;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Create permissions
        $permissions = [
            // Users
            'read-users', 'create-users', 'update-users', 'delete-users',
            // Orders
            'read-orders', 'create-orders', 'update-orders', 'delete-orders',
            'approve-orders', 'cancel-orders', 'export-orders',
            // Products
            'read-products', 'create-products', 'update-products', 'delete-products',
            // Admin
            'access-dashboard', 'manage-settings', 'view-logs',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // Create roles
        $superAdmin = Role::firstOrCreate(['name' => 'super-admin']);
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $manager = Role::firstOrCreate(['name' => 'manager']);
        $user = Role::firstOrCreate(['name' => 'user']);

        // Assign permissions to roles
        $superAdmin->givePermissions(Permission::all());

        $admin->givePermissions([
            'read-users', 'create-users', 'update-users',
            'read-orders', 'create-orders', 'update-orders', 'approve-orders',
            'read-products', 'create-products', 'update-products',
            'access-dashboard',
        ]);

        $manager->givePermissions([
            'read-users',
            'read-orders', 'create-orders', 'update-orders', 'approve-orders',
            'read-products',
        ]);

        $user->givePermissions([
            'read-orders', 'create-orders',
            'read-products',
        ]);
    }
}
```

---

# Output Format

```markdown
## Auth Implementation: <Target>

### Policy Created
- Location: app/Policies/<Name>Policy.php
- Model: <Model>
- Methods: viewAny, view, create, update, delete, [custom]

### Permissions
| Permission | Description |
|------------|-------------|
| read-<resource> | View list and single |
| create-<resource> | Create new |
| update-<resource> | Modify existing |
| delete-<resource> | Soft delete |

### Usage
```php
// Controller
$this->authorize('action', $model);

// Blade
@can('action', $model)
```

### Test
```bash
vendor/bin/pest --filter="authorization"
```
```
