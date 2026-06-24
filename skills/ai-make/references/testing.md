# Testing AI Services

## Test Strategies with Prism::fake()

```php
<?php

use App\Services\AI\TextGeneratorService;
use App\Services\AI\ContentAnalyzerService;
use Prism\Prism;

describe('AI Services', function () {
    beforeEach(function () {
        // Mock Prism for testing
        Prism::fake([
            'text' => 'This is a mocked AI response.',
        ]);
    });

    it('generates text', function () {
        $service = new TextGeneratorService();
        $result = $service->generate('Hello');

        expect($result)->toBe('This is a mocked AI response.');
    });

    it('analyzes sentiment', function () {
        Prism::fake([
            'text' => '{"sentiment":"positive","confidence":0.95,"keywords":["great","awesome"]}',
        ]);

        $service = new ContentAnalyzerService();
        $result = $service->analyzeSentiment('This is great!');

        expect($result)
            ->toHaveKey('sentiment', 'positive')
            ->toHaveKey('confidence');
    });
});
```

## Key Testing Principles

1. **Always use `Prism::fake()`** to avoid real API calls during tests
2. **Mock realistic responses** that match your service's expected output shape
3. **Test error handling** with error response mocks
4. **Verify message history** is stored correctly in conversation tests
5. **Assert pagination and limits** for semantic search tests
6. **Use data builders** to create test conversations with history

## Example: Conversation Service Test

```php
it('maintains message history', function () {
    $conversation = Conversation::factory()->create();
    $service = new ConversationService($conversation);

    Prism::fake(['text' => 'Hello back!']);

    $response = $service->chat('Hello');

    expect($response)->toBe('Hello back!')
        ->and($conversation->messages)->toHaveCount(2)
        ->and($conversation->messages->first()->content)->toBe('Hello')
        ->and($conversation->messages->last()->content)->toBe('Hello back!');
});
```

## Example: Tool-Calling Test

```php
it('calls order lookup tool', function () {
    $order = Order::factory()->create(['number' => 'ORD-123']);

    Prism::fake([
        'text' => 'Found order ORD-123 with status pending',
        'toolCalls' => [
            [
                'tool' => 'get_order',
                'parameters' => ['order_number' => 'ORD-123'],
            ],
        ],
    ]);

    $service = new OrderAssistantService();
    $result = $service->assist('What is the status of order ORD-123?');

    expect($result)->toContain('ORD-123');
});
```
