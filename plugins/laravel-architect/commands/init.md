---
description: "Initialize Laravel Agent - sets up directories, pattern registry, and tenancy support"
allowed-tools: Bash, Write, Read, Glob, Edit
---

# /init - Initialize Laravel Agent System

First-time setup for Laravel Agent. Creates directories, pattern registry, and optional tenancy support.

## Process

### Step 1: Verify Laravel Project

```bash
if [ ! -f "artisan" ]; then
    echo "Error: Not a Laravel project. Run this in a Laravel project root."
    exit 1
fi
php artisan --version
```

### Step 2: Create Directory Structure

```bash
mkdir -p app/Features
mkdir -p app/Modules
mkdir -p app/Services
mkdir -p app/Actions
mkdir -p app/Support/Tenancy/Concerns
mkdir -p app/Support/Tenancy/Scopes
mkdir -p .ai/patterns
mkdir -p .ai/guidelines
echo "Created directory structure"
```

### Step 3: Create Pattern Registry

Create `.ai/patterns/registry.json`:

```json
{
  "patterns": [],
  "limit": 5,
  "history": [],
  "available": ["Repository", "DTO", "Strategy", "Action", "Factory", "Pipeline", "Observer", "QueryObject"]
}
```

### Step 4: Check Dependencies

```bash
echo "=== Checking Dependencies ==="

# Laravel Boost
composer show laravel/boost 2>/dev/null && echo "✓ Laravel Boost installed" || echo "○ Laravel Boost: composer require laravel/boost --dev"

# Laratrust
composer show santigarcor/laratrust 2>/dev/null && echo "✓ Laratrust installed" || echo "○ Laratrust: composer require santigarcor/laratrust"

# Pest
composer show pestphp/pest 2>/dev/null && echo "✓ Pest installed" || echo "○ Pest: composer require pestphp/pest --dev"
```

### Step 5: Create Tenancy Support Files

**app/Support/Tenancy/TenantContext.php:**
```php
<?php

declare(strict_types=1);

namespace App\Support\Tenancy;

final class TenantContext
{
    private static ?int $tenantId = null;
    private static ?int $userId = null;

    public static function setTenant(int $tenantId): void
    {
        self::$tenantId = $tenantId;
    }

    public static function setUser(int $userId): void
    {
        self::$userId = $userId;
    }

    public static function getTenantId(): ?int
    {
        return self::$tenantId;
    }

    public static function getUserId(): ?int
    {
        return self::$userId;
    }

    public static function clear(): void
    {
        self::$tenantId = null;
        self::$userId = null;
    }
}
```

**app/Support/Tenancy/Concerns/BelongsToTenant.php:**
```php
<?php

declare(strict_types=1);

namespace App\Support\Tenancy\Concerns;

use App\Support\Tenancy\Scopes\TenantScope;
use App\Support\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Model;

trait BelongsToTenant
{
    public static function bootBelongsToTenant(): void
    {
        static::addGlobalScope(new TenantScope());

        static::creating(function (Model $model) {
            if (! $model->created_for_id) {
                $model->created_for_id = TenantContext::getTenantId();
            }
            if (! $model->created_by_id) {
                $model->created_by_id = TenantContext::getUserId() ?? auth()->id();
            }
        });
    }
}
```

**app/Support/Tenancy/Scopes/TenantScope.php:**
```php
<?php

declare(strict_types=1);

namespace App\Support\Tenancy\Scopes;

use App\Support\Tenancy\TenantContext;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

final class TenantScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if ($tenantId = TenantContext::getTenantId()) {
            $builder->where($model->getTable().'.created_for_id', $tenantId);
        }
    }
}
```

### Step 6: Output Summary

```markdown
## Laravel Agent Initialized

### Structure Created
- app/Features/     (self-contained business features)
- app/Modules/      (reusable domain logic)
- app/Services/     (orchestration services)
- app/Actions/      (single-purpose actions)
- app/Support/      (utilities, tenancy)
- .ai/patterns/     (pattern registry)

### Pattern Limit: 5 patterns max

### Commands Available
- /build <description>  - Intelligent build
- /feature:make <Name>  - Create feature directly
- /refactor <target>    - Improve code quality
- /patterns             - View pattern usage

### Next Steps
1. Install Laravel Boost if not installed
2. Configure TenantMiddleware for your auth
3. Start building: /build <description>
```
