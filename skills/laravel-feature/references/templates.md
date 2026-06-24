# IMPLEMENTATION TEMPLATES

## Model
```php
<?php

declare(strict_types=1);

namespace App\Features\<Name>\Domain\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
// use App\Support\Tenancy\Concerns\BelongsToTenant;

final class <Singular> extends Model
{
    use HasFactory, SoftDeletes;
    // use BelongsToTenant; // If tenancy enabled

    protected $guarded = ['id', 'created_for_id', 'created_by_id'];

    protected $casts = [];
}
```

## Migration
```php
Schema::create('<slug>', function (Blueprint $table) {
    $table->id();
    // Only add if Tenancy: Yes
    // $table->unsignedBigInteger('created_for_id')->index();
    // $table->unsignedBigInteger('created_by_id')->index();
    // Spec columns go here
    $table->timestamps();
    $table->softDeletes();
});
```

## Web Controller
```php
<?php

declare(strict_types=1);

namespace App\Features\<Name>\Http\Controllers;

use App\Features\<Name>\Domain\Models\<Singular>;
use App\Features\<Name>\Http\Requests\{Store<Singular>Request, Update<Singular>Request};
use App\Http\Controllers\Controller;

final class <Name>Controller extends Controller
{
    public function __construct()
    {
        $this->authorizeResource(<Singular>::class, '<slug_singular>');
    }

    public function index() { return view('<slug>::index', ['<slug>' => <Singular>::latest()->paginate(15)]); }
    public function create() { return view('<slug>::create'); }
    public function store(Store<Singular>Request $request) { /* create & redirect */ }
    public function show(<Singular> $<slug_singular>) { return view('<slug>::show', compact('<slug_singular>')); }
    public function edit(<Singular> $<slug_singular>) { return view('<slug>::edit', compact('<slug_singular>')); }
    public function update(Update<Singular>Request $request, <Singular> $<slug_singular>) { /* update & redirect */ }
    public function destroy(<Singular> $<slug_singular>) { /* delete & redirect */ }
}
```

## API Controller - DELEGATE TO laravel-api

For API endpoints, delegate to laravel-api using Task tool:

```
Use the Task tool with subagent_type="laravel-api" to implement API:

Name: <Name>
Version: v1
Spec: <same spec as feature>
Features: [filtering, sorting, pagination, includes]
```

The api-builder will create:
- `app/Http/Controllers/Api/V1/<Name>Controller.php`
- `app/Http/Resources/V1/<Name>Resource.php`
- `app/Http/Resources/V1/<Name>Collection.php`
- `routes/api/v1.php` entries
- OpenAPI documentation annotations

**Why delegate?** The api-builder has specialized knowledge of:
- API versioning strategies
- OpenAPI/Swagger documentation
- Rate limiting configuration
- Query filtering with Spatie Query Builder
- GraphQL with Lighthouse (if installed)
- OAuth2 with Passport (if installed)

## Policy (Laratrust)
```php
public function viewAny(User $user): bool { return $user->hasPermission('read-<slug>'); }
public function view(User $user, <Singular> $<slug_singular>): bool { return $user->hasPermission('read-<slug>'); }
public function create(User $user): bool { return $user->hasPermission('create-<slug>'); }
public function update(User $user, <Singular> $<slug_singular>): bool { return $user->hasPermission('update-<slug>'); }
public function delete(User $user, <Singular> $<slug_singular>): bool { return $user->hasPermission('delete-<slug>'); }
```

## ServiceProvider
```php
public function boot(): void
{
    $this->loadRoutesFrom(__DIR__.'/Http/Routes/web.php');
    $this->loadRoutesFrom(__DIR__.'/Http/Routes/api.php');
    $this->loadViewsFrom(__DIR__.'/Views', '<slug>');
    $this->loadMigrationsFrom(__DIR__.'/Database/Migrations');
    Gate::policy(<Singular>::class, <Singular>Policy::class);
}
```

## Pest Tests
```php
<?php
use App\Features\<Name>\Domain\Models\<Singular>;

describe('<Name>', function () {
    it('can list <slug>', fn () => $this->actingAs(user())->get(route('<slug>.index'))->assertOk());
    it('can create <slug_singular>', fn () => /* test */);
    it('can view <slug_singular>', fn () => /* test */);
    it('can update <slug_singular>', fn () => /* test */);
    it('can delete <slug_singular>', fn () => /* test */);
});

describe('<Name> API', function () {
    it('returns JSON collection', fn () => /* test */);
});
```
