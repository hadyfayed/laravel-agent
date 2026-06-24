# DomPDF Template Example

## PDF Generator Class (DomPDF)

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

## Key Differences from Spatie

- No Chromium required (pure PHP)
- CSS2 support only (no Grid/Flexbox)
- Simpler configuration
- Lighter resource usage
