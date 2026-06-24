# Inertia.js Setup Reference

Install and bootstrap Inertia.js in a Laravel project (Vue 3 or React), including the server-side adapter, middleware, root Blade template, and Vite config.

## Environment Check

```bash
# Check for Inertia
composer show inertiajs/inertia-laravel 2>/dev/null && echo "INERTIA=yes" || echo "INERTIA=no"
grep -q "@inertiajs/vue3" package.json 2>/dev/null && echo "VUE=yes" || echo "VUE=no"
grep -q "@inertiajs/react" package.json 2>/dev/null && echo "REACT=yes" || echo "REACT=no"
```

## With Laravel Breeze (Recommended)

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

## Manual Installation

```bash
# Install server-side adapter
composer require inertiajs/inertia-laravel

# Setup middleware
php artisan inertia:middleware

# Install Vue 3 (recommended)
npm install @inertiajs/vue3 vue

# Or React
npm install @inertiajs/react react react-dom

# Install Vite plugin
npm install -D @vitejs/plugin-vue  # for Vue
npm install -D @vitejs/plugin-react  # for React

# Install Ziggy for route helpers
composer require tightenco/ziggy
```

Register the middleware in `bootstrap/app.php`:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \App\Http\Middleware\HandleInertiaRequests::class,
    ]);
})
```

## Vue 3 App Setup

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

A simpler Vue 3 setup (without Ziggy):

```js
// resources/js/app.js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'

createInertiaApp({
    title: (title) => `${title} - My App`,
    resolve: (name) => resolvePageComponent(
        `./Pages/${name}.vue`,
        import.meta.glob('./Pages/**/*.vue')
    ),
    setup({ el, App, props, plugin }) {
        createApp({ render: () => h(App, props) })
            .use(plugin)
            .mount(el)
    },
    progress: {
        color: '#4B5563',
    },
})
```

## Vue Vite Config

```js
// vite.config.js
import { defineConfig } from 'vite'
import laravel from 'laravel-vite-plugin'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
    plugins: [
        laravel({
            input: 'resources/js/app.js',
            refresh: true,
        }),
        vue({
            template: {
                transformAssetUrls: {
                    base: null,
                    includeAbsolute: false,
                },
            },
        }),
    ],
})
```

## React App Setup

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

A simpler React setup:

```jsx
// resources/js/app.jsx
import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'

createInertiaApp({
    title: (title) => `${title} - My App`,
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

## Root Template

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

A simpler root template:

```blade
{{-- resources/views/app.blade.php --}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title inertia>{{ config('app.name') }}</title>
    @vite(['resources/js/app.js', 'resources/css/app.css'])
    @inertiaHead
</head>
<body class="antialiased">
    @inertia
</body>
</html>
```
