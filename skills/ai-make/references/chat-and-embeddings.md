# Chat and Embeddings Patterns

## Conversational AI Service

```php
<?php

declare(strict_types=1);

namespace App\Services\AI;

use App\Models\Conversation;
use App\Models\Message;
use Prism\Prism;
use Prism\Enums\Provider;
use Prism\ValueObjects\Messages\UserMessage;
use Prism\ValueObjects\Messages\AssistantMessage;

final class ConversationService
{
    public function __construct(
        private readonly Conversation $conversation,
    ) {}

    public function chat(string $userMessage): string
    {
        // Store user message
        $this->conversation->messages()->create([
            'role' => 'user',
            'content' => $userMessage,
        ]);

        // Build message history
        $messages = $this->conversation->messages()
            ->orderBy('created_at')
            ->get()
            ->map(fn (Message $msg) => match ($msg->role) {
                'user' => new UserMessage($msg->content),
                'assistant' => new AssistantMessage($msg->content),
            })
            ->toArray();

        // Generate response
        $response = Prism::text()
            ->using(Provider::OpenAI, 'gpt-4o')
            ->withSystemPrompt($this->conversation->system_prompt)
            ->withMessages($messages)
            ->generate();

        // Store assistant response
        $this->conversation->messages()->create([
            'role' => 'assistant',
            'content' => $response->text,
        ]);

        return $response->text;
    }

    public function streamChat(string $userMessage): \Generator
    {
        $this->conversation->messages()->create([
            'role' => 'user',
            'content' => $userMessage,
        ]);

        $messages = $this->buildMessageHistory();
        $fullResponse = '';

        $stream = Prism::text()
            ->using(Provider::OpenAI, 'gpt-4o')
            ->withSystemPrompt($this->conversation->system_prompt)
            ->withMessages($messages)
            ->stream();

        foreach ($stream as $chunk) {
            $fullResponse .= $chunk->text;
            yield $chunk->text;
        }

        $this->conversation->messages()->create([
            'role' => 'assistant',
            'content' => $fullResponse,
        ]);
    }

    private function buildMessageHistory(): array
    {
        return $this->conversation->messages()
            ->orderBy('created_at')
            ->get()
            ->map(fn (Message $msg) => match ($msg->role) {
                'user' => new UserMessage($msg->content),
                'assistant' => new AssistantMessage($msg->content),
            })
            ->toArray();
    }
}
```

## Embeddings Service

```php
<?php

declare(strict_types=1);

namespace App\Services\AI;

use Prism\Prism;
use Prism\Enums\Provider;
use Illuminate\Support\Collection;
use Pgvector\Laravel\Vector;

final class EmbeddingsService
{
    public function embed(string $text): array
    {
        $response = Prism::embeddings()
            ->using(Provider::OpenAI, 'text-embedding-3-small')
            ->fromInput($text)
            ->generate();

        return $response->embeddings[0]->embedding;
    }

    public function embedMany(array $texts): array
    {
        $response = Prism::embeddings()
            ->using(Provider::OpenAI, 'text-embedding-3-small')
            ->fromInput($texts)
            ->generate();

        return collect($response->embeddings)
            ->map(fn ($e) => $e->embedding)
            ->toArray();
    }

    /**
     * Semantic search using pgvector
     */
    public function semanticSearch(string $query, string $model, int $limit = 10): Collection
    {
        $queryEmbedding = $this->embed($query);

        return $model::query()
            ->orderByRaw('embedding <=> ?', [new Vector($queryEmbedding)])
            ->limit($limit)
            ->get();
    }

    /**
     * Find similar documents
     */
    public function findSimilar(string $model, int $id, int $limit = 5): Collection
    {
        $document = $model::find($id);

        return $model::query()
            ->where('id', '!=', $id)
            ->orderByRaw('embedding <=> ?', [new Vector($document->embedding)])
            ->limit($limit)
            ->get();
    }
}
```

## Database Schemas

### Conversations Table
```php
Schema::create('conversations', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('title')->nullable();
    $table->text('system_prompt')->nullable();
    $table->json('metadata')->nullable();
    $table->timestamps();
});
```

### Messages Table
```php
Schema::create('messages', function (Blueprint $table) {
    $table->id();
    $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
    $table->enum('role', ['user', 'assistant', 'system']);
    $table->text('content');
    $table->json('metadata')->nullable(); // tokens, model, etc.
    $table->timestamps();
});
```

### Documents Table (with pgvector)
```php
Schema::create('documents', function (Blueprint $table) {
    $table->id();
    $table->string('title');
    $table->text('content');
    $table->vector('embedding', 1536); // OpenAI dimension
    $table->timestamps();

    $table->index('embedding', 'documents_embedding_idx')
        ->algorithm('hnsw')
        ->with(['m' => 16, 'ef_construction' => 64]);
});
```

## Livewire Chat Component

```php
<?php

namespace App\Livewire;

use App\Services\AI\ConversationService;
use App\Models\Conversation;
use Livewire\Component;

class AiChat extends Component
{
    public Conversation $conversation;
    public string $message = '';
    public bool $isStreaming = false;
    public string $streamingResponse = '';

    public function mount(?int $conversationId = null): void
    {
        $this->conversation = $conversationId
            ? Conversation::findOrFail($conversationId)
            : Conversation::create([
                'user_id' => auth()->id(),
                'system_prompt' => 'You are a helpful assistant.',
            ]);
    }

    public function send(): void
    {
        if (empty(trim($this->message))) {
            return;
        }

        $userMessage = $this->message;
        $this->message = '';
        $this->isStreaming = true;
        $this->streamingResponse = '';

        $service = new ConversationService($this->conversation);

        foreach ($service->streamChat($userMessage) as $chunk) {
            $this->streamingResponse .= $chunk;
            $this->stream('response', $this->streamingResponse);
        }

        $this->isStreaming = false;
        $this->conversation->refresh();
    }

    public function render()
    {
        return view('livewire.ai-chat', [
            'messages' => $this->conversation->messages()->orderBy('created_at')->get(),
        ]);
    }
}
```
