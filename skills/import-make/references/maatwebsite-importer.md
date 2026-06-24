# Maatwebsite Excel Importer

## Basic Import

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

## Upsert (Update or Create)

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

## Queued Import (Large Files)

```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\Product;
use App\Notifications\ImportFailedNotification;
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
                $user = \App\Models\User::find($this->userId);
                $user?->notify(new ImportFailedNotification(
                    $event->getException()->getMessage()
                ));
            },
        ];
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

    public function messages(): array
    {
        return [
            'file.mimes' => 'File must be CSV, XLSX, or XLS format.',
            'file.max' => 'File must not exceed 10MB.',
        ];
    }
}
```

## Import Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Imports\ProductImport;
use App\Imports\ProductQueuedImport;
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

## Routes

```php
Route::prefix('products')->middleware(['web', 'auth'])->group(function () {
    Route::get('/import', [ProductImportController::class, 'create'])->name('products.import.create');
    Route::post('/import', [ProductImportController::class, 'store'])->name('products.import.store');
    Route::post('/import/queued', [ProductImportController::class, 'storeQueued'])->name('products.import.queued');
});
```
