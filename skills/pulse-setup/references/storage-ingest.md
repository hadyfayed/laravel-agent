# Pulse Storage and Ingest Configuration

## Storage Drivers

### Database Storage (Default)

```php
<?php

// config/pulse.php

'storage' => [
    'driver' => env('PULSE_STORAGE_DRIVER', 'database'),
    'database' => [
        'connection' => env('PULSE_DB_CONNECTION', null),
        'chunk' => 1000,
    ],
],

'cache' => env('PULSE_CACHE_DRIVER'),

// Result store
'result_stores' => [
    Spatie\Health\ResultStores\EloquentHealthResultStore::class => [
        'model' => Spatie\Health\Models\HealthCheckResultHistoryItem::class,
        'keep_history_for_days' => 7,
    ],
],
```

**Pros**: Simple, no additional infrastructure.
**Cons**: Slower for high traffic, increases database load.

## Ingest Drivers

### Sync Ingest (Default)

```php
'ingest' => [
    'driver' => env('PULSE_INGEST_DRIVER', 'storage'),
    'buffer' => env('PULSE_INGEST_BUFFER', 5000),
    'trim' => [
        'lottery' => [1, 1000],
        'keep' => '7 days',
    ],
],
```

**Pros**: No external dependencies, synchronous processing.
**Cons**: Impacts request latency, slower aggregation.

### Redis Ingest (High-Traffic Optimization)

```php
<?php

// config/pulse.php

'ingest' => [
    'driver' => 'redis',
    'redis' => [
        'connection' => 'pulse',
        'chunk' => 1000,
    ],
],

// Add to config/database.php
'redis' => [
    'pulse' => [
        'url' => env('PULSE_REDIS_URL'),
        'host' => env('PULSE_REDIS_HOST', '127.0.0.1'),
        'port' => env('PULSE_REDIS_PORT', '6379'),
        'database' => env('PULSE_REDIS_DB', '3'),
    ],
],
```

Run the worker to process Redis entries:

```bash
# In scheduler (Kernel.php)
$schedule->command('pulse:work')->everyFiveSeconds();

# Or run as daemon
php artisan pulse:work
```

**Pros**: Asynchronous, decouples data collection from storage, low-latency.
**Cons**: Requires Redis, additional worker process.

## Environment Variables

```env
# Basic Pulse config
PULSE_ENABLED=true
PULSE_DOMAIN=
PULSE_PATH=pulse
PULSE_STORAGE_DRIVER=database
PULSE_DB_CONNECTION=mysql
PULSE_INGEST_DRIVER=storage
PULSE_CACHE_DRIVER=redis

# For Redis ingest
PULSE_REDIS_URL=redis://127.0.0.1:6379/3
PULSE_REDIS_HOST=127.0.0.1
PULSE_REDIS_PORT=6379
PULSE_REDIS_DB=3
```

## Data Retention and Trimming

Configure how long Pulse keeps historical data:

```php
'ingest' => [
    'trim' => [
        'lottery' => [1, 1000],  // 1 in 1000 requests triggers trim
        'keep' => '7 days',      // Keep data for 7 days
    ],
],
```

Clear old data manually:

```bash
php artisan pulse:clear
```

## Dashboard Authorization

```php
<?php

// app/Providers/AppServiceProvider.php

use Illuminate\Support\Facades\Gate;
use Laravel\Pulse\Facades\Pulse;

public function boot(): void
{
    Gate::define('viewPulse', function ($user) {
        return $user->isAdmin();
    });

    // Customize user resolution
    Pulse::user(fn ($user) => [
        'name' => $user->name,
        'email' => $user->email,
        'avatar' => $user->profile_photo_url,
    ]);
}
```

## Routes

Access the Pulse dashboard at `/pulse` (default path). Customize in `config/pulse.php`:

```php
'path' => env('PULSE_PATH', 'pulse'),
'domain' => env('PULSE_DOMAIN'),
```

## Comparison: Telescope vs Pulse

| Feature | Telescope | Pulse |
|---------|-----------|-------|
| Purpose | Debugging | Monitoring |
| Environment | Development | Production |
| Detail Level | Very detailed | Aggregated |
| Performance | Heavier | Lightweight |
| Retention | Hours/Days | Days/Weeks |

**Use Telescope** for development debugging.
**Use Pulse** for production monitoring.
