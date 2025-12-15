---
description: "Create CSV/Excel importer using maatwebsite/excel or spatie/simple-excel"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /import:make - Create Data Importer

Generate robust CSV/Excel importers with validation, chunking, and error handling.

## Input
$ARGUMENTS = `<ImporterName> [--model=<Model>] [--package=<maatwebsite|spatie>]`

Examples:
- `/import:make ProductImport --model=Product`
- `/import:make UserImport --package=spatie`
- `/import:make OrderImport --model=Order`

## Process

1. **Install Package**
   ```bash
   # Maatwebsite Excel (full-featured, Laravel-specific)
   composer require maatwebsite/excel

   # OR Spatie Simple Excel (lightweight, streaming)
   composer require spatie/simple-excel
   ```

2. **Create Import Structure**
   ```
   app/
   ├── Imports/
   │   └── <Name>Import.php
   ├── Http/
   │   ├── Controllers/
   │   │   └── <Name>ImportController.php
   │   └── Requests/
   │       └── <Name>ImportRequest.php
   └── Jobs/
       └── Process<Name>Import.php
   ```

3. **Generate Validation Rules**

4. **Create Upload UI** (optional)

## Templates (Maatwebsite Excel)

### Basic Import
```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\SkipsOnFailure;
use Maatwebsite\Excel\Concerns\SkipsFailures;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;

final class ProductImport implements
    ToModel,
    WithHeadingRow,
    WithValidation,
    SkipsOnFailure,
    WithBatchInserts,
    WithChunkReading
{
    use SkipsFailures;

    public function model(array $row): ?Product
    {
        return new Product([
            'name' => $row['name'],
            'sku' => $row['sku'],
            'description' => $row['description'] ?? null,
            'price_cents' => (int) ($row['price'] * 100),
            'stock' => (int) $row['stock'],
            'category_id' => $this->findCategoryId($row['category']),
        ]);
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['required', 'string', 'unique:products,sku'],
            'price' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
            'category' => ['required', 'string'],
        ];
    }

    public function customValidationMessages(): array
    {
        return [
            'sku.unique' => 'SKU :input already exists.',
        ];
    }

    public function batchSize(): int
    {
        return 1000;
    }

    public function chunkSize(): int
    {
        return 1000;
    }

    private function findCategoryId(string $categoryName): ?int
    {
        return \App\Models\Category::firstWhere('name', $categoryName)?->id;
    }
}
```

### Import with Upsert (Update or Create)
```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithUpserts;

final class ProductUpsertImport implements ToModel, WithHeadingRow, WithUpserts
{
    public function model(array $row): ?Product
    {
        return new Product([
            'sku' => $row['sku'],
            'name' => $row['name'],
            'price_cents' => (int) ($row['price'] * 100),
            'stock' => (int) $row['stock'],
        ]);
    }

    public function uniqueBy(): string
    {
        return 'sku';
    }
}
```

### Queued Import (Large Files)
```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\ShouldQueue;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Events\ImportFailed;
use Illuminate\Contracts\Queue\ShouldQueue as ShouldQueueContract;
use Illuminate\Bus\Queueable;

final class ProductQueuedImport implements
    ToModel,
    WithHeadingRow,
    WithChunkReading,
    ShouldQueue,
    ShouldQueueContract,
    WithEvents
{
    use Queueable;

    public function __construct(
        public readonly int $userId,
    ) {}

    public function model(array $row): ?Product
    {
        return new Product([
            'name' => $row['name'],
            'sku' => $row['sku'],
            'price_cents' => (int) ($row['price'] * 100),
            'created_by_id' => $this->userId,
        ]);
    }

    public function chunkSize(): int
    {
        return 500;
    }

    public function registerEvents(): array
    {
        return [
            ImportFailed::class => function (ImportFailed $event) {
                // Notify user of failure
                \App\Models\User::find($this->userId)?->notify(
                    new \App\Notifications\ImportFailedNotification($event->getException())
                );
            },
        ];
    }
}
```

### Import Controller
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Imports\ProductImport;
use App\Http\Requests\ProductImportRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;
use Maatwebsite\Excel\Facades\Excel;

final class ProductImportController extends Controller
{
    public function create(): View
    {
        return view('products.import');
    }

    public function store(ProductImportRequest $request): RedirectResponse
    {
        $import = new ProductImport();

        Excel::import($import, $request->file('file'));

        $failures = $import->failures();

        if ($failures->isNotEmpty()) {
            return back()
                ->with('warning', "Imported with {$failures->count()} errors.")
                ->with('failures', $failures);
        }

        return redirect()
            ->route('products.index')
            ->with('success', 'Products imported successfully.');
    }

