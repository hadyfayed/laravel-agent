# Headless CMS Template

A content API with Filament admin panel for managing content that can be consumed by any frontend.

## Features

- **Content API**: RESTful + GraphQL endpoints for content delivery
- **Filament Admin**: Full-featured admin panel for content management
- **Media Library**: Spatie Media Library for assets
- **Localization**: Multi-language content support
- **SEO**: Meta tags, slugs, sitemaps
- **Caching**: Redis caching for API responses
- **Webhooks**: Notify external services on content changes

## Quick Start

```bash
# Create new project
laravel new my-cms --git

# Install dependencies
composer require \
    filament/filament:^3.0 \
    spatie/laravel-medialibrary \
    spatie/laravel-translatable \
    spatie/laravel-sluggable \
    spatie/laravel-tags \
    nuwave/lighthouse

# Run the setup command
/project:init headless-cms
```

## Directory Structure

```
app/
├── Filament/
│   ├── Resources/
│   │   ├── PostResource.php
│   │   ├── PageResource.php
│   │   ├── CategoryResource.php
│   │   └── MediaResource.php
│   └── Widgets/
├── Models/
│   ├── Post.php
│   ├── Page.php
│   ├── Category.php
│   └── Media.php
├── Http/
│   ├── Controllers/Api/
│   │   └── ContentController.php
│   └── Resources/
│       ├── PostResource.php
│       └── PageResource.php
graphql/
├── schema.graphql
└── types/
```

## Content Models

### Post
```php
class Post extends Model
{
    use HasSlug, HasTranslations, HasTags, HasMedia;

    public array $translatable = ['title', 'content', 'excerpt', 'meta_description'];

    protected $casts = [
        'published_at' => 'datetime',
        'is_featured' => 'boolean',
    ];
}
```

### Page
```php
class Page extends Model
{
    use HasSlug, HasTranslations, HasMedia;

    public array $translatable = ['title', 'content', 'meta_title', 'meta_description'];
}
```

## API Endpoints

### REST API
```
GET    /api/v1/posts              List posts
GET    /api/v1/posts/{slug}       Get post by slug
GET    /api/v1/pages/{slug}       Get page by slug
GET    /api/v1/categories         List categories
GET    /api/v1/tags               List tags
GET    /api/v1/search?q=          Search content
```

### GraphQL API
```graphql
query {
    posts(first: 10, where: { is_published: true }) {
        data {
            id
            title
            slug
            excerpt
            featured_image
            category {
                name
            }
            tags {
                name
            }
        }
    }
}

query {
    post(slug: "hello-world") {
        title
        content
        author {
            name
        }
        related_posts {
            title
            slug
        }
    }
}
```

## Filament Admin

Access at `/admin`

### Resources
- **Posts**: Create, edit, publish blog posts
- **Pages**: Static pages with flexible content
- **Categories**: Organize content
- **Media**: Upload and manage assets
- **Users**: Admin user management

### Features
- Rich text editor (Tiptap)
- Media picker
- SEO fields
- Publishing workflow (draft → review → published)
- Content versioning
- Scheduled publishing

## Caching Strategy

```php
// Cache API responses
Cache::tags(['content', 'posts'])->remember(
    "posts.{$locale}.page.{$page}",
    now()->addHour(),
    fn () => Post::published()->paginate()
);

// Invalidate on update
protected static function booted()
{
    static::saved(fn () => Cache::tags(['posts'])->flush());
}
```

## Webhooks

Notify external services (Netlify, Vercel, etc.) on content changes:

```php
// Dispatch webhook on publish
event(new ContentPublished($post));

// Listener sends webhook
Http::post(config('cms.webhook_url'), [
    'event' => 'content.published',
    'type' => 'post',
    'id' => $post->id,
    'slug' => $post->slug,
]);
```

## Slash Commands

- `/feature:make Articles` - Create content type
- `/filament:make ContentType` - Add Filament resource
- `/api:make Content` - Create API endpoints
