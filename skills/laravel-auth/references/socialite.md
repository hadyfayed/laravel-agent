# Laravel Socialite — Social Login (OAuth)

Implement social authentication with Laravel Socialite.

## When to Use

- OAuth social login (Google, GitHub, Facebook, etc.)
- "Sign in with" functionality
- Third-party authentication
- Linking social accounts to existing users
- Retrieving user data from OAuth providers

## Quick Start

```bash
composer require laravel/socialite
```

## Installation

```bash
composer require laravel/socialite
```

## Supported Providers

Built-in providers:
- Google
- Facebook
- Twitter (OAuth 1.0)
- Twitter (OAuth 2.0)
- LinkedIn
- GitHub
- GitLab
- Bitbucket
- Slack

Community providers (socialiteproviders.com):
- Apple
- Discord
- Spotify
- Twitch
- Microsoft
- And 100+ more

## Configuration

```php
<?php

// config/services.php
return [
    'github' => [
        'client_id' => env('GITHUB_CLIENT_ID'),
        'client_secret' => env('GITHUB_CLIENT_SECRET'),
        'redirect' => env('GITHUB_REDIRECT_URI'),
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect' => env('GOOGLE_REDIRECT_URI'),
    ],

    'facebook' => [
        'client_id' => env('FACEBOOK_CLIENT_ID'),
        'client_secret' => env('FACEBOOK_CLIENT_SECRET'),
        'redirect' => env('FACEBOOK_REDIRECT_URI'),
    ],
];
```

```env
# .env
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
GITHUB_REDIRECT_URI=https://your-app.com/auth/github/callback

GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=https://your-app.com/auth/google/callback
```

## Routes

```php
<?php

// routes/web.php
use App\Http\Controllers\Auth\SocialiteController;

Route::get('/auth/{provider}/redirect', [SocialiteController::class, 'redirect'])
    ->name('socialite.redirect');

Route::get('/auth/{provider}/callback', [SocialiteController::class, 'callback'])
    ->name('socialite.callback');
```

## Controller

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Laravel\Socialite\Facades\Socialite;

class SocialiteController extends Controller
{
    protected array $providers = ['github', 'google', 'facebook'];

    public function redirect(string $provider): RedirectResponse
    {
        $this->validateProvider($provider);

        return Socialite::driver($provider)->redirect();
    }

    public function callback(string $provider): RedirectResponse
    {
        $this->validateProvider($provider);

        $socialUser = Socialite::driver($provider)->user();

        $user = User::updateOrCreate(
            [
                'provider' => $provider,
                'provider_id' => $socialUser->getId(),
            ],
            [
                'name' => $socialUser->getName(),
                'email' => $socialUser->getEmail(),
                'avatar' => $socialUser->getAvatar(),
                'provider_token' => $socialUser->token,
                'provider_refresh_token' => $socialUser->refreshToken,
                'password' => bcrypt(Str::random(24)),
            ]
        );

        Auth::login($user, remember: true);

        return redirect()->intended('/dashboard');
    }

    protected function validateProvider(string $provider): void
    {
        if (! in_array($provider, $this->providers)) {
            abort(404, 'Provider not supported');
        }
    }
}
```

## User Model

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    protected $fillable = [
        'name',
        'email',
        'password',
        'avatar',
        'provider',
        'provider_id',
        'provider_token',
        'provider_refresh_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'provider_token',
        'provider_refresh_token',
    ];
}
```

