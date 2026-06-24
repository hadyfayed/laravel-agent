# Sitemap Generation (spatie/laravel-sitemap)

Automatic XML sitemap generation with model support.

## Installation

```bash
composer require spatie/laravel-sitemap
```

## Create Sitemap Command

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

## Schedule Generation

In `app/Console/Kernel.php`:

```php
protected function schedule(Schedule $schedule): void
{
    $schedule->command('sitemap:generate')->daily();
}
```

## Submit to Search Engines

After generating, submit `/sitemap.xml` to Google Search Console and Bing Webmaster Tools.
