---
name: laravel-inertia
description: >
  Build modern SPAs with Laravel and Inertia.js using Vue or React. Use when the user needs
  Inertia, Vue SPA, React SPA, single-page application without API, or server-side routing
  with client-side rendering. Triggers: "inertia", "inertia.js", "vue spa", "react spa",
  "single page app", "server-driven spa", "ziggy", "breeze inertia", "server-side props".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Inertia Skill

Build modern single-page applications with Laravel and Inertia.js without building an API.

## When to Use

- Building SPAs with server-side routing
- Need Vue or React with Laravel backend
- Want SPA experience without API complexity
- Building admin panels or dashboards
- User requests "Inertia", "Vue SPA", or "React SPA"

## Quick Start

### With Laravel Breeze (Recommended)

```bash
# New project with Inertia + Vue
composer create-project laravel/laravel my-app
cd my-app
composer require laravel/breeze --dev
php artisan breeze:install vue

# Or with React
php artisan breeze:install react

# Or with Vue + TypeScript
php artisan breeze:install vue --typescript

# Install dependencies and build
npm install
npm run dev
```

### Manual Installation

```bash
# Install Inertia server-side
composer require inertiajs/inertia-laravel

# Publish middleware
php artisan inertia:middleware

# Register middleware in bootstrap/app.php
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \App\Http\Middleware\HandleInertiaRequests::class,
    ]);
})

# Install client-side (Vue 3)
npm install @inertiajs/vue3

# Or React
npm install @inertiajs/react

# Install Ziggy for route helpers
composer require tightenco/ziggy
```

## Installation

### Vue 3 Setup

```javascript
// resources/js/app.js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'
import { ZiggyVue } from '../../vendor/tightenco/ziggy'

createInertiaApp({
    title: (title) => `${title} - ${import.meta.env.VITE_APP_NAME}`,
    resolve: (name) => resolvePageComponent(
        `./Pages/${name}.vue`,
        import.meta.glob('./Pages/**/*.vue')
    ),
    setup({ el, App, props, plugin }) {
        return createApp({ render: () => h(App, props) })
            .use(plugin)
            .use(ZiggyVue)
            .mount(el)
    },
    progress: {
        color: '#4B5563',
    },
})
```

### React Setup

```javascript
// resources/js/app.jsx
import { createRoot } from 'react-dom/client'
import { createInertiaApp } from '@inertiajs/react'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'

createInertiaApp({
    title: (title) => `${title} - ${import.meta.env.VITE_APP_NAME}`,
    resolve: (name) => resolvePageComponent(
        `./Pages/${name}.jsx`,
        import.meta.glob('./Pages/**/*.jsx')
    ),
    setup({ el, App, props }) {
        createRoot(el).render(<App {...props} />)
    },
    progress: {
        color: '#4B5563',
    },
})
```

### Root Template

```blade
{{-- resources/views/app.blade.php --}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title inertia>{{ config('app.name') }}</title>
    @routes
    @vite(['resources/js/app.js', "resources/js/Pages/{$page['component']}.vue"])
    @inertiaHead
</head>
<body>
    @inertia
</body>
</html>
```

## Controller Pattern

### Basic Controller

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

## Pages and Layouts

### Vue Page Component

```vue
<!-- resources/js/Pages/Products/Index.vue -->
<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AppLayout from '@/Layouts/AppLayout.vue'

defineProps({
    products: Object,
    filters: Object,
})

const deleteProduct = (id) => {
    if (confirm('Are you sure?')) {
        router.delete(route('products.destroy', id))
    }
}
</script>

<template>
    <AppLayout>
        <Head title="Products" />

        <div class="py-12">
            <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
                <div class="flex justify-between mb-6">
                    <h1 class="text-2xl font-bold">Products</h1>
                    <Link
                        :href="route('products.create')"
                        class="btn btn-primary"
                    >
                        Create Product
                    </Link>
                </div>

                <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                    <table class="min-w-full">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Category</th>
                                <th>Price</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="product in products.data" :key="product.id">
                                <td>{{ product.name }}</td>
                                <td>{{ product.category }}</td>
                                <td>{{ product.price }}</td>
                                <td>
                                    <Link
                                        :href="route('products.edit', product.id)"
                                        class="text-blue-600"
                                    >
                                        Edit
                                    </Link>
                                    <button
                                        @click="deleteProduct(product.id)"
                                        class="text-red-600 ml-4"
                                    >
                                        Delete
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                    </table>

                    <!-- Pagination -->
                    <div class="flex justify-between p-4">
                        <Link
                            v-if="products.prev_page_url"
                            :href="products.prev_page_url"
                            class="btn"
                        >
                            Previous
                        </Link>
                        <Link
                            v-if="products.next_page_url"
                            :href="products.next_page_url"
                            class="btn"
                        >
                            Next
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    </AppLayout>
</template>
```

