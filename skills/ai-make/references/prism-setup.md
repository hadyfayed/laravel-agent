# Prism PHP Setup and Configuration

## Installation

```bash
composer require prism-php/prism
php artisan vendor:publish --tag=prism-config
```

## Configuration (config/prism.php)

```php
return [
    'default' => env('PRISM_PROVIDER', 'openai'),

    'providers' => [
        'openai' => [
            'api_key' => env('OPENAI_API_KEY'),
            'organization' => env('OPENAI_ORGANIZATION'),
        ],
        'anthropic' => [
            'api_key' => env('ANTHROPIC_API_KEY'),
        ],
        'ollama' => [
            'url' => env('OLLAMA_URL', 'http://localhost:11434'),
        ],
    ],
];
```

## Environment Variables

```env
PRISM_PROVIDER=openai
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
OLLAMA_URL=http://localhost:11434
```

## Providers Supported

- **OpenAI:** `gpt-4o`, `gpt-4-turbo`, `gpt-3.5-turbo`, `text-embedding-3-small`, `text-embedding-3-large`
- **Anthropic:** `claude-opus-4`, `claude-sonnet-4`, `claude-haiku`
- **Ollama:** Local models (Llama 2, Mistral, etc.)

## Multi-Provider Usage

```php
// Explicit provider selection
Prism::text()
    ->using(Provider::OpenAI, 'gpt-4o')
    ->withSystemPrompt('...')
    ->withPrompt('...')
    ->generate();

// Use default provider from config
Prism::text()
    ->withSystemPrompt('...')
    ->withPrompt('...')
    ->generate();
```
