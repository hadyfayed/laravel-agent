# Spatie PDF Template Examples

## PDF Generator Class (Spatie)

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

## Blade Template Example

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

    <div style="margin-top: 40px; font-size: 10px; color: #666; text-align: center;">
        <p>Thank you for your business!</p>
    </div>
</body>
</html>
```
