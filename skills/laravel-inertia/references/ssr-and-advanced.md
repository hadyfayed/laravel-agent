# SSR, Testing, and Advanced Patterns Reference

Server-side rendering, feature testing with Inertia assertions, common pitfalls, best practices, and output/guardrail conventions.

## Server-Side Rendering (SSR)

```bash
# Install SSR package
npm install @inertiajs/vue3-server

# Build SSR bundle
npm run build
```

```javascript
// resources/js/ssr.js
import { createSSRApp, h } from 'vue'
import { renderToString } from '@vue/server-renderer'
import { createInertiaApp } from '@inertiajs/vue3'
import createServer from '@inertiajs/vue3/server'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'

createServer((page) =>
    createInertiaApp({
        page,
        render: renderToString,
        resolve: (name) => resolvePageComponent(
            `./Pages/${name}.vue`,
            import.meta.glob('./Pages/**/*.vue')
        ),
        setup({ App, props, plugin }) {
            return createSSRApp({
                render: () => h(App, props),
            }).use(plugin)
        },
    })
)
```

```php
// config/inertia.php
return [
    'ssr' => [
        'enabled' => true,
        'url' => 'http://127.0.0.1:13714',
    ],
];
```

## Testing Inertia Apps

### Feature Tests (Products)

```php
<?php

declare(strict_types=1);

use App\Models\Product;
use App\Models\User;
use Inertia\Testing\AssertableInertia as Assert;

beforeEach(function () {
    $this->user = User::factory()->create();
    $this->actingAs($this->user);
});

describe('Product Pages', function () {
    it('renders products index page', function () {
        Product::factory()->count(3)->create();

        $this->get(route('products.index'))
            ->assertInertia(fn (Assert $page) => $page
                ->component('Products/Index')
                ->has('products.data', 3)
                ->has('products.data.0', fn (Assert $page) => $page
                    ->where('id', Product::first()->id)
                    ->has('name')
                    ->has('price')
                    ->etc()
                )
            );
    });

    it('shares auth user data', function () {
        $this->get(route('products.index'))
            ->assertInertia(fn (Assert $page) => $page
                ->has('auth.user', fn (Assert $page) => $page
                    ->where('id', $this->user->id)
                    ->where('name', $this->user->name)
                    ->where('email', $this->user->email)
                    ->etc()
                )
            );
    });

    it('validates product creation', function () {
        $this->post(route('products.store'), [])
            ->assertInvalid(['name', 'price', 'category_id']);
    });

    it('creates a product', function () {
        $data = Product::factory()->make()->toArray();

        $this->post(route('products.store'), $data)
            ->assertRedirect(route('products.index'))
            ->assertSessionHas('success');

        $this->assertDatabaseHas('products', ['name' => $data['name']]);
    });

    it('renders product edit page with data', function () {
        $product = Product::factory()->create();

        $this->get(route('products.edit', $product))
            ->assertInertia(fn (Assert $page) => $page
                ->component('Products/Edit')
                ->where('product.id', $product->id)
                ->where('product.name', $product->name)
                ->has('categories')
            );
    });

    it('updates a product', function () {
        $product = Product::factory()->create();
        $newName = 'Updated Name';

        $this->put(route('products.update', $product), [
            'name' => $newName,
            'price' => 99.99,
            'category_id' => $product->category_id,
        ])
            ->assertRedirect()
            ->assertSessionHas('success');

        expect($product->fresh()->name)->toBe($newName);
    });

    it('deletes a product', function () {
        $product = Product::factory()->create();

        $this->delete(route('products.destroy', $product))
            ->assertRedirect()
            ->assertSessionHas('success');

        $this->assertSoftDeleted('products', ['id' => $product->id]);
    });
});
```

### Testing Lazy Props

```php
it('does not load reviews by default', function () {
    $product = Product::factory()->create();

    $this->get(route('products.show', $product))
        ->assertInertia(fn (Assert $page) => $page
            ->has('product')
            ->missing('reviews') // Lazy prop not loaded
        );
});

it('loads reviews when explicitly requested', function () {
    $product = Product::factory()->create();
    Review::factory()->count(3)->for($product)->create();

    $this->get(route('products.show', $product), [
        'only' => ['reviews'],
    ])
        ->assertInertia(fn (Assert $page) => $page
            ->has('reviews', 3)
        );
});
```

### Feature Tests (Posts)

```php
<?php

use App\Models\Post;
use App\Models\User;

describe('Posts Inertia', function () {
    it('renders posts index', function () {
        $user = User::factory()->create();
        Post::factory()->count(5)->create();

        $this->actingAs($user)
            ->get('/posts')
            ->assertInertia(fn ($page) => $page
                ->component('Posts/Index')
                ->has('posts.data', 5)
            );
    });

    it('passes filters to page', function () {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/posts?search=test')
            ->assertInertia(fn ($page) => $page
                ->where('filters.search', 'test')
            );
    });

    it('creates post and redirects', function () {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->post('/posts', [
                'title' => 'Test Post',
                'content' => 'Content here',
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('posts', ['title' => 'Test Post']);
    });
});
```

