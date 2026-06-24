# Meta Tags & Open Graph (artesaos/seotools)

Dynamic meta tags, Open Graph, and Twitter Cards.

## Installation

```bash
composer require artesaos/seotools
php artisan vendor:publish --provider="Artesaos\SEOTools\Providers\SEOToolsServiceProvider"
```

## Configuration

Publish and customize `config/seotools.php` with defaults for your application.

## Usage in Controllers

```php
use Artesaos\SEOTools\Facades\SEOTools;

public function show(Post $post)
{
    SEOTools::setTitle($post->title);
    SEOTools::setDescription($post->excerpt);
    
    SEOTools::opengraph()->setUrl(route('posts.show', $post));
    SEOTools::opengraph()->addImage($post->featured_image);
    SEOTools::opengraph()->setType('article');
    
    SEOTools::twitter()->setImage($post->featured_image);
    SEOTools::twitter()->setType('summary_large_image');

    return view('posts.show', compact('post'));
}
```

## Blade Template Integration

In your layout template `<head>`:

```blade
<head>
    {!! SEO::generate() !!}
    <!-- Generates all meta tags, Open Graph, Twitter Cards -->
</head>
```

## Meta Tag Examples

- `<meta name="description" content="...">`
- `<meta property="og:title" content="...">`
- `<meta property="og:image" content="...">`
- `<meta name="twitter:card" content="summary_large_image">`
