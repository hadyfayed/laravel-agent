# Spatie Simple Excel Importer

## Streaming Import

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
    private int $skipped = 0;

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
                    $this->skipped++;
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

    public function getSkippedCount(): int
    {
        return $this->skipped;
    }

    public function hasErrors(): bool
    {
        return !empty($this->errors);
    }
}
```

## Chunked Processing (Memory Efficient)

```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use Spatie\SimpleExcel\SimpleExcelReader;
use Carbon\Carbon;

final class ProductChunkedImport
{
    private int $imported = 0;
    private int $chunkSize = 1000;

    public function import(string $path): self
    {
        SimpleExcelReader::create($path)
            ->useDelimiter(',')
            ->getRows()
            ->chunk($this->chunkSize)
            ->each(function ($chunk) {
                $this->processChunk($chunk);
            });

        return $this;
    }

    private function processChunk($chunk): void
    {
        $data = $chunk->map(function ($row) {
            return [
                'name' => $row['name'],
                'sku' => $row['sku'],
                'price_cents' => (int) ($row['price'] * 100),
                'stock' => (int) $row['stock'],
                'created_at' => now(),
                'updated_at' => now(),
            ];
        })->toArray();

        Product::insert($data);
        $this->imported += count($data);
    }

    public function getImportedCount(): int
    {
        return $this->imported;
    }
}
```

## Upsert with Deduplication

```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use Spatie\SimpleExcel\SimpleExcelReader;

final class ProductUpsertImport
{
    private int $updated = 0;
    private int $created = 0;

    public function import(string $path): self
    {
        SimpleExcelReader::create($path)
            ->getRows()
            ->chunk(500)
            ->each(function ($chunk) {
                foreach ($chunk as $row) {
                    $this->upsertRow($row);
                }
            });

        return $this;
    }

    private function upsertRow(array $row): void
    {
        $product = Product::updateOrCreate(
            ['sku' => $row['sku']],
            [
                'name' => $row['name'],
                'price_cents' => (int) ($row['price'] * 100),
                'stock' => (int) $row['stock'],
            ]
        );

        if ($product->wasRecentlyCreated) {
            $this->created++;
        } else {
            $this->updated++;
        }
    }

    public function getCreatedCount(): int
    {
        return $this->created;
    }

    public function getUpdatedCount(): int
    {
        return $this->updated;
    }
}
```

## Import Request

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

## Import Controller (Spatie)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Imports\ProductImport;
use App\Http\Requests\ProductImportRequest;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;
use Illuminate\Support\Facades\Log;

final class ProductImportController extends Controller
{
    public function create(): View
    {
        return view('products.import');
    }

    public function store(ProductImportRequest $request): RedirectResponse
    {
        try {
            $import = (new ProductImport())
                ->import($request->file('file')->path());

            if ($import->hasErrors()) {
                Log::warning('Import errors', $import->getErrors());

                return back()
                    ->with('warning', "Imported {$import->getImportedCount()} products with {$import->getSkippedCount()} errors.")
                    ->with('errors', $import->getErrors());
            }

            return redirect()
                ->route('products.index')
                ->with('success', "Imported {$import->getImportedCount()} products.");
        } catch (\Exception $e) {
            Log::error('Import failed', ['error' => $e->getMessage()]);

            return back()
                ->with('error', 'Import failed: ' . $e->getMessage());
        }
    }
}
```

## Routes (Spatie)

```php
Route::prefix('products')->middleware(['web', 'auth'])->group(function () {
    Route::get('/import', [ProductImportController::class, 'create'])->name('products.import.create');
    Route::post('/import', [ProductImportController::class, 'store'])->name('products.import.store');
});
```
