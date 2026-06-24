# Pulse Recorders Configuration

## Recorders Overview

| Recorder | Metrics | Purpose |
|----------|---------|---------|
| `CacheInteractions` | Cache hits/misses/size | Monitor caching effectiveness |
| `Exceptions` | Exception count/type/location | Track application errors |
| `Queues` | Queue depth, jobs processed | Monitor background jobs |
| `Requests` | Request count, response time | Track HTTP traffic |
| `SlowJobs` | Jobs exceeding threshold | Find performance bottlenecks |
| `SlowOutgoingRequests` | HTTP client slowness | Monitor external API calls |
| `SlowQueries` | Queries exceeding threshold | Database performance |
| `SlowRequests` | Requests exceeding threshold | Slow page loads |
| `UserJobs` | Jobs per user | Understand user activity |
| `UserRequests` | Requests per user | User traffic patterns |
| `Servers` | CPU, memory per server | Infrastructure metrics |

## Default Configuration

```php
<?php

// config/pulse.php

'recorders' => [
    Recorders\CacheInteractions::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'ignore' => [
            '/^laravel:pulse:/',
            '/^telescope:/',
        ],
        'groups' => [
            '/^user:/' => 'user:*',
        ],
    ],

    Recorders\Exceptions::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'location' => true,
        'ignore' => [
            // Ignored exception classes
        ],
    ],

    Recorders\Queues::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'ignore' => [
            // Ignored job classes
        ],
    ],

    Recorders\Requests::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'ignore' => [
            '#^/pulse$#',
            '#^/telescope#',
            '#^/horizon#',
        ],
    ],

    Recorders\SlowJobs::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'threshold' => 1000, // milliseconds
        'ignore' => [],
    ],

    Recorders\SlowOutgoingRequests::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'threshold' => 1000,
        'ignore' => [],
    ],

    Recorders\SlowQueries::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'threshold' => 1000,
        'ignore' => [
            '/^select .* from `pulse_/i',
        ],
        'location' => true,
    ],

    Recorders\SlowRequests::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'threshold' => 1000,
        'ignore' => [],
    ],

    Recorders\UserJobs::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'ignore' => [],
    ],

    Recorders\UserRequests::class => [
        'enabled' => true,
        'sample_rate' => 1,
        'ignore' => [],
    ],

    Recorders\Servers::class => [
        'enabled' => true,
        'sample_rate' => 1,
    ],
],
```

## Custom Recorder

```php
<?php

namespace App\Pulse\Recorders;

use Illuminate\Config\Repository;
use Laravel\Pulse\Pulse;
use Laravel\Pulse\Recorders\Concerns\Sampling;

class ApiCalls
{
    use Sampling;

    public function __construct(
        protected Pulse $pulse,
        protected Repository $config,
    ) {}

    public function register($callback, $app): void
    {
        $app['events']->listen(ApiCallMade::class, function ($event) {
            if (!$this->shouldSample()) {
                return;
            }

            $this->pulse->record(
                type: 'api_call',
                key: $event->endpoint,
                value: $event->duration,
            )->count()->max();
        });
    }
}
```

## Custom Card

```php
<?php

namespace App\Livewire\Pulse;

use Laravel\Pulse\Livewire\Card;
use Livewire\Attributes\Lazy;

#[Lazy]
class ApiCalls extends Card
{
    public function render()
    {
        $apiCalls = $this->aggregate('api_call', ['count', 'max']);

        return view('livewire.pulse.api-calls', [
            'apiCalls' => $apiCalls,
        ]);
    }
}
```

## Sample Rate Configuration

Use `sample_rate` to reduce data collection overhead:

```php
// Record 1 in every 10 events (10% sampling)
'sample_rate' => 0.1,

// Record every event (no sampling)
'sample_rate' => 1,
```

## Ignoring Patterns

Use regex patterns to exclude specific operations:

```php
// Ignore cache keys matching pattern
'ignore' => [
    '/^session:/',        // Session cache keys
    '/^cache:/',          // Temporary cache
],

// Ignore specific routes
'ignore' => [
    '#^/health#',         // Health check routes
    '#^/monitoring#',     // Monitoring endpoints
],
```
