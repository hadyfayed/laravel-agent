# Forms, Validation, and File Uploads Reference

`useForm`, validation errors, and file uploads with Inertia.js (Vue 3 and React).

## Vue Form with useForm

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

## React Form with useForm

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

## Server-Side Validation

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

## Display Validation Errors (Vue)

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

## File Uploads

Controller handling an uploaded file (with Spatie Media Library):

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

Vue form with file upload (`forceFormData` is required for file uploads):

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