    /**
     * Queued import for large files.
     */
    public function storeQueued(ProductImportRequest $request): RedirectResponse
    {
        $import = new ProductQueuedImport(auth()->id());

        Excel::queueImport($import, $request->file('file'));

        return redirect()
            ->route('products.index')
            ->with('info', 'Import started. You will be notified when complete.');
    }
}
```

### Import Request
```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class ProductImportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('import', \App\Models\Product::class);
    }

    public function rules(): array
    {
        return [
            'file' => [
                'required',
                'file',
                'mimes:csv,xlsx,xls',
                'max:10240', // 10MB
            ],
        ];
    }
}
```

## Templates (Spatie Simple Excel)

### Streaming Import
```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use Spatie\SimpleExcel\SimpleExcelReader;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

final class ProductImport
{
    private array $errors = [];
    private int $imported = 0;

    public function import(string $path): self
    {
        SimpleExcelReader::create($path)
            ->useDelimiter(',')
            ->useHeaders(['name', 'sku', 'price', 'stock', 'category'])
            ->getRows()
            ->each(function (array $row, int $index) {
                try {
                    $this->importRow($row, $index + 2); // +2 for header and 0-index
                } catch (ValidationException $e) {
                    $this->errors[$index + 2] = $e->errors();
                }
            });

        return $this;
    }

    private function importRow(array $row, int $rowNumber): void
    {
        $validator = Validator::make($row, [
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['required', 'string', 'unique:products,sku'],
            'price' => ['required', 'numeric', 'min:0'],
            'stock' => ['required', 'integer', 'min:0'],
        ]);

        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        Product::create([
            'name' => $row['name'],
            'sku' => $row['sku'],
            'price_cents' => (int) ($row['price'] * 100),
            'stock' => (int) $row['stock'],
        ]);

        $this->imported++;
    }

    public function getErrors(): array
    {
        return $this->errors;
    }

    public function getImportedCount(): int
    {
        return $this->imported;
    }

    public function hasErrors(): bool
    {
        return !empty($this->errors);
    }
}
```

### Chunked Processing (Memory Efficient)
```php
<?php

use Spatie\SimpleExcel\SimpleExcelReader;

SimpleExcelReader::create($filePath)
    ->useDelimiter(',')
    ->getRows()
    ->chunk(1000)
    ->each(function ($chunk) {
        $data = $chunk->map(fn ($row) => [
            'name' => $row['name'],
            'sku' => $row['sku'],
            'price_cents' => (int) ($row['price'] * 100),
            'created_at' => now(),
            'updated_at' => now(),
        ])->toArray();

        Product::insert($data);
    });
```

### Import View
```blade
{{-- resources/views/products/import.blade.php --}}
<form action="{{ route('products.import') }}" method="POST" enctype="multipart/form-data">
    @csrf

    <div class="mb-4">
        <label for="file" class="block font-medium">Import File (CSV, XLSX)</label>
        <input type="file" name="file" id="file" accept=".csv,.xlsx,.xls" required>
        @error('file')
            <p class="text-red-500 text-sm">{{ $message }}</p>
        @enderror
    </div>

    <div class="mb-4">
        <a href="{{ route('products.import.template') }}" class="text-blue-600">
            Download template
        </a>
    </div>

    <button type="submit" class="btn btn-primary">Import</button>
</form>

@if(session('failures'))
    <div class="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded">
        <h3 class="font-bold">Import Errors</h3>
        <ul class="list-disc pl-5 mt-2">
            @foreach(session('failures') as $failure)
                <li>
                    Row {{ $failure->row() }}:
                    {{ implode(', ', $failure->errors()) }}
                </li>
            @endforeach
        </ul>
    </div>
@endif
```

## Interactive Prompts

When run without arguments, prompt user for:

1. **Import name?**
   - (text input)

2. **Target model?**
   - (select from existing models)

3. **Package preference?**
   - Maatwebsite Excel (full-featured)
   - Spatie Simple Excel (lightweight)

4. **Import behavior?**
   - Create only (skip existing)
   - Upsert (update or create)
   - Replace all

5. **File types to support?**
   - [x] CSV
   - [x] XLSX
   - [ ] XLS

6. **Large file support?**
   - Yes (queued, chunked processing)
   - No (synchronous)

## Output

```markdown
## Importer Created: <Name>Import

### Package Installed
- maatwebsite/excel (or spatie/simple-excel)

### Files Created
- app/Imports/<Name>Import.php
- app/Http/Controllers/<Name>ImportController.php
- app/Http/Requests/<Name>ImportRequest.php
- resources/views/<name>/import.blade.php

### Routes Added
```php
Route::get('/<name>/import', [<Name>ImportController::class, 'create']);
Route::post('/<name>/import', [<Name>ImportController::class, 'store']);
Route::get('/<name>/import/template', [<Name>ImportController::class, 'template']);
```

### Expected CSV Format
```csv
name,sku,price,stock,category
"Product Name","SKU-001",29.99,100,"Category Name"
```

### Usage
```php
// Synchronous import
Excel::import(new <Name>Import, $file);

// Queued import (large files)
Excel::queueImport(new <Name>Import, $file);
```

### Next Steps
1. Customize validation rules in Import class
2. Add column mappings if needed
3. Create download template route
4. Test with sample file
```