### React Page Component

```jsx
// resources/js/Pages/Products/Index.jsx
import { Head, Link, router } from '@inertiajs/react'
import AppLayout from '@/Layouts/AppLayout'

export default function Index({ products, filters }) {
    const deleteProduct = (id) => {
        if (confirm('Are you sure?')) {
            router.delete(route('products.destroy', id))
        }
    }

    return (
        <AppLayout>
            <Head title="Products" />

            <div className="py-12">
                <div className="max-w-7xl mx-auto sm:px-6 lg:px-8">
                    <div className="flex justify-between mb-6">
                        <h1 className="text-2xl font-bold">Products</h1>
                        <Link
                            href={route('products.create')}
                            className="btn btn-primary"
                        >
                            Create Product
                        </Link>
                    </div>

                    <div className="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                        <table className="min-w-full">
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Category</th>
                                    <th>Price</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {products.data.map((product) => (
                                    <tr key={product.id}>
                                        <td>{product.name}</td>
                                        <td>{product.category}</td>
                                        <td>{product.price}</td>
                                        <td>
                                            <Link
                                                href={route('products.edit', product.id)}
                                                className="text-blue-600"
                                            >
                                                Edit
                                            </Link>
                                            <button
                                                onClick={() => deleteProduct(product.id)}
                                                className="text-red-600 ml-4"
                                            >
                                                Delete
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </AppLayout>
    )
}
```

### Layout Component (Vue)

```vue
<!-- resources/js/Layouts/AppLayout.vue -->
<script setup>
import { Link, usePage } from '@inertiajs/vue3'
import { computed } from 'vue'

const page = usePage()
const flash = computed(() => page.props.flash)
</script>

<template>
    <div>
        <nav class="bg-white border-b border-gray-100">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex justify-between h-16">
                    <div class="flex">
                        <Link :href="route('dashboard')" class="flex items-center">
                            Logo
                        </Link>

                        <div class="hidden space-x-8 sm:ml-10 sm:flex">
                            <Link
                                :href="route('products.index')"
                                class="inline-flex items-center px-1 pt-1"
                            >
                                Products
                            </Link>
                        </div>
                    </div>

                    <div class="hidden sm:flex sm:items-center sm:ml-6">
                        <span>{{ $page.props.auth.user.name }}</span>
                    </div>
                </div>
            </div>
        </nav>

        <!-- Flash Messages -->
        <div v-if="flash.success" class="bg-green-100 p-4">
            {{ flash.success }}
        </div>

        <main>
            <slot />
        </main>
    </div>
</template>
```

## Shared Data

### HandleInertiaRequests Middleware

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

## Forms

### Vue Form with useForm

```vue
<!-- resources/js/Pages/Products/Create.vue -->
<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import AppLayout from '@/Layouts/AppLayout.vue'

defineProps({
    categories: Array,
})

const form = useForm({
    name: '',
    description: '',
    price: '',
    category_id: null,
})

const submit = () => {
    form.post(route('products.store'), {
        preserveScroll: true,
        onSuccess: () => form.reset(),
    })
}
</script>

<template>
    <AppLayout>
        <Head title="Create Product" />

        <div class="max-w-2xl mx-auto py-12">
            <h1 class="text-2xl font-bold mb-6">Create Product</h1>

            <form @submit.prevent="submit">
                <div class="mb-4">
                    <label for="name" class="block mb-2">Name</label>
                    <input
                        id="name"
                        v-model="form.name"
                        type="text"
                        class="w-full border rounded px-3 py-2"
                        :class="{ 'border-red-500': form.errors.name }"
                    />
                    <div v-if="form.errors.name" class="text-red-500 text-sm mt-1">
                        {{ form.errors.name }}
                    </div>
                </div>

                <div class="mb-4">
                    <label for="description" class="block mb-2">Description</label>
                    <textarea
                        id="description"
                        v-model="form.description"
                        class="w-full border rounded px-3 py-2"
                        rows="4"
                    ></textarea>
                </div>

                <div class="mb-4">
                    <label for="price" class="block mb-2">Price</label>
                    <input
                        id="price"
                        v-model="form.price"
                        type="number"
                        step="0.01"
                        class="w-full border rounded px-3 py-2"
                        :class="{ 'border-red-500': form.errors.price }"
                    />
                    <div v-if="form.errors.price" class="text-red-500 text-sm mt-1">
                        {{ form.errors.price }}
                    </div>
                </div>

                <div class="mb-4">
                    <label for="category_id" class="block mb-2">Category</label>
                    <select
                        id="category_id"
                        v-model="form.category_id"
                        class="w-full border rounded px-3 py-2"
                    >
                        <option :value="null">Select a category</option>
                        <option
                            v-for="category in categories"
                            :key="category.value"
                            :value="category.value"
                        >
                            {{ category.label }}
                        </option>
                    </select>
                </div>

                <div class="flex justify-between">
                    <button
                        type="submit"
                        class="btn btn-primary"
                        :disabled="form.processing"
                    >
                        <span v-if="form.processing">Creating...</span>
                        <span v-else>Create Product</span>
                    </button>

                    <Link :href="route('products.index')" class="btn">
                        Cancel
                    </Link>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
```

