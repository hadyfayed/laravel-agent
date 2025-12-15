---
description: "Create PDF generation feature using spatie/laravel-pdf"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /pdf:make - Create PDF Generation Feature

Generate PDF templates, controllers, and views using spatie/laravel-pdf (Browsershot-based) or barryvdh/laravel-dompdf.

## Input
$ARGUMENTS = `<PDFType> [--package=<spatie|dompdf>]`

Examples:
- `/pdf:make Invoice`
- `/pdf:make Report --package=dompdf`
- `/pdf:make Certificate`
- `/pdf:make Contract`

## Process

1. **Check/Install Package**
   ```bash
   # Prefer spatie/laravel-pdf (modern, CSS Grid/Flexbox support)
   composer show spatie/laravel-pdf 2>/dev/null || composer require spatie/laravel-pdf

   # Or barryvdh/laravel-dompdf (simpler, no Chromium needed)
   composer show barryvdh/laravel-dompdf 2>/dev/null || composer require barryvdh/laravel-dompdf
   ```

2. **Create PDF Structure**
   ```
   app/
   ├── Pdf/
   │   └── <Type>Pdf.php           # PDF generator class
   └── Http/
       └── Controllers/
           └── <Type>PdfController.php

   resources/views/pdf/
   └── <type>/
       ├── template.blade.php      # Main PDF template
       ├── header.blade.php        # Optional header
       └── footer.blade.php        # Optional footer
   ```

3. **Generate Files**

4. **Create Tests**

## Templates

### PDF Generator Class (Spatie)
```php
<?php

declare(strict_types=1);

namespace App\Pdf;

use App\Models\Invoice;
use Spatie\LaravelPdf\Facades\Pdf;
use Spatie\LaravelPdf\PdfBuilder;

final class InvoicePdf
{
    public function __construct(
        private readonly Invoice $invoice,
    ) {}

    public function generate(): PdfBuilder
    {
        return Pdf::view('pdf.invoice.template', [
            'invoice' => $this->invoice,
            'company' => config('app.company'),
        ])
        ->format('a4')
        ->headerView('pdf.invoice.header', ['invoice' => $this->invoice])
        ->footerView('pdf.invoice.footer');
    }

    public function download(): \Symfony\Component\HttpFoundation\Response
    {
        return $this->generate()
            ->name("invoice-{$this->invoice->number}.pdf")
            ->download();
    }

    public function save(string $path): void
    {
        $this->generate()->save($path);
    }

    public function stream(): \Symfony\Component\HttpFoundation\Response
    {
        return $this->generate()
            ->name("invoice-{$this->invoice->number}.pdf")
            ->inline();
    }
}
```

### PDF Generator Class (DomPDF)
```php
<?php

declare(strict_types=1);

namespace App\Pdf;

use App\Models\Invoice;
use Barryvdh\DomPDF\Facade\Pdf;

final class InvoicePdf
{
    public function __construct(
        private readonly Invoice $invoice,
    ) {}

    public function generate(): \Barryvdh\DomPDF\PDF
    {
        return Pdf::loadView('pdf.invoice.template', [
            'invoice' => $this->invoice,
            'company' => config('app.company'),
        ])
        ->setPaper('a4', 'portrait')
        ->setOptions([
            'isHtml5ParserEnabled' => true,
            'isRemoteEnabled' => true,
        ]);
    }

    public function download(): \Symfony\Component\HttpFoundation\Response
    {
        return $this->generate()->download("invoice-{$this->invoice->number}.pdf");
    }

    public function stream(): \Symfony\Component\HttpFoundation\Response
    {
        return $this->generate()->stream("invoice-{$this->invoice->number}.pdf");
    }

    public function save(string $path): void
    {
        $this->generate()->save($path);
    }
}
```

### PDF Controller
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Invoice;
use App\Pdf\InvoicePdf;
use Illuminate\Http\Request;

final class InvoicePdfController extends Controller
{
    public function download(Invoice $invoice)
    {
        $this->authorize('view', $invoice);

        return (new InvoicePdf($invoice))->download();
    }

    public function stream(Invoice $invoice)
    {
        $this->authorize('view', $invoice);

        return (new InvoicePdf($invoice))->stream();
    }
}
```

### PDF Blade Template
```blade
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice #{{ $invoice->number }}</title>
    <style>
        * { font-family: 'DejaVu Sans', sans-serif; }
        body { font-size: 12px; line-height: 1.4; color: #333; }
        .header { border-bottom: 2px solid #333; padding-bottom: 20px; margin-bottom: 20px; }
        .company-name { font-size: 24px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f5f5f5; }
        .total-row { font-weight: bold; font-size: 14px; }
        .text-right { text-align: right; }
        .footer { margin-top: 40px; font-size: 10px; color: #666; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">{{ $company['name'] ?? config('app.name') }}</div>
        <div>{{ $company['address'] ?? '' }}</div>
    </div>

    <h1>Invoice #{{ $invoice->number }}</h1>
    <p><strong>Date:</strong> {{ $invoice->date->format('F j, Y') }}</p>
    <p><strong>Due:</strong> {{ $invoice->due_date->format('F j, Y') }}</p>

    <h2>Bill To</h2>
    <p>{{ $invoice->customer->name }}<br>{{ $invoice->customer->address }}</p>

    <table>
        <thead>
            <tr>
                <th>Description</th>
                <th class="text-right">Qty</th>
                <th class="text-right">Price</th>
                <th class="text-right">Total</th>
            </tr>
        </thead>
        <tbody>
            @foreach($invoice->items as $item)
            <tr>
                <td>{{ $item->description }}</td>
                <td class="text-right">{{ $item->quantity }}</td>
                <td class="text-right">{{ $item->unit_price_formatted }}</td>
                <td class="text-right">{{ $item->total_formatted }}</td>
            </tr>
            @endforeach
            <tr class="total-row">
                <td colspan="3" class="text-right">Total</td>
                <td class="text-right">{{ $invoice->total_formatted }}</td>
            </tr>
        </tbody>
    </table>

    <div class="footer">
        <p>Thank you for your business!</p>
    </div>
</body>
</html>
```

## Routes
```php
Route::middleware('auth')->group(function () {
    Route::get('/invoices/{invoice}/pdf', [InvoicePdfController::class, 'download'])
        ->name('invoices.pdf.download');
    Route::get('/invoices/{invoice}/pdf/view', [InvoicePdfController::class, 'stream'])
        ->name('invoices.pdf.stream');
});
```

## Output

```markdown
## PDF Generation: <Type>

### Package
- spatie/laravel-pdf (or barryvdh/laravel-dompdf)

### Files Created
- app/Pdf/<Type>Pdf.php
- app/Http/Controllers/<Type>PdfController.php
- resources/views/pdf/<type>/template.blade.php
- resources/views/pdf/<type>/header.blade.php
- resources/views/pdf/<type>/footer.blade.php

### Routes Added
- GET /<types>/{<type>}/pdf - Download PDF
- GET /<types>/{<type>}/pdf/view - View in browser

### Usage
```php
// Download
return (new <Type>Pdf($model))->download();

// Stream (view in browser)
return (new <Type>Pdf($model))->stream();

// Save to storage
(new <Type>Pdf($model))->save(storage_path('app/pdfs/file.pdf'));
```

### Next Steps
1. Customize the PDF template in resources/views/pdf/<type>/
2. Add company config to config/app.php
3. Test with a sample record
```