## Migration

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('avatar')->nullable();
            $table->string('provider')->nullable();
            $table->string('provider_id')->nullable();
            $table->string('provider_token')->nullable();
            $table->string('provider_refresh_token')->nullable();

            $table->unique(['provider', 'provider_id']);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['provider', 'provider_id']);
            $table->dropColumn([
                'avatar',
                'provider',
                'provider_id',
                'provider_token',
                'provider_refresh_token',
            ]);
        });
    }
};
```

## Linking Social Accounts

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Laravel\Socialite\Facades\Socialite;

class LinkedAccountController extends Controller
{
    public function link(string $provider): RedirectResponse
    {
        return Socialite::driver($provider)
            ->redirectUrl(route('socialite.link.callback', $provider))
            ->redirect();
    }

    public function callback(string $provider): RedirectResponse
    {
        $socialUser = Socialite::driver($provider)->user();

        // Check if account is already linked to another user
        $existingAccount = LinkedSocialAccount::where([
            'provider' => $provider,
            'provider_id' => $socialUser->getId(),
        ])->first();

        if ($existingAccount && $existingAccount->user_id !== auth()->id()) {
            return back()->with('error', 'This account is linked to another user.');
        }

        auth()->user()->linkedAccounts()->updateOrCreate(
            ['provider' => $provider],
            [
                'provider_id' => $socialUser->getId(),
                'token' => $socialUser->token,
                'refresh_token' => $socialUser->refreshToken,
            ]
        );

        return redirect()->route('profile.show')
            ->with('success', ucfirst($provider) . ' account linked!');
    }

    public function unlink(string $provider): RedirectResponse
    {
        auth()->user()->linkedAccounts()
            ->where('provider', $provider)
            ->delete();

        return back()->with('success', ucfirst($provider) . ' account unlinked.');
    }
}
```

## Scopes

```php
// Request additional scopes
return Socialite::driver('github')
    ->scopes(['read:user', 'public_repo'])
    ->redirect();

// Set scopes (replaces default)
return Socialite::driver('google')
    ->setScopes(['openid', 'profile', 'email'])
    ->redirect();

// With optional parameters
return Socialite::driver('google')
    ->with(['hd' => 'example.com']) // Restrict to domain
    ->redirect();
```

## Stateless Authentication

```php
// For API/token-based flows
$user = Socialite::driver('github')->stateless()->user();
```

## Community Providers

### Installing Additional Providers

```bash
# Apple
composer require socialiteproviders/apple

# Discord
composer require socialiteproviders/discord

# Microsoft
composer require socialiteproviders/microsoft
```

### SocialiteProviders Manager Setup

For the broader `socialiteproviders/manager` package:

```bash
composer require socialiteproviders/manager
# Install specific providers:
composer require socialiteproviders/google
composer require socialiteproviders/github
composer require socialiteproviders/apple
```

#### Configuration (config/services.php)

```php
'google' => [
    'client_id' => env('GOOGLE_CLIENT_ID'),
    'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    'redirect' => env('GOOGLE_REDIRECT_URI'),
],

'github' => [
    'client_id' => env('GITHUB_CLIENT_ID'),
    'client_secret' => env('GITHUB_CLIENT_SECRET'),
    'redirect' => env('GITHUB_REDIRECT_URI'),
],
```

#### Event Listener

```php
// app/Providers/EventServiceProvider.php
protected $listen = [
    \SocialiteProviders\Manager\SocialiteWasCalled::class => [
        \SocialiteProviders\Google\GoogleExtendSocialite::class.'@handle',
        \SocialiteProviders\GitHub\GitHubExtendSocialite::class.'@handle',
        \SocialiteProviders\Apple\AppleExtendSocialite::class.'@handle',
        \SocialiteProviders\Discord\DiscordExtendSocialite::class.'@handle',
    ],
];
```

#### Social Auth Controller (SocialiteProviders variant)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Laravel\Socialite\Facades\Socialite;

final class SocialAuthController extends Controller
{
    public function redirect(string $provider): RedirectResponse
    {
        $this->validateProvider($provider);

        return Socialite::driver($provider)->redirect();
    }

    public function callback(string $provider): RedirectResponse
    {
        $this->validateProvider($provider);

        $socialUser = Socialite::driver($provider)->user();

        $user = User::updateOrCreate(
            ['email' => $socialUser->getEmail()],
            [
                'name' => $socialUser->getName(),
                'provider' => $provider,
                'provider_id' => $socialUser->getId(),
                'avatar' => $socialUser->getAvatar(),
                'email_verified_at' => now(),
            ]
        );

        auth()->login($user, remember: true);

        return redirect()->intended('/dashboard');
    }

    private function validateProvider(string $provider): void
    {
        if (!in_array($provider, ['google', 'github', 'apple'])) {
            abort(404);
        }
    }
}
```

#### Routes for Social Login (SocialiteProviders variant)

```php
Route::get('/auth/{provider}', [SocialAuthController::class, 'redirect'])
    ->name('social.redirect');

Route::get('/auth/{provider}/callback', [SocialAuthController::class, 'callback'])
    ->name('social.callback');