## Common Pitfalls

1. **Not Using router for Navigation** - Use `Link` or `router` methods instead of `<a>` tags
   ```vue
   <!-- Bad -->
   <a href="/products">Products</a>

   <!-- Good -->
   <Link :href="route('products.index')">Products</Link>
   ```

2. **Forgetting forceFormData for File Uploads** - File uploads require FormData
   ```vue
   // Bad
   form.post(route('products.store'))

   // Good
   form.post(route('products.store'), {
       forceFormData: true,
   })
   ```

3. **Not Preserving Scroll on Updates** - User loses position after actions
   ```vue
   // Bad
   router.delete(route('products.destroy', id))

   // Good
   router.delete(route('products.destroy', id), {
       preserveScroll: true,
   })
   ```

4. **Returning Full Models to Frontend** - Exposes sensitive data
   ```php
   // Bad
   return Inertia::render('Products/Index', [
       'products' => Product::all(), // Exposes all model data
   ]);

   // Good
   return Inertia::render('Products/Index', [
       'products' => Product::all()->map(fn ($p) => [
           'id' => $p->id,
           'name' => $p->name,
           'price' => $p->price_formatted,
       ]),
   ]);
   ```

5. **N+1 Queries in Props** - Causes performance issues
   ```php
   // Bad
   return Inertia::render('Products/Index', [
       'products' => Product::all(), // N+1 when accessing relations
   ]);

   // Good
   return Inertia::render('Products/Index', [
       'products' => Product::with('category')->get(),
   ]);
   ```

6. **Not Using Lazy Props for Heavy Data** - Slows initial page load
   ```php
   // Bad
   return Inertia::render('Dashboard', [
       'stats' => $this->calculateHeavyStats(), // Always computed
   ]);

   // Good
   return Inertia::render('Dashboard', [
       'stats' => Inertia::lazy(fn () => $this->calculateHeavyStats()),
   ]);
   ```

7. **Missing CSRF Protection** - Security vulnerability
   ```blade
   <!-- Ensure @vite includes app.js which sets up CSRF -->
   @vite(['resources/js/app.js'])
   ```

8. **Not Handling Flash Messages** - Users miss feedback
   ```php
   // Always share flash messages in HandleInertiaRequests
   'flash' => [
       'success' => fn () => $request->session()->get('success'),
       'error' => fn () => $request->session()->get('error'),
   ],
   ```

Additional pitfalls (from the Inertia specialist guardrails):

- **Heavy initial props** - Only pass necessary data, use lazy loading
- **Not using preserveState** - Loses form state on validation errors
- **Missing form.reset()** - Forms keep old values after submission
- **Not handling errors** - Use form.errors for validation messages
- **SSR complexity** - Only add SSR if truly needed

## Best Practices

1. **Transform Data in Controllers** - Don't expose raw models
2. **Use Partial Reloads** - Only reload necessary data
3. **Implement Loading States** - Show feedback during requests
4. **Preserve Scroll Intelligently** - Better UX for updates
5. **Use Lazy Props for Heavy Data** - Faster initial loads
6. **Share Only Necessary User Data** - Security and performance
7. **Use Ziggy for Route Helpers** - Type-safe routing in JS
8. **Implement Proper Error Handling** - Display validation errors
9. **Use SSR for SEO-Critical Pages** - Better search rankings
10. **Test Inertia Assertions** - Verify props and components

## Guardrails (Inertia specialist conventions)

- **ALWAYS** use form helper for forms (`useForm`)
- **ALWAYS** preserve state on form submissions
- **ALWAYS** pass only necessary data to avoid bloat
- **NEVER** expose sensitive data in page props
- **NEVER** use API routes for Inertia — use web routes
- **NEVER** forget to handle validation errors in frontend

## Output Format (when delivering an Inertia feature)

```markdown
## laravel-inertia Complete

### Summary
- **Framework**: Vue 3|React
- **Pages**: Index, Create, Edit, Show
- **Components**: Layout, Pagination, Flash
- **Status**: Success|Partial|Failed

### Files Created/Modified
- `resources/js/app.js` - Inertia setup
- `resources/js/Pages/Posts/Index.vue`
- `resources/js/Pages/Posts/Create.vue`
- `resources/js/Layouts/AppLayout.vue`
- `app/Http/Controllers/PostController.php`
- `app/Http/Middleware/HandleInertiaRequests.php`

### Shared Data
- auth.user
- flash.success
- flash.error
- can.*

### Routes
- GET /posts → Posts/Index
- GET /posts/create → Posts/Create
- POST /posts → redirect
- GET /posts/{id} → Posts/Show
- GET /posts/{id}/edit → Posts/Edit

### Next Steps
1. Run `npm run dev`
2. Create additional page components
3. Style with Tailwind CSS
4. Add authentication pages
```
