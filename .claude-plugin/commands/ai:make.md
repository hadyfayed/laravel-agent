---
description: "Create AI-powered features using Prism PHP"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /ai:make - Create AI Feature

Generate AI-powered Laravel features with Prism PHP.

## Input
$ARGUMENTS = `<Name> [type]`

Examples:
- `/ai:make ChatBot` - Conversational AI service
- `/ai:make ProductRecommender embeddings` - Semantic search/recommendations
- `/ai:make OrderAssistant tools` - AI with tool calling
- `/ai:make ContentModerator structured` - Structured JSON output

## Types
- `chat` - Conversational AI (default)
- `embeddings` - Vector embeddings & semantic search
- `tools` - AI with function/tool calling
- `structured` - Structured JSON output
- `mcp` - MCP server tools

## Process

Use Task tool with subagent_type `laravel-ai`:
```
Create AI feature:

Name: <name>
Type: <type>
Provider: [openai|anthropic|ollama]
Features: [streaming, history, tools]
```
