# Tool-Calling and MCP Patterns

## AI with Tool Calling

```php
<?php

declare(strict_types=1);

namespace App\Services\AI;

use App\Models\Order;
use Prism\Prism;
use Prism\Enums\Provider;
use Prism\Tool;

final class OrderAssistantService
{
    public function assist(string $userQuery): string
    {
        $response = Prism::text()
            ->using(Provider::OpenAI, 'gpt-4o')
            ->withSystemPrompt('You are an order management assistant.')
            ->withPrompt($userQuery)
            ->withTools($this->getTools())
            ->generate();

        return $response->text;
    }

    private function getTools(): array
    {
        return [
            Tool::as('get_order')
                ->for('Retrieve order details by order number')
                ->withStringParameter('order_number', 'The order number to look up')
                ->using(function (string $order_number): string {
                    $order = Order::where('number', $order_number)->first();

                    if (!$order) {
                        return json_encode(['error' => 'Order not found']);
                    }

                    return json_encode([
                        'number' => $order->number,
                        'status' => $order->status,
                        'total' => $order->total_formatted,
                        'items' => $order->items->count(),
                        'created_at' => $order->created_at->toDateTimeString(),
                    ]);
                }),

            Tool::as('list_recent_orders')
                ->for('List recent orders for a customer')
                ->withStringParameter('customer_email', 'Customer email address')
                ->withNumberParameter('limit', 'Number of orders to return', required: false)
                ->using(function (string $customer_email, int $limit = 5): string {
                    $orders = Order::whereHas('customer', fn ($q) =>
                        $q->where('email', $customer_email)
                    )
                    ->latest()
                    ->take($limit)
                    ->get(['number', 'status', 'total_cents', 'created_at']);

                    return $orders->toJson();
                }),

            Tool::as('cancel_order')
                ->for('Cancel a pending order')
                ->withStringParameter('order_number', 'The order number to cancel')
                ->withStringParameter('reason', 'Cancellation reason')
                ->using(function (string $order_number, string $reason): string {
                    $order = Order::where('number', $order_number)
                        ->where('status', 'pending')
                        ->first();

                    if (!$order) {
                        return json_encode(['error' => 'Order not found or cannot be cancelled']);
                    }

                    $order->update([
                        'status' => 'cancelled',
                        'cancellation_reason' => $reason,
                    ]);

                    return json_encode(['success' => true, 'message' => 'Order cancelled']);
                }),
        ];
    }
}
```

## Structured Output (JSON)

```php
<?php

declare(strict_types=1);

namespace App\Services\AI;

use Prism\Prism;
use Prism\Enums\Provider;

final class ContentAnalyzerService
{
    public function analyzeSentiment(string $text): array
    {
        $response = Prism::text()
            ->using(Provider::OpenAI, 'gpt-4o')
            ->withSystemPrompt('Analyze the sentiment of the text. Respond only with valid JSON.')
            ->withPrompt("Analyze: {$text}")
            ->withJsonSchema([
                'type' => 'object',
                'properties' => [
                    'sentiment' => [
                        'type' => 'string',
                        'enum' => ['positive', 'negative', 'neutral'],
                    ],
                    'confidence' => [
                        'type' => 'number',
                        'minimum' => 0,
                        'maximum' => 1,
                    ],
                    'keywords' => [
                        'type' => 'array',
                        'items' => ['type' => 'string'],
                    ],
                ],
                'required' => ['sentiment', 'confidence', 'keywords'],
            ])
            ->generate();

        return json_decode($response->text, true);
    }

    public function extractEntities(string $text): array
    {
        $response = Prism::text()
            ->using(Provider::OpenAI, 'gpt-4o')
            ->withSystemPrompt('Extract named entities from text. Return JSON.')
            ->withPrompt($text)
            ->withJsonSchema([
                'type' => 'object',
                'properties' => [
                    'people' => ['type' => 'array', 'items' => ['type' => 'string']],
                    'organizations' => ['type' => 'array', 'items' => ['type' => 'string']],
                    'locations' => ['type' => 'array', 'items' => ['type' => 'string']],
                    'dates' => ['type' => 'array', 'items' => ['type' => 'string']],
                ],
            ])
            ->generate();

        return json_decode($response->text, true);
    }
}
```

## Laravel MCP Server

```php
<?php

// routes/mcp.php
use Laravel\Mcp\Facades\Mcp;

Mcp::tool('get_user', function (int $userId) {
    return User::find($userId)?->toArray() ?? ['error' => 'User not found'];
})
->description('Retrieve user information by ID')
->parameter('userId', 'integer', 'The user ID to look up');

Mcp::tool('search_products', function (string $query, int $limit = 10) {
    return Product::search($query)->take($limit)->get()->toArray();
})
->description('Search products by name or description')
->parameter('query', 'string', 'Search query')
->parameter('limit', 'integer', 'Maximum results (default: 10)', required: false);

Mcp::tool('create_order', function (int $customerId, array $items) {
    $order = Order::create(['customer_id' => $customerId]);
    $order->items()->createMany($items);
    return $order->load('items')->toArray();
})
->description('Create a new order')
->parameter('customerId', 'integer', 'Customer ID')
->parameter('items', 'array', 'Array of order items');
```

## Basic Text Generation

```php
<?php

declare(strict_types=1);

namespace App\Services\AI;

use Prism\Prism;
use Prism\Enums\Provider;

final class TextGeneratorService
{
    public function generate(string $prompt, string $systemPrompt = ''): string
    {
        $response = Prism::text()
            ->using(Provider::OpenAI, 'gpt-4o')
            ->withSystemPrompt($systemPrompt ?: 'You are a helpful assistant.')
            ->withPrompt($prompt)
            ->generate();

        return $response->text;
    }

    public function generateWithContext(string $prompt, array $context): string
    {
        $contextString = collect($context)
            ->map(fn ($value, $key) => "{$key}: {$value}")
            ->implode("\n");

        return $this->generate(
            prompt: $prompt,
            systemPrompt: "Context:\n{$contextString}\n\nUse this context to answer questions."
        );
    }
}
```
