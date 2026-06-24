# Vue & React Page Components Reference

Framework-specific page components, layouts, SEO/head management, and Ziggy route helpers for Inertia.js.

## Vue Page Component (with table + pagination)

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

## Vue Page Component (with debounced search)

```vue
<!-- resources/js/Pages/Posts/Index.vue -->
<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import { ref, watch } from 'vue'
import debounce from 'lodash/debounce'
import AppLayout from '@/Layouts/AppLayout.vue'
import Pagination from '@/Components/Pagination.vue'

const props = defineProps({
    posts: Object,
    filters: Object,
})

const search = ref(props.filters.search ?? '')

watch(search, debounce((value) => {
    router.get('/posts', { search: value }, {
        preserveState: true,
        preserveScroll: true,
    })
}, 300))

function deletePost(id) {
    if (confirm('Are you sure?')) {
        router.delete(`/posts/${id}`)
    }
}
</script>

<template>
    <Head title="Posts" />

    <AppLayout>
        <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-semibold">Posts</h1>
                <Link
                    href="/posts/create"
                    class="bg-blue-500 text-white px-4 py-2 rounded"
                >
                    Create Post
                </Link>
            </div>

            <div class="mb-4">
                <input
                    v-model="search"
                    type="text"
                    placeholder="Search posts..."
                    class="w-full border rounded px-4 py-2"
                />
            </div>

            <div class="bg-white shadow rounded-lg divide-y">
                <div
                    v-for="post in posts.data"
                    :key="post.id"
                    class="p-6 flex justify-between items-center"
                >
                    <div>
                        <Link
                            :href="`/posts/${post.id}`"
                            class="text-lg font-medium text-blue-600 hover:underline"
                        >
                            {{ post.title }}
                        </Link>
                        <p class="text-gray-500 text-sm">
                            By {{ post.author }} · {{ post.created_at }}
                        </p>
                    </div>
                    <div class="flex gap-2">
                        <Link
                            :href="`/posts/${post.id}/edit`"
                            class="text-gray-500 hover:text-gray-700"
                        >
                            Edit
                        </Link>
                        <button
                            @click="deletePost(post.id)"
                            class="text-red-500 hover:text-red-700"
                        >
                            Delete
                        </button>
                    </div>
                </div>
            </div>

            <Pagination :links="posts.links" class="mt-6" />
        </div>
    </AppLayout>
</template>
```

## React Page Component (with table)

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

## React Page Component (with search)

```jsx
// resources/js/Pages/Posts/Index.jsx
import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import AppLayout from '@/Layouts/AppLayout'
import Pagination from '@/Components/Pagination'

export default function Index({ posts, filters }) {
    const [search, setSearch] = useState(filters.search ?? '')

    function handleSearch(e) {
        setSearch(e.target.value)
        router.get('/posts', { search: e.target.value }, {
            preserveState: true,
            preserveScroll: true,
        })
    }

    function deletePost(id) {
        if (confirm('Are you sure?')) {
            router.delete(`/posts/${id}`)
        }
    }

    return (
        <AppLayout>
            <Head title="Posts" />

            <div className="max-w-7xl mx-auto py-6 px-4">
                <div className="flex justify-between items-center mb-6">
                    <h1 className="text-2xl font-semibold">Posts</h1>
                    <Link
                        href="/posts/create"
                        className="bg-blue-500 text-white px-4 py-2 rounded"
                    >
                        Create Post
                    </Link>
                </div>

                <input
                    type="text"
                    value={search}
                    onChange={handleSearch}
                    placeholder="Search posts..."
                    className="w-full border rounded px-4 py-2 mb-4"
                />

                <div className="bg-white shadow rounded-lg divide-y">
                    {posts.data.map((post) => (
                        <div key={post.id} className="p-6 flex justify-between">
                            <div>
                                <Link
                                    href={`/posts/${post.id}`}
                                    className="text-lg font-medium text-blue-600"
                                >
                                    {post.title}
                                </Link>
                                <p className="text-gray-500 text-sm">
                                    By {post.author} · {post.created_at}
                                </p>
                            </div>
                            <button
                                onClick={() => deletePost(post.id)}
                                className="text-red-500"
                            >
                                Delete
                            </button>
                        </div>
                    ))}
                </div>

                <Pagination links={posts.links} className="mt-6" />
            </div>
        </AppLayout>
    )
}
```

## Layout Component (Vue)

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

## SEO / Head Management

Vue:

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

React:

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

## Ziggy (Route Helpers)

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

## Spatie Query Builder Integration

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

## Spatie Media Library Integration

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