### React Form with useForm

```jsx
// resources/js/Pages/Products/Create.jsx
import { Head, Link, useForm } from '@inertiajs/react'
import AppLayout from '@/Layouts/AppLayout'

export default function Create({ categories }) {
    const { data, setData, post, processing, errors } = useForm({
        name: '',
        description: '',
        price: '',
        category_id: null,
    })

    const submit = (e) => {
        e.preventDefault()
        post(route('products.store'), {
            preserveScroll: true,
            onSuccess: () => reset(),
        })
    }

    return (
        <AppLayout>
            <Head title="Create Product" />

            <div className="max-w-2xl mx-auto py-12">
                <h1 className="text-2xl font-bold mb-6">Create Product</h1>

                <form onSubmit={submit}>
                    <div className="mb-4">
                        <label htmlFor="name" className="block mb-2">Name</label>
                        <input
                            id="name"
                            type="text"
                            value={data.name}
                            onChange={e => setData('name', e.target.value)}
                            className="w-full border rounded px-3 py-2"
                        />
                        {errors.name && (
                            <div className="text-red-500 text-sm mt-1">
                                {errors.name}
                            </div>
                        )}
                    </div>

                    <div className="mb-4">
                        <label htmlFor="price" className="block mb-2">Price</label>
                        <input
                            id="price"
                            type="number"
                            step="0.01"
                            value={data.price}
                            onChange={e => setData('price', e.target.value)}
                            className="w-full border rounded px-3 py-2"
                        />
                        {errors.price && (
                            <div className="text-red-500 text-sm mt-1">
                                {errors.price}
                            </div>
                        )}
                    </div>

                    <div className="mb-4">
                        <label htmlFor="category_id" className="block mb-2">Category</label>
                        <select
                            id="category_id"
                            value={data.category_id || ''}
                            onChange={e => setData('category_id', e.target.value)}
                            className="w-full border rounded px-3 py-2"
                        >
                            <option value="">Select a category</option>
                            {categories.map((category) => (
                                <option key={category.value} value={category.value}>
                                    {category.label}
                                </option>
                            ))}
                        </select>
                    </div>

                    <div className="flex justify-between">
                        <button
                            type="submit"
                            className="btn btn-primary"
                            disabled={processing}
                        >
                            {processing ? 'Creating...' : 'Create Product'}
                        </button>

                        <Link href={route('products.index')} className="btn">
                            Cancel
                        </Link>
                    </div>
                </form>
            </div>
        </AppLayout>
    )
}
```

## File Uploads

### Controller

```php
public function store(StoreProductRequest $request): RedirectResponse
{
    $product = Product::create($request->validated());

    if ($request->hasFile('image')) {
        $product->addMedia($request->file('image'))
            ->toMediaCollection('images');
    }

    return redirect()
        ->route('products.index')
        ->with('success', 'Product created successfully.');
}
```

### Vue Form with File Upload

```vue
<script setup>
import { useForm } from '@inertiajs/vue3'

const form = useForm({
    name: '',
    image: null,
})

const handleFileChange = (e) => {
    form.image = e.target.files[0]
}

const submit = () => {
    form.post(route('products.store'), {
        forceFormData: true, // Important for file uploads
        preserveScroll: true,
    })
}
</script>

<template>
    <form @submit.prevent="submit">
        <input
            type="file"
            @change="handleFileChange"
            accept="image/*"
        />

        <!-- Show preview if image selected -->
        <img
            v-if="form.image"
            :src="URL.createObjectURL(form.image)"
            class="mt-2 h-32 w-32 object-cover"
        />

        <!-- Show upload progress -->
        <div v-if="form.progress" class="mt-2">
            <div class="bg-gray-200 rounded-full h-2">
                <div
                    class="bg-blue-600 h-2 rounded-full"
                    :style="{ width: `${form.progress.percentage}%` }"
                ></div>
            </div>
            <p class="text-sm text-gray-600 mt-1">
                {{ form.progress.percentage }}% uploaded
            </p>
        </div>

        <button type="submit" :disabled="form.processing">
            Upload
        </button>
    </form>
</template>
```

