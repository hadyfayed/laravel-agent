---
name: ai-make
description: Generate AI features with Prism PHP (chat, embeddings, tool-calling) across OpenAI/Anthropic/Ollama; when adding AI services.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(composer require) Read Write Edit
argument-hint: "<Name> [chat|embeddings|tools|structured|mcp]"
---

## Task

Generate an AI-powered Laravel service using Prism PHP for multi-provider LLM support.

## Input

- **Name:** Service class name (e.g., `ChatBot`, `ProductRecommender`, `ContentAnalyzer`)
- **Type:** AI feature type (default: `chat`)
  - `chat` — Conversational AI with message history
  - `embeddings` — Vector embeddings & semantic search
  - `tools` — LLM with function/tool calling
  - `structured` — Structured JSON output (e.g. sentiment analysis)
  - `mcp` — MCP server tools for AI clients

## Steps

1. **Verify Prism is installed:**
   ```bash
   composer show prism-php/prism 2>/dev/null && echo "Prism installed" || composer require prism-php/prism
   ```

2. **Create service file** in `app/Services/AI/<Name>Service.php` following the pattern for your type:
   - **chat:** Conversation model, message history, streaming support
   - **embeddings:** Vector generation, pgvector storage, semantic search
   - **tools:** Tool definitions, handler functions, result processing
   - **structured:** JSON schema validation, type-safe output parsing
   - **mcp:** routes/mcp.php with tool + parameter definitions

3. **Add configuration** (if needed):
   - Update `.env` with provider API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.)
   - Publish Prism config: `php artisan vendor:publish --tag=prism-config`

4. **Create supporting files** (if type requires):
   - **chat:** Create `Conversation` and `Message` models + migrations
   - **embeddings:** Create `Document` model with pgvector migration, install pgvector extension
   - **tools:** Create a test with mocked Prism responses
   - **structured:** Define JSON schema inline; add tests

5. **Write tests** using `Prism::fake()` to avoid real API calls:
   ```php
   Prism::fake(['text' => 'mocked response']);
   ```

## Reference

For in-depth patterns, see the reference material:
- `${CLAUDE_SKILL_DIR}/references/prism-setup.md` — Installation and configuration
- `${CLAUDE_SKILL_DIR}/references/chat-and-embeddings.md` — Conversation & semantic search patterns
- `${CLAUDE_SKILL_DIR}/references/tool-calling.md` — Tool-calling service & MCP server examples
- `${CLAUDE_SKILL_DIR}/references/testing.md` — Test strategies with Prism::fake()

## Security guardrails

- Never expose API keys in code or logs
- Never send sensitive user data to LLMs without consent
- Always implement rate limiting for AI endpoints
- Always validate and sanitize LLM outputs before using
- Prefer streaming for long responses
- Prefer tool-calling over prompt engineering for structured tasks
- Use cost tracking in production
