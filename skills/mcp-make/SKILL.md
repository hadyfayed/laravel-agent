---
name: mcp-make
description: Scaffold an MCP tool or server (PHP/TypeScript); when adding MCP capabilities to a plugin.
disable-model-invocation: true
allowed-tools: Read Write Edit Bash(mkdir *) Bash(test *) Bash(find *)
argument-hint: "<tool-name> [--type=php|typescript]"
---

## Task

Create a new MCP tool scaffolding in `mcp/src/Tools/` (PHP) or `mcp/src/tools/` (TypeScript).

## Input

Parse `$ARGUMENTS`:
- `<tool-name>`: tool name (snake_case for PHP, kebab-case for TypeScript)
- `[--type=php|typescript]`: language (default: php)

## Steps

1. **Validate name** — snake_case for PHP, kebab-case for TypeScript. Exit if invalid.

2. **Determine type** — default to PHP unless `--type=typescript` is set.

3. **PHP Tool** — Create `mcp/src/Tools/<ToolName>Tool.php`:

```php
<?php

namespace App\Mcp\Tools;

use PhpMcp\Server\Attributes\McpTool;
use PhpMcp\Server\Attributes\ToolParameter;

#[McpTool(
    name: '<tool_name>',
    description: '<description>'
)]
class <ToolName>Tool
{
    public function __construct() {}

    public function __invoke(
        #[ToolParameter(description: '<param1 description>')]
        string $param1
    ): array {
        try {
            $result = $this->execute($param1);
            return [
                'success' => true,
                'data' => $result,
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    protected function execute(string $param1): mixed
    {
        // TODO: Implement tool logic
        return [];
    }
}
```

4. **TypeScript Tool** — Create `mcp/src/tools/<tool-name>.ts`:

```typescript
export const <toolName>Tool = {
  name: '<tool_name>',
  description: '<description>',
  inputSchema: {
    type: 'object',
    properties: {
      param1: {
        type: 'string',
        description: '<param1 description>',
      },
    },
    required: ['param1'],
  },
};

export async function handle<ToolName>(params: any): Promise<any> {
  try {
    const result = await execute(params);
    return { success: true, data: result };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function execute(params: any): Promise<unknown> {
  // TODO: Implement tool logic
  return {};
}
```

5. **Create test file** (PHP):
   ```bash
   mkdir -p mcp/tests/Tools
   # Generate test stub for <ToolName>ToolTest.php
   ```

6. **Report creation**:
   - PHP: `mcp/src/Tools/<ToolName>Tool.php` + test stub
   - TypeScript: `mcp/src/tools/<tool-name>.ts`
   - Next: implement execute() logic, register in service provider/index file, and run tests
