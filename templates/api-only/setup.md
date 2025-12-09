---
description: "Initialize an API-only starter project"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /project:init api - API-Only Starter Setup

Initialize a production-ready API-only application.

## Process

1. **Install Required Packages**
   ```bash
   composer require \
       laravel/sanctum \
       spatie/laravel-query-builder \
       spatie/laravel-data \
       knuckleswtf/scribe

   composer require --dev \
       pestphp/pest \
       pestphp/pest-plugin-laravel \
       larastan/larastan \
       laravel/pint
   ```

2. **Publish Configurations**
   ```bash
   php artisan vendor:publish --tag=sanctum-config
   php artisan vendor:publish --tag=scribe-config
   ```

3. **Create API Structure**
   ```
   app/Http/Controllers/Api/V1/
   app/Http/Resources/V1/
   app/Http/Requests/Api/
   app/Data/
   routes/api_v1.php
   ```

4. **Create Core Components**

   **ForceJsonResponse Middleware:**
   ```php
   class ForceJsonResponse
   {
       public function handle($request, $next)
       {
           $request->headers->set('Accept', 'application/json');
           return $next($request);
       }
   }
   ```

   **BaseApiController:**
   ```php
   abstract class BaseApiController extends Controller
   {
       protected function success($data, int $status = 200)
       {
           return response()->json(['data' => $data], $status);
       }

       protected function error(string $message, int $status = 400)
       {
           return response()->json(['message' => $message], $status);
       }
   }
   ```

5. **Configure Rate Limiting**
   ```php
   // app/Providers/RouteServiceProvider.php
   RateLimiter::for('api', function (Request $request) {
       return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
   });
   ```

6. **Setup Authentication**
   - Create AuthController with register/login/logout
   - Configure Sanctum guards
   - Add token expiration

7. **Create Base Resources**
   - UserResource
   - ErrorResource
   - PaginatedCollection

8. **Setup Tests**
   ```bash
   php artisan pest:install
   ```
   - Create ApiTestCase base class
   - Authentication helper traits
   - Factory states for testing

9. **Setup CI/CD**
   ```bash
   /cicd:setup github
   ```

10. **Report Results**
    ```markdown
    ## API Project Initialized

    ### Structure Created
    - [x] Versioned API routes (v1)
    - [x] Base API controller
    - [x] JSON response middleware
    - [x] Sanctum authentication
    - [x] Rate limiting configured
    - [x] API documentation (Scribe)
    - [x] Query builder for filtering

    ### Endpoints Created
    - POST /api/v1/auth/register
    - POST /api/v1/auth/login
    - POST /api/v1/auth/logout
    - GET /api/v1/user

    ### Next Steps
    1. Run: `php artisan migrate`
    2. Create first resource: `/api:resource Posts`
    3. Generate docs: `php artisan scribe:generate`
    4. Run tests: `vendor/bin/pest`

    ### Commands Available
    - `/api:resource <Name>` - Create API resource
    - `/api:version v2` - Create new API version
    - `/api:docs` - Generate documentation
    - `/security:audit api` - Security audit
    ```
