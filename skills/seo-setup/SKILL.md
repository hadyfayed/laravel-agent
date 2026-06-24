---
name: seo-setup
description: Set up SEO infrastructure — sitemaps, meta tags, Open Graph, structured data/schema, robots.txt. Triggers: "SEO", "sitemap", "meta tags", "schema", "Open Graph", "when adding SEO".
disable-model-invocation: true
allowed-tools: Bash(composer *) Bash(php artisan *) Read Write Edit
argument-hint: "[--sitemap] [--meta] [--opengraph] [--schema] [--all]"
---

## Task

Configure comprehensive SEO for your Laravel app. Optionally specify flags via `$ARGUMENTS`; if omitted, run interactively.

## Components

### 1. Sitemap Generation (spatie/laravel-sitemap)

Automatic XML sitemap generation with model support.

```bash
composer require spatie/laravel-sitemap
```

Create `app/Console/Commands/GenerateSitemapCommand.php`:

```php
<?php
declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\Post;
use Illuminate\Console\Command;
use Spatie\Sitemap\Sitemap;
use Spatie\Sitemap\Tags\Url;

final class GenerateSitemapCommand extends Command
{
    protected $signature = 'sitemap:generate';
    protected $description = 'Generate XML sitemap';

    public function handle(): int
    {
        $sitemap = Sitemap::create();

        // Static pages
        $sitemap->add(Url::create('/')->setPriority(1.0));
        $sitemap->add(Url::create('/about')->setPriority(0.8));

        // Dynamic content
        Post::published()->each(fn ($post) =>
            $sitemap->add(Url::create(route('posts.show', $post))
                ->setLastModificationDate($post->updated_at)
                ->setPriority(0.9))
        );

        $sitemap->writeToFile(public_path('sitemap.xml'));
        $this->info('Sitemap generated!');

        return self::SUCCESS;
    }
}
```

Schedule in `app/Console/Kernel.php`:

```php
$schedule->command('sitemap:generate')->daily();
```

### 2. Meta Tags (artesaos/seotools)

Dynamic meta tags, Open Graph, Twitter Cards.

```bash
composer require artesaos/seotools
php artisan vendor:publish --provider="Artesaos\SEOTools\Providers\SEOToolsServiceProvider"
```

Configure defaults in `config/seotools.php` (published; customize as needed).

In controllers, use `SEOTools` facade:

```php
use Artesaos\SEOTools\Facades\SEOTools;

public function show(Post $post)
{
    SEOTools::setTitle($post->title);
    SEOTools::setDescription($post->excerpt);
    SEOTools::opengraph()->setUrl(route('posts.show', $post));
    SEOTools::opengraph()->addImage($post->featured_image);
    SEOTools::twitter()->setImage($post->featured_image);

    return view('posts.show', compact('post'));
}
```

In Blade layout:

```blade
<head>
    {!! SEO::generate() !!}
</head>
```

### 3. Model-Based SEO (ralphjsmit/laravel-seo)

Store SEO data per model with Filament integration.

```bash
composer require ralphjsmit/laravel-seo
php artisan vendor:publish --tag="seo-migrations"
php artisan migrate
```

Add trait to model:

```php
use RalphJSmit\Laravel\SEO\Support\HasSEO;

final class Post extends Model
{
    use HasSEO;
}
```

In Filament resource, add SEO form field:

```php
use RalphJSmit\Filament\SEO\SEO;

public static function form(Form $form): Form
{
    return $form->schema([
        TextInput::make('title'),
        // ... other fields
        SEO::make(),
    ]);
}
```

## Environment Variables

```env
SCOUT_DRIVER=meilisearch  # if using Scout for indexing
```

## Output

Report installed packages, files created/modified, database migrations, and next steps for robots.txt and Google Search Console submission.

## Commands

```bash
php artisan sitemap:generate
php artisan migrate
```

## Reference

Detailed SEO patterns, canonical tags, robots.txt rules, and schema.org markup: see the **laravel-seo** reference skill.