```

#### Migration for Social Fields (SocialiteProviders variant)

```php
Schema::table('users', function (Blueprint $table) {
    $table->string('provider')->nullable();
    $table->string('provider_id')->nullable();
    $table->string('avatar')->nullable();
    $table->string('password')->nullable()->change(); // Allow null for social users

    $table->unique(['provider', 'provider_id']);
});
```

## Blade Components

```blade
{{-- Login buttons --}}
<div class="space-y-2">
    <a href="{{ route('socialite.redirect', 'github') }}"
       class="btn btn-github">
        <svg><!-- GitHub icon --></svg>
        Continue with GitHub
    </a>

    <a href="{{ route('socialite.redirect', 'google') }}"
       class="btn btn-google">
        <svg><!-- Google icon --></svg>
        Continue with Google
    </a>
</div>

{{-- Or create a component --}}
<x-social-login-button provider="github" />
<x-social-login-button provider="google" />
```

## Handling Errors

```php
public function callback(string $provider): RedirectResponse
{
    try {
        $socialUser = Socialite::driver($provider)->user();
    } catch (\Laravel\Socialite\Two\InvalidStateException $e) {
        return redirect()->route('login')
            ->with('error', 'Authentication session expired. Please try again.');
    } catch (\Exception $e) {
        return redirect()->route('login')
            ->with('error', 'Unable to authenticate. Please try again.');
    }

    // Continue with authentication...
}
```

## Testing

```php
<?php

use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\User as SocialiteUser;
use Mockery;

it('authenticates with github', function () {
    $socialiteUser = Mockery::mock(SocialiteUser::class);
    $socialiteUser->shouldReceive('getId')->andReturn('12345');
    $socialiteUser->shouldReceive('getName')->andReturn('John Doe');
    $socialiteUser->shouldReceive('getEmail')->andReturn('john@example.com');
    $socialiteUser->shouldReceive('getAvatar')->andReturn('https://example.com/avatar.jpg');
    $socialiteUser->token = 'test-token';
    $socialiteUser->refreshToken = 'test-refresh-token';

    Socialite::shouldReceive('driver')
        ->with('github')
        ->andReturn(Mockery::mock([
            'user' => $socialiteUser,
        ]));

    $response = $this->get('/auth/github/callback');

    $response->assertRedirect('/dashboard');

    $this->assertDatabaseHas('users', [
        'email' => 'john@example.com',
        'provider' => 'github',
        'provider_id' => '12345',
    ]);
});

it('redirects to github', function () {
    $response = $this->get('/auth/github/redirect');

    $response->assertRedirect();
    $this->assertStringContainsString('github.com', $response->headers->get('Location'));
});
```

## Common Pitfalls

1. **Wrong Redirect URI**
   ```env
   # Must exactly match provider settings
   GITHUB_REDIRECT_URI=https://your-app.com/auth/github/callback
   # Not: http://... (must be HTTPS in production)
   # Not: trailing slash differences
   ```

2. **Missing Provider Validation**
   ```php
   // Always validate provider to prevent errors
   if (! in_array($provider, ['github', 'google'])) {
       abort(404);
   }
   ```

3. **Not Handling Email Conflicts**
   ```php
   // User might exist with same email from different provider
   $existingUser = User::where('email', $socialUser->getEmail())->first();

   if ($existingUser && $existingUser->provider !== $provider) {
       return back()->with('error', 'Email already registered with different method.');
   }
   ```

4. **Storing Tokens Insecurely**
   ```php
   // Encrypt sensitive tokens
   protected $casts = [
       'provider_token' => 'encrypted',
       'provider_refresh_token' => 'encrypted',
   ];
   ```

5. **Not Handling Missing Email**
   ```php
   // Some providers don't return email
   $email = $socialUser->getEmail() ?? $socialUser->getId().'@'.$provider.'.local';
   ```

6. **Session State Errors**
   ```php
   // Use stateless for API calls
   $user = Socialite::driver($provider)->stateless()->user();
   ```

## Best Practices

- Validate provider names to prevent errors
- Handle OAuth exceptions gracefully
- Allow linking multiple social accounts
- Store and encrypt access tokens securely
- Handle missing email addresses
- Use HTTPS for redirect URIs
- Implement account unlinking
- Log social authentication events
- Test OAuth flows thoroughly
- Use stateless for API authentication
