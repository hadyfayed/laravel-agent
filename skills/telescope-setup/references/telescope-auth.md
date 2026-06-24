# Telescope Authorization & Production Setup

## TelescopeServiceProvider Configuration

Create or update `app/Providers/TelescopeServiceProvider.php`:

```php
<?php
declare(strict_types=1);

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Laravel\Telescope\Telescope;
use Laravel\Telescope\TelescopeApplicationServiceProvider;

final class TelescopeServiceProvider extends TelescopeApplicationServiceProvider
{
    public function register(): void
    {
        Telescope::night();  // dark mode

        $this->hideSensitiveRequestDetails();

        // Only record on local or critical events in production
        Telescope::filter(function ($entry) {
            if ($this->app->environment('local')) {
                return true;
            }

            return $entry->isReportableException()
                || $entry->isFailedRequest()
                || $entry->isFailedJob();
        });
    }

    protected function hideSensitiveRequestDetails(): void
    {
        if ($this->app->environment('local')) {
            return;
        }

        Telescope::hideRequestParameters(['_token', 'password']);
        Telescope::hideRequestHeaders(['cookie', 'x-csrf-token']);
    }

    protected function gate(): void
    {
        Gate::define('viewTelescope', fn ($user) =>
            in_array($user->email, ['admin@example.com']) || $user->isAdmin()
        );
    }
}
```

## Filtering by Environment

Use environment-aware filtering to reduce storage and noise in production:

- **Local:** Record everything
- **Production:** Only critical events (exceptions, failed requests, failed jobs)

## Sensitivity Masking

Hide sensitive request data in production:
- Parameters: `_token`, `password`, `credit_card`, etc.
- Headers: `cookie`, `x-csrf-token`, `authorization`

## Gate Authorization

Define `viewTelescope` gate to restrict dashboard access to trusted users:
- Admin users
- Specific email addresses
- Roles/permissions from Spatie/Laratrust

## Pruning Schedule

In `app/Console/Kernel.php` or `routes/console.php`:

```php
Schedule::command('telescope:prune --hours=48')->daily();
```

Keeps only 2 days of data; adjust `--hours` as needed.
