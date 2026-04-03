---
description: "Create a new MCP (Model Context Protocol) tool"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /mcp:make - Create MCP Tool

Create a new MCP tool for extending Claude Code capabilities with custom integrations.

## Input
$ARGUMENTS = `<tool-name> [description] [--type=php|typescript]`

Examples:
- `/mcp:make get_tickets "Fetch Jira tickets by project"`
- `/mcp:make run_tests "Execute test suite" --type=php`
- `/mcp:make deploy_app "Deploy application to server" --type=typescript`

## Process

1. **Parse Arguments**
   - `name`: Tool name (snake_case)
   - `description`: What the tool does
   - `--type`: php (default) or typescript

2. **Gather Tool Details**

   If not provided, ask:
   ```
   MCP Tool Configuration:
   - Name: <parsed>
   - Description: <parsed or ask>
   - Parameters: <ask for each>
     - name: <param name>
     - type: string|int|bool|array
     - description: <what it does>
     - required: yes|no
   - Return type: <ask>
   - Service dependency: <ask, optional>
   ```

3. **Validate Tool Name**

   ```
   ✓ get_tickets
   ✓ run_tests
   ✓ deploy_app
   ✗ getTickets (use snake_case)
   ✗ GET_TICKETS (use lowercase)
   ```

4. **Generate PHP MCP Tool**

   Create `mcp/src/Tools/<ToolName>Tool.php`:

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
       public function __construct(
           // Add service dependencies here
       ) {}

       public function __invoke(
           #[ToolParameter(description: '<param1 description>')]
           string $param1,

           #[ToolParameter(description: '<param2 description>', required: false)]
           ?int $param2 = null
       ): array {
           try {
               // Implementation here
               $result = $this->execute($param1, $param2);

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

       protected function execute(string $param1, ?int $param2): mixed
       {
           // TODO: Implement tool logic
           return [];
       }
   }
   ```

5. **Generate TypeScript MCP Tool** (if --type=typescript)

   Create `mcp/src/tools/<tool-name>.ts`:

   ```typescript
   import { Tool, ToolParameter } from '@modelcontextprotocol/sdk';

   interface <ToolName>Params {
     param1: string;
     param2?: number;
   }

   interface <ToolName>Result {
     success: boolean;
     data?: unknown;
     error?: string;
   }

   export const <toolName>Tool: Tool = {
     name: '<tool_name>',
     description: '<description>',
     inputSchema: {
       type: 'object',
       properties: {
         param1: {
           type: 'string',
           description: '<param1 description>',
         },
         param2: {
           type: 'number',
           description: '<param2 description>',
         },
       },
       required: ['param1'],
     },
   };

   export async function handle<ToolName>(
     params: <ToolName>Params
   ): Promise<<ToolName>Result> {
     try {
       // Implementation here
       const result = await execute(params);

       return {
         success: true,
         data: result,
       };
     } catch (error) {
       return {
         success: false,
         error: error instanceof Error ? error.message : 'Unknown error',
       };
     }
   }

   async function execute(params: <ToolName>Params): Promise<unknown> {
     // TODO: Implement tool logic
     return {};
   }
   ```

6. **Register Tool**

   **For PHP** - Add to service provider:
   ```php
   // mcp/src/McpServiceProvider.php
   public function tools(): array
   {
       return [
           // ... existing tools
           \App\Mcp\Tools\<ToolName>Tool::class,
       ];
   }
   ```

   **For TypeScript** - Add to index:
   ```typescript
   // mcp/src/index.ts
   import { <toolName>Tool, handle<ToolName> } from './tools/<tool-name>';

   server.tool(<toolName>Tool, handle<ToolName>);
   ```

7. **Generate Test**

   **For PHP** - Create `mcp/tests/Tools/<ToolName>ToolTest.php`:
   ```php
   <?php

   namespace Tests\Tools;

   use App\Mcp\Tools\<ToolName>Tool;
   use PHPUnit\Framework\TestCase;

   class <ToolName>ToolTest extends TestCase
   {
       public function test_it_returns_success_with_valid_input(): void
       {
           $tool = new <ToolName>Tool();

           $result = $tool('<param1_value>');

           $this->assertTrue($result['success']);
           $this->assertArrayHasKey('data', $result);
       }

       public function test_it_handles_errors_gracefully(): void
       {
           $tool = new <ToolName>Tool();

           $result = $tool('invalid_input');

           // Adjust assertion based on expected behavior
           $this->assertArrayHasKey('success', $result);
       }
   }
   ```

8. **Report Success**

   ```markdown
   ## MCP Tool Created: <tool_name>

   ### Files Created
   - `mcp/src/Tools/<ToolName>Tool.php` - Tool implementation
   - `mcp/tests/Tools/<ToolName>ToolTest.php` - Test file

   ### Registration
   Add to `mcp/src/McpServiceProvider.php`:
   ```php
   \App\Mcp\Tools\<ToolName>Tool::class,
   ```

   ### Tool Schema
   ```json
   {
     "name": "<tool_name>",
     "description": "<description>",
     "inputSchema": {
       "type": "object",
       "properties": {
         "param1": {"type": "string", "description": "..."},
         "param2": {"type": "integer", "description": "..."}
       },
       "required": ["param1"]
     }
   }
   ```

   ### Usage in Claude Code
   ```
   mcp__<server-name>__<tool_name>
   ```

   ### Next Steps
   1. Implement the tool logic in `execute()` method
   2. Add service dependencies if needed
   3. Run tests: `vendor/bin/pest mcp/tests/Tools/<ToolName>ToolTest.php`
   4. Register in service provider
   ```

## MCP Tool Patterns

### Pattern 1: Read-Only Tool
```php
public function __invoke(string $query): array
{
    $data = $this->service->search($query);
    return ['success' => true, 'data' => $data];
}
```

### Pattern 2: Action Tool
```php
public function __invoke(string $id, array $data): array
{
    $result = $this->service->update($id, $data);
    return ['success' => true, 'updated' => $result];
}
```

### Pattern 3: Batch Tool
```php
public function __invoke(array $items): array
{
    $results = [];
    foreach ($items as $item) {
        $results[] = $this->service->process($item);
    }
    return ['success' => true, 'processed' => count($results), 'results' => $results];
}
```
