# Pages, Props, and Shared Data Reference

Controllers, shared data middleware, partial reloads, lazy props, and scroll management for Inertia.js apps.

## Controller Pattern

### Basic Product Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

final class ProductController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Products/Index', [
            'products' => Product::query()
                ->with('category')
                ->latest()
                ->paginate(15)
                ->through(fn ($product) => [
                    'id' => $product->id,
                    'name' => $product->name,
                    'price' => $product->price_formatted,
                    'category' => $product->category->name,
                ]),
            'filters' => request()->only(['search', 'category']),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('Products/Create', [
            'categories' => Category::all()->map(fn ($cat) => [
                'value' => $cat->id,
                'label' => $cat->name,
            ]),
        ]);
    }

    public function store(StoreProductRequest $request): RedirectResponse
    {
        Product::create($request->validated());

        return redirect()
            ->route('products.index')
            ->with('success', 'Product created successfully.');
    }

    public function edit(Product $product): Response
    {
        return Inertia::render('Products/Edit', [
            'product' => [
                'id' => $product->id,
                'name' => $product->name,
                'description' => $product->description,
                'price' => $product->price,
                'category_id' => $product->category_id,
            ],
            'categories' => Category::all()->map(fn ($cat) => [
                'value' => $cat->id,
                'label' => $cat->name,
            ]),
        ]);
    }

    public function update(UpdateProductRequest $request, Product $product): RedirectResponse
    {
        $product->update($request->validated());

        return redirect()
            ->route('products.index')
            ->with('success', 'Product updated successfully.');
    }

    public function destroy(Product $product): RedirectResponse
    {
        $product->delete();

        return back()->with('success', 'Product deleted successfully.');
    }
}
```

### Post Controller (with authorization + selective columns)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

final class PostController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Posts/Index', [
            'posts' => Post::query()
                ->with('author:id,name')
                ->latest()
                ->paginate(10)
                ->through(fn ($post) => [
                    'id' => $post->id,
                    'title' => $post->title,
                    'excerpt' => $post->excerpt,
                    'author' => $post->author->name,
                    'created_at' => $post->created_at->diffForHumans(),
                ]),
            'filters' => request()->only(['search', 'status']),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('Posts/Create', [
            'categories' => Category::pluck('name', 'id'),
        ]);
    }

    public function store(StorePostRequest $request): RedirectResponse
    {
        $post = auth()->user()->posts()->create($request->validated());

        return redirect()
            ->route('posts.show', $post)
            ->with('success', 'Post created successfully.');
    }

    public function show(Post $post): Response
    {
        return Inertia::render('Posts/Show', [
            'post' => [
                'id' => $post->id,
                'title' => $post->title,
                'content' => $post->content,
                'author' => $post->author->only('id', 'name'),
                'created_at' => $post->created_at->format('F j, Y'),
                'can' => [
                    'edit' => auth()->user()?->can('update', $post),
                    'delete' => auth()->user()?->can('delete', $post),
                ],
            ],
        ]);
    }

    public function edit(Post $post): Response
    {
        return Inertia::render('Posts/Edit', [
            'post' => $post->only('id', 'title', 'content', 'category_id'),
            'categories' => Category::pluck('name', 'id'),
        ]);
    }

    public function update(UpdatePostRequest $request, Post $post): RedirectResponse
    {
        $post->update($request->validated());

        return redirect()
            ->route('posts.show', $post)
            ->with('success', 'Post updated successfully.');
    }

    public function destroy(Post $post): RedirectResponse
    {
        $post->delete();

        return redirect()
            ->route('posts.index')
            ->with('success', 'Post deleted successfully.');
    }
}
```

## Shared Data (HandleInertiaRequests Middleware)

Full middleware sharing auth, flash, errors, and Ziggy:

```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

final class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    public function share(Request $request): array
    {
        return [
            ...parent::share($request),
            'auth' => [
                'user' => $request->user() ? [
                    'id' => $request->user()->id,
                    'name' => $request->user()->name,
                    'email' => $request->user()->email,
                    'avatar' => $request->user()->avatar_url,
                    'permissions' => $request->user()->permissions,
                ] : null,
            ],
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'errors' => fn () => $request->session()->get('errors')?->getBag('default')?->getMessages() ?? (object) [],
            'ziggy' => fn () => [
                ...\Tighten\Ziggy\Ziggy::fromRequest($request)->toArray(),
                'location' => $request->url(),
            ],
        ];
    }
}
```

A simpler shared-data middleware (auth + flash + can):

```php
<?php

// app/Http/Middleware/HandleInertiaRequests.php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

final class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function share(Request $request): array
    {
        return array_merge(parent::share($request), [
            'auth' => [
                'user' => $request->user()?->only('id', 'name', 'email'),
            ],
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'can' => [
                'viewAdmin' => $request->user()?->isAdmin(),
            ],
        ]);
    }
}
```

## Partial Reloads

Only reload specific props:

```vue
<script setup>
import { router } from '@inertiajs/vue3'

const loadMore = () => {
    router.reload({
        only: ['products'], // Only reload products prop
        preserveScroll: true,
        preserveState: true,
    })
}

const filterByCategory = (categoryId) => {
    router.get(
        route('products.index'),
        { category: categoryId },
        {
            only: ['products', 'filters'], // Partial reload
            preserveState: true,
        }
    )
}
</script>
```

## Lazy Props

Only load props when explicitly requested:

```php
// Controller
return Inertia::render('Products/Show', [
    'product' => $product,
    // Only load reviews when explicitly requested
    'reviews' => Inertia::lazy(fn () => $product->reviews()->latest()->get()),
]);
```

```vue
<script setup>
import { router } from '@inertiajs/vue3'

const loadReviews = () => {
    router.reload({ only: ['reviews'] })
}
</script>
```

## Scroll Management

Preserve scroll position:

```vue
<script setup>
import { router } from '@inertiajs/vue3'

const deleteProduct = (id) => {
    router.delete(route('products.destroy', id), {
        preserveScroll: true, // Maintain scroll position
    })
}

const loadMore = () => {
    router.get(
        route('products.index', { page: page + 1 }),
        {},
        {
            preserveScroll: true,
            preserveState: true,
        }
    )
}
</script>
```

Scroll to top:

```vue
<script setup>
import { router } from '@inertiajs/vue3'

const goToPage = (url) => {
    router.get(url, {}, {
        preserveScroll: false, // Scroll to top (default)
    })
}
</script>
```

Scroll regions (restore scroll within a region):

```vue
<template>
    <div>
        <div scroll-region class="overflow-y-auto h-96">
            <!-- Scrollable content -->
            <!-- Inertia will restore scroll position in this region -->
        </div>
    </div>
</template>
```