## Validation and Errors

### Server-Side Validation

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class StoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'price' => ['required', 'numeric', 'min:0', 'max:999999.99'],
            'category_id' => ['required', 'exists:categories,id'],
            'image' => ['nullable', 'image', 'max:2048'], // 2MB max
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Product name is required.',
            'price.min' => 'Price cannot be negative.',
            'image.max' => 'Image must not exceed 2MB.',
        ];
    }
}
```

### Display Validation Errors (Vue)

```vue
<script setup>
import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

const page = usePage()
const errors = computed(() => page.props.errors)
const hasErrors = computed(() => Object.keys(errors.value).length > 0)
</script>

<template>
    <!-- Show all errors -->
    <div v-if="hasErrors" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
        <ul class="list-disc list-inside">
            <li v-for="(error, key) in errors" :key="key">
                {{ error }}
            </li>
        </ul>
    </div>

    <!-- Or per-field errors -->
    <div class="mb-4">
        <input
            v-model="form.name"
            type="text"
            :class="{ 'border-red-500': errors.name }"
        />
        <div v-if="errors.name" class="text-red-500 text-sm mt-1">
            {{ errors.name }}
        </div>
    </div>
</template>
```

## Partial Reloads

### Only Reload Specific Props

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

### Lazy Props

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

### Preserve Scroll Position

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

### Scroll to Top

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

### Scroll Regions

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

## SEO and Head Management

### Head Component (Vue)

```vue
<script setup>
import { Head } from '@inertiajs/vue3'

defineProps({
    product: Object,
})
</script>

<template>
    <div>
        <Head>
            <title>{{ product.name }}</title>
            <meta name="description" :content="product.description" />
            <meta property="og:title" :content="product.name" />
            <meta property="og:description" :content="product.description" />
            <meta property="og:image" :content="product.image_url" />
            <meta name="twitter:card" content="summary_large_image" />
            <link rel="canonical" :href="route('products.show', product.id)" />
        </Head>

        <!-- Page content -->
    </div>
</template>
```

### Head Component (React)

```jsx
import { Head } from '@inertiajs/react'

export default function Show({ product }) {
    return (
        <>
            <Head>
                <title>{product.name}</title>
                <meta name="description" content={product.description} />
                <meta property="og:title" content={product.name} />
                <meta property="og:description" content={product.description} />
                <meta property="og:image" content={product.image_url} />
            </Head>

            {/* Page content */}
        </>
    )
}
```

### Server-Side Rendering (SSR)

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

### Feature Tests

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

## Package Integration

### Ziggy (Route Helpers)

```bash
composer require tightenco/ziggy
```

```vue
<script setup>
import { router } from '@inertiajs/vue3'

// Use route() helper
router.get(route('products.show', { product: 123 }))
</script>

<template>
    <Link :href="route('products.index')">Products</Link>
    <Link :href="route('products.show', product.id)">View</Link>
</template>
```

### Spatie Query Builder

```php
use Spatie\QueryBuilder\QueryBuilder;
use Spatie\QueryBuilder\AllowedFilter;

public function index(Request $request): Response
{
    $products = QueryBuilder::for(Product::class)
        ->allowedFilters([
            'name',
            AllowedFilter::exact('category_id'),
            AllowedFilter::scope('price_between'),
        ])
        ->allowedSorts(['name', 'price', 'created_at'])
        ->with('category')
        ->paginate(15);

    return Inertia::render('Products/Index', [
        'products' => $products,
        'filters' => $request->only(['filter', 'sort']),
    ]);
}
```

### Spatie Media Library

```php
return Inertia::render('Products/Show', [
    'product' => [
        'id' => $product->id,
        'name' => $product->name,
        'images' => $product->getMedia('images')->map(fn ($media) => [
            'id' => $media->id,
            'url' => $media->getUrl(),
            'thumb' => $media->getUrl('thumb'),
        ]),
    ],
]);
```

## Related Commands

- `/laravel-agent:inertia:make` - Create Inertia page components
- `/laravel-agent:inertia:install` - Setup Inertia with Vue or React
- `/laravel-agent:breeze:install` - Install Laravel Breeze with Inertia

## Related Skills

- `laravel-api` - Building REST APIs (alternative approach)
- `laravel-livewire` - Alternative reactive framework
- `laravel-feature` - Feature structure patterns
- `laravel-testing` - Testing strategies

## Related Agents

- `laravel-inertia` - Inertia.js specialist
- `laravel-architect` - Architecture and planning
- `frontend-vue` - Vue.js expertise
- `frontend-react` - React expertise
