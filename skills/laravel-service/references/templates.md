---
name: laravel-service
description: Code templates for Laravel services and actions (native and lorisleiva/laravel-actions)
---

# SERVICE IMPLEMENTATION

```php
<?php

declare(strict_types=1);

namespace App\Services;

final class <Name>Service
{
    public function __construct(
        private readonly DependencyOne $dep1,
        private readonly DependencyTwo $dep2,
    ) {}

    public function performOperation(OperationData $data): OperationResult
    {
        // Orchestrate dependencies
        // Keep methods < 20 lines
    }
}
```

# NATIVE LARAVEL ACTION

```php
<?php

declare(strict_types=1);

namespace App\Actions\<Domain>;

final class <VerbNoun>Action
{
    public function __construct(
        private readonly Dependency $dependency,
    ) {}

    public function execute(<Input>Data $input): <Output>Result
    {
        // Single responsibility
        // One clear purpose
        // Max 20 lines
    }
}
```

# LARAVEL ACTIONS PACKAGE

```php
<?php

declare(strict_types=1);

namespace App\Actions\<Domain>;

use Lorisleiva\Actions\Concerns\AsAction;
use Lorisleiva\Actions\Concerns\AsController;
use Lorisleiva\Actions\Concerns\AsJob;
use Lorisleiva\Actions\Concerns\AsListener;
use Lorisleiva\Actions\Concerns\AsCommand;

final class <VerbNoun>
{
    use AsAction;

    /**
     * Main business logic - always define this.
     */
    public function handle(<Input> $input): <Output>
    {
        // Core business logic
        // Single responsibility
        // Max 20 lines
    }

    /**
     * Run as HTTP controller.
     * Route: Route::post('/endpoint', <VerbNoun>::class);
     */
    public function asController(Request $request): JsonResponse|RedirectResponse
    {
        $result = $this->handle(
            <Input>::fromRequest($request)
        );

        return response()->json($result);
    }

    /**
     * Validation rules for controller mode.
     */
    public function rules(): array
    {
        return [
            'field' => ['required', 'string'],
        ];
    }

    /**
     * Run as queued job.
     * Dispatch: <VerbNoun>::dispatch($input);
     */
    public function asJob(<Input> $input): void
    {
        $this->handle($input);
    }

    /**
     * Configure job options.
     */
    public function configureJob(Job $job): void
    {
        $job->onQueue('default')
            ->tries(3)
            ->backoff([10, 60, 300]);
    }

    /**
     * Run as event listener.
     * Event::listen(SomeEvent::class, <VerbNoun>::class);
     */
    public function asListener(SomeEvent $event): void
    {
        $this->handle($event->getData());
    }

    /**
     * Run as artisan command.
     * php artisan app:<verb-noun>
     */
    public string $commandSignature = 'app:<verb-noun> {argument}';
    public string $commandDescription = 'Description of the command';

    public function asCommand(Command $command): int
    {
        $this->handle($command->argument('argument'));

        $command->info('Done!');
        return 0;
    }
}
```

# LARAVEL ACTIONS - KEY FEATURES

```php
// Running the action
$result = <VerbNoun>::run($input);           // Static call
$result = app(<VerbNoun>::class)->handle($input);  // Via container

// As controller (register in routes)
Route::post('/orders', CreateOrder::class);
Route::get('/reports/{id}', GenerateReport::class);

// As queued job
CreateOrder::dispatch($orderData);           // Dispatch to queue
CreateOrder::dispatchAfterResponse($data);   // After response
CreateOrder::dispatchSync($data);            // Synchronous

// As event listener (register in EventServiceProvider)
Event::listen(OrderCreated::class, SendOrderConfirmation::class);

// As artisan command (auto-registered)
php artisan app:create-order --option=value
```

# LARAVEL ACTIONS - MIDDLEWARE & AUTHORIZATION

```php
class CreateOrder
{
    use AsAction;

    // Controller middleware
    public function getControllerMiddleware(): array
    {
        return ['auth', 'verified'];
    }

    // Authorization
    public function authorize(Request $request): bool
    {
        return $request->user()->can('create', Order::class);
    }

    // Validation with custom messages
    public function rules(): array
    {
        return ['items' => ['required', 'array', 'min:1']];
    }

    public function messages(): array
    {
        return ['items.required' => 'Please add at least one item.'];
    }
}
```

# SERVICE TEST

```php
<?php

use App\Services\<Name>Service;

describe('<Name>Service', function () {
    it('orchestrates correctly', function () {
        $service = app(<Name>Service::class);
        $result = $service->performOperation($data);
        expect($result)->toBeInstanceOf(OperationResult::class);
    });
});
```

# ACTION TEST (NATIVE)

```php
<?php

use App\Actions\<Domain>\<VerbNoun>Action;

describe('<VerbNoun>Action', function () {
    it('executes successfully', function () {
        $action = app(<VerbNoun>Action::class);
        $result = $action->execute($input);
        expect($result)->toBeTrue();
    });
});
```

# ACTION TEST (LARAVEL ACTIONS)

```php
<?php

use App\Actions\<Domain>\<VerbNoun>;

describe('<VerbNoun>', function () {
    // Test the core logic
    it('handles input correctly', function () {
        $result = <VerbNoun>::run($input);
        expect($result)->toBeInstanceOf(Expected::class);
    });

    // Test as controller
    it('works as controller', function () {
        $response = $this->postJson('/endpoint', $data);
        $response->assertOk();
    });

    // Test as job
    it('can be dispatched as job', function () {
        <VerbNoun>::dispatch($input);
        // Assert job was queued or side effects occurred
    });

    // Test authorization
    it('authorizes the user', function () {
        $this->actingAs($unauthorizedUser)
            ->postJson('/endpoint', $data)
            ->assertForbidden();
    });
});
```

# OCTANE COMPATIBILITY

If `laravel/octane` is installed, follow these guidelines:

## Stateless Services (CRITICAL)
Services and actions MUST be stateless for Octane:

```php
// ❌ BAD - State persists between requests
final class BadService
{
    private array $cache = [];  // Will persist!

    public function process($data)
    {
        $this->cache[$data['id']] = $data;  // Memory leak!
    }
}

// ✅ GOOD - Stateless, uses external cache
final class GoodService
{
    public function __construct(
        private readonly CacheInterface $cache,
    ) {}

    public function process($data)
    {
        $this->cache->put("item.{$data['id']}", $data, 3600);
    }
}
```

## Avoid Static State
```php
// ❌ BAD - Static properties persist
class Counter
{
    private static int $count = 0;  // Shared across ALL requests!
}

// ✅ GOOD - Use cache or request-scoped
class Counter
{
    public function __construct(private readonly Cache $cache) {}

    public function increment(): int
    {
        return $this->cache->increment('counter');
    }
}
```

## Constructor vs Runtime Resolution
```php
// ❌ BAD - Resolved once, reused forever
final class Service
{
    public function __construct(
        private readonly User $user,  // Will be first request's user!
    ) {}
}

// ✅ GOOD - Resolve at runtime
final class Service
{
    public function getCurrentUser(): User
    {
        return auth()->user();  // Fresh each request
    }
}
```
