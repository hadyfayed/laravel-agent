---
description: "Setup SEO infrastructure: sitemaps, meta tags, Open Graph, structured data"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /seo:setup - Configure SEO Infrastructure

Setup comprehensive SEO for your Laravel application including sitemaps, meta tags, Open Graph, and structured data.

## Input
$ARGUMENTS = `[--sitemap] [--meta] [--opengraph] [--schema] [--all]`

Examples:
- `/seo:setup` - Interactive setup
- `/seo:setup --sitemap` - Just sitemap generation
- `/seo:setup --meta` - Meta tags with artesaos/seotools
- `/seo:setup --all` - Complete SEO infrastructure

## Components

### 1. Sitemap Generation (spatie/laravel-sitemap)
Automatic XML sitemap generation with model support.

### 2. Meta Tags (artesaos/seotools)
Dynamic meta tags, Open Graph, Twitter Cards.

### 3. Model-Based SEO (ralphjsmit/laravel-seo)
Store SEO data per model with Filament integration.

## Process

### Sitemap Setup

1. **Install Package**
   ```bash
   composer require spatie/laravel-sitemap
   ```

2. **Create Generator Command**
   ```php
   <?php

   declare(strict_types=1);

   namespace App\Console\Commands;

   use App\Models\Post;
   use App\Models\Product;
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

3. **Schedule Generation**
   ```php
   $schedule->command('sitemap:generate')->daily();
   ```

### Meta Tags Setup (artesaos/seotools)

1. **Install Package**
   ```bash
   composer require artesaos/seotools
   php artisan vendor:publish --provider="Artesaos\SEOTools\Providers\SEOToolsServiceProvider"
   ```

2. **Configure Defaults**
   ```php
   // config/seotools.php
   return [
       'meta' => [
           'defaults' => [
               'title' => env('APP_NAME'),
               'description' => 'Your site description',
               'keywords' => ['laravel', 'application'],
               'canonical' => null,
               'robots' => 'index, follow',
           ],
       ],
       'opengraph' => [
           'defaults' => [
               'title' => env('APP_NAME'),
               'description' => 'Your site description',
               'type' => 'website',
               'site_name' => env('APP_NAME'),
           ],
       ],
       'twitter' => [
           'defaults' => [
               'card' => 'summary_large_image',
               'site' => '@yourhandle',
           ],
       ],
   ];
   ```

3. **Controller Usage**
   ```php
   use Artesaos\SEOTools\Facades\SEOTools;

   public function show(Post $post)
   {
       SEOTools::setTitle($post->title);
       SEOTools::setDescription($post->excerpt);
       SEOTools::opengraph()->setUrl(route('posts.show', $post));
       SEOTools::opengraph()->addImage($post->featured_image);
       SEOTools::twitter()->setImage($post->featured_image);
       SEOTools::jsonLd()->addImage($post->featured_image);

       return view('posts.show', compact('post'));
   }
   ```

4. **Blade Integration**
   ```blade
   <head>
       {!! SEO::generate() !!}
   </head>
   ```

### Model-Based SEO (ralphjsmit/laravel-seo)

1. **Install Package**
   ```bash
   composer require ralphjsmit/laravel-seo
   php artisan vendor:publish --tag="seo-migrations"
   php artisan migrate
   ```

2. **Add Trait to Model**
   ```php
   <?php

   namespace App\Models;

   use Illuminate\Database\Eloquent\Model;
   use RalphJSmit\Laravel\SEO\Support\HasSEO;

   final class Post extends Model
   {
       use HasSEO;
   }
   ```

3. **Create SEO in Controller**
   ```php
   public function store(Request $request)
   {
       $post = Post::create($request->validated());

       $post->seo()->update([
           'title' => $request->seo_title,
           'description' => $request->seo_description,
           'image' => $request->seo_image,
       ]);

       return redirect()->route('posts.show', $post);
   }
   ```

4. **Blade Component**
   ```blade
   <head>
       <x-seo::meta />
   </head>
   ```

5. **Filament Integration**
   ```php
   use RalphJSmit\Laravel\SEO\Support\SEOData;
   use RalphJSmit\Filament\SEO\SEO;

   public static function form(Form $form): Form
   {
       return $form->schema([
           TextInput::make('title'),
           RichEditor::make('content'),

           // SEO Section
           SEO::make(),
       ]);
   }
   ```

## Interactive Prompts

When run without flags:

1. **SEO components to setup?**
   - [x] Sitemap (spatie/laravel-sitemap)
   - [ ] Meta Tags (artesaos/seotools)
   - [ ] Model SEO (ralphjsmit/laravel-seo)
   - [ ] All components

2. **Sitemap generation method?**
   - Crawl-based (automatic URL discovery)
   - Model-based (from Eloquent models)
   - Hybrid (static + dynamic)

3. **Schedule sitemap generation?**
   - Daily (recommended)
   - Hourly
   - Weekly
   - Manual only

4. **Models with SEO data?**
   - (Select from existing models)

## Output

```markdown
## SEO Infrastructure Setup

### Packages Installed
- spatie/laravel-sitemap
- artesaos/seotools
- ralphjsmit/laravel-seo

### Files Created
- app/Console/Commands/GenerateSitemapCommand.php
- config/seotools.php (published)

### Files Modified
- app/Models/Post.php (HasSEO trait)
- app/Models/Page.php (HasSEO trait)
- resources/views/layouts/app.blade.php (SEO tags)

### Database
- Migration: create_seo_table

### Commands
```bash
php artisan sitemap:generate
```

### Schedule
- Sitemap: Daily at midnight

### Blade Usage
```blade
<head>
    {!! SEO::generate() !!}
    {{-- OR for model-based --}}
    <x-seo::meta />
</head>
```

### Controller Usage
```php
SEOTools::setTitle($title);
SEOTools::setDescription($description);
SEOTools::opengraph()->addImage($image);
```

### Next Steps
1. Run `php artisan migrate`
2. Run `php artisan sitemap:generate`
3. Add `Sitemap: https://yoursite.com/sitemap.xml` to robots.txt
4. Submit sitemap to Google Search Console
5. Configure default SEO values in config/seotools.php
```
