# Model-Based SEO (ralphjsmit/laravel-seo)

Store SEO data per model with Filament admin integration.

## Installation

```bash
composer require ralphjsmit/laravel-seo
php artisan vendor:publish --tag="seo-migrations"
php artisan migrate
```

## Add Trait to Model

```php
use RalphJSmit\Laravel\SEO\Support\HasSEO;

final class Post extends Model
{
    use HasSEO;
}
```

## Filament Integration

In your Filament resource, add the SEO form field:

```php
use RalphJSmit\Filament\SEO\SEO;

public static function form(Form $form): Form
{
    return $form->schema([
        TextInput::make('title')
            ->required(),
        
        Textarea::make('content')
            ->required(),
        
        // Add SEO fieldset for admin editing
        SEO::make(),
    ]);
}
```

## Access SEO Data

```php
$post = Post::find(1);
echo $post->seo()->title;
echo $post->seo()->description;
echo $post->seo()->canonical_url;
```

## Benefits

- Per-model SEO metadata management
- WYSIWYG admin editing in Filament
- Automatic metadata storage and retrieval
- Supports custom meta fields
