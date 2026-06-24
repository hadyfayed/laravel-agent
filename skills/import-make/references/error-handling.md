# Error Handling and Validation

## Failure Reporting (Maatwebsite)

```blade
{{-- resources/views/products/import.blade.php --}}
<div class="max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold mb-4">Import Products</h1>

    @if($errors->any())
        <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded">
            <h2 class="font-bold text-red-900">Import Errors</h2>
            <ul class="mt-2 list-disc pl-5">
                @foreach($errors->all() as $error)
                    <li class="text-red-700">{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    @if(session('failures'))
        <div class="mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded">
            <h2 class="font-bold text-yellow-900">
                Failed Rows ({{ session('failures')->count() }})
            </h2>
            <div class="mt-4 overflow-x-auto">
                <table class="min-w-full text-sm">
                    <thead class="bg-yellow-100">
                        <tr>
                            <th class="px-4 py-2 text-left">Row</th>
                            <th class="px-4 py-2 text-left">Errors</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach(session('failures') as $failure)
                            <tr class="border-t">
                                <td class="px-4 py-2 font-mono">{{ $failure->row() }}</td>
                                <td class="px-4 py-2">
                                    @foreach($failure->errors() as $error)
                                        <div class="text-yellow-700">{{ $error }}</div>
                                    @endforeach
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    @endif

    <form action="{{ route('products.import.store') }}" method="POST" enctype="multipart/form-data">
        @csrf

        <div class="mb-4">
            <label for="file" class="block font-medium mb-2">Select File (CSV, XLSX)</label>
            <input
                type="file"
                name="file"
                id="file"
                accept=".csv,.xlsx,.xls"
                required
                class="w-full px-4 py-2 border rounded @error('file') border-red-500 @enderror"
            />
            @error('file')
                <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
            @enderror
        </div>

        <div class="mb-4">
            <a href="{{ route('products.import.template') }}" class="text-blue-600 hover:underline">
                Download CSV template
            </a>
        </div>

        <button type="submit" class="px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            Import Products
        </button>
    </form>
</div>
```

## Template Download

```php
public function template(): Response
{
    $headers = [
        'name',
        'sku',
        'price',
        'stock',
        'category',
        'description',
    ];

    $path = storage_path('app/templates/products-template.csv');

    // Create directory if it doesn't exist
    if (!file_exists(dirname($path))) {
        mkdir(dirname($path), 0755, true);
    }

    // Create CSV with headers and one example row
    $handle = fopen($path, 'w');
    fputcsv($handle, $headers);
    fputcsv($handle, [
        'Example Product',
        'SKU-001',
        '29.99',
        '100',
        'Electronics',
        'Sample description',
    ]);
    fclose($handle);

    return response()->download($path, 'products-template.csv', [
        'Content-Type' => 'text/csv',
    ])->deleteFileAfterSend(true);
}
```

## Custom Validation Messages

```php
final class ProductImport implements
    ToModel,
    WithHeadingRow,
    WithValidation
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'sku' => 'required|string|unique:products,sku|regex:/^[A-Z0-9\-]+$/',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'category' => 'required|exists:categories,name',
        ];
    }

    public function customValidationMessages(): array
    {
        return [
            'sku.unique' => 'SKU :input already exists in row :attribute.',
            'sku.regex' => 'SKU must contain only uppercase letters, numbers, and hyphens.',
            'category.exists' => 'Category ":input" does not exist. Available categories: ' .
                \App\Models\Category::pluck('name')->implode(', '),
            'price.numeric' => 'Price must be a valid number.',
        ];
    }
}
```

## Logging and Auditing

```php
<?php

declare(strict_types=1);

namespace App\Imports;

use App\Models\ImportLog;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

final class ProductImport implements ToModel, WithHeadingRow
{
    private int $totalRows = 0;
    private int $failedRows = 0;

    public function __construct(
        private readonly int $userId,
    ) {}

    public function model(array $row): ?Product
    {
        $this->totalRows++;

        try {
            // Validation and creation...
            return new Product([
                'name' => $row['name'],
                'sku' => $row['sku'],
                'price_cents' => (int) ($row['price'] * 100),
            ]);
        } catch (\Exception $e) {
            $this->failedRows++;

            Log::error('Product import row failed', [
                'user_id' => $this->userId,
                'row' => $row,
                'error' => $e->getMessage(),
            ]);

            return null;
        }
    }

    public function __destruct()
    {
        if ($this->totalRows > 0) {
            ImportLog::create([
                'user_id' => $this->userId,
                'model' => 'Product',
                'total_rows' => $this->totalRows,
                'failed_rows' => $this->failedRows,
                'imported_rows' => $this->totalRows - $this->failedRows,
                'status' => $this->failedRows === 0 ? 'success' : 'partial',
            ]);
        }
    }
}
```

## Retry Logic for Transient Failures

```php
final class ProductImport
{
    private const MAX_RETRIES = 3;

    public function model(array $row): ?Product
    {
        return $this->retry(
            fn () => $this->createProduct($row),
            MAX_RETRIES
        );
    }

    private function createProduct(array $row): Product
    {
        return new Product([
            'name' => $row['name'],
            'sku' => $row['sku'],
            'price_cents' => (int) ($row['price'] * 100),
        ]);
    }

    private function retry(callable $callback, int $retries = 1): ?Product
    {
        $attempts = 0;

        while ($attempts < $retries) {
            try {
                return $callback();
            } catch (\Exception $e) {
                $attempts++;
                if ($attempts >= $retries) {
                    Log::error('Import failed after retries', [
                        'attempts' => $attempts,
                        'error' => $e->getMessage(),
                    ]);
                    return null;
                }
                usleep(100000); // Wait 100ms before retry
            }
        }

        return null;
    }
}
```
