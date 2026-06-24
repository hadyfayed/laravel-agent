---
name: pdf-make
description: Generate PDF documents (invoices, reports, certificates) using spatie/laravel-pdf or barryvdh/laravel-dompdf with templates and controllers; when adding PDF generation.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(composer require) Bash(composer show) Read Write Edit
argument-hint: "<PDFType> [--package=<spatie|dompdf>]"
---

## Task

Create a PDF generation feature with templated views and dedicated PDF class.

## Input

- **PDFType:** Class name (e.g., `Invoice`, `Report`, `Certificate`, `Contract`)
- **package:** Driver choice (default: `spatie`)
  - `spatie` — spatie/laravel-pdf (modern, CSS Grid/Flexbox, requires Chromium)
  - `dompdf` — barryvdh/laravel-dompdf (lightweight, no Chromium)

## Steps

1. **Install package** if not present:
   ```bash
   # Spatie (recommended for modern CSS)
   composer show spatie/laravel-pdf 2>/dev/null || composer require spatie/laravel-pdf

   # Or DomPDF (simpler, HTML/CSS2)
   composer show barryvdh/laravel-dompdf 2>/dev/null || composer require barryvdh/laravel-dompdf
   ```

2. **Create PDF structure**:
   ```
   app/
   ├── Pdf/
   │   └── <Type>Pdf.php
   └── Http/Controllers/
       └── <Type>PdfController.php

   resources/views/pdf/<type>/
   ├── template.blade.php
   ├── header.blade.php (optional)
   └── footer.blade.php (optional)
   ```

3. **Generate PDF class** in `app/Pdf/<Type>Pdf.php`:
   - Constructor accepts model/data
   - `generate()` method returns PdfBuilder (Spatie) or PDF instance (DomPDF)
   - `download()`, `stream()`, `save()` methods for output formats
   - Header/footer support

4. **Generate controller** in `app/Http/Controllers/<Type>PdfController.php`:
   - `download()` — Return PDF as download
   - `stream()` — Display in browser

5. **Create Blade templates** in `resources/views/pdf/<type>/`:
   - `template.blade.php` — Main content
   - `header.blade.php` — Repeating header
   - `footer.blade.php` — Repeating footer

6. **Add routes** (optional):
   ```php
   Route::get('/<types>/{<type>}/pdf', [<Type>PdfController::class, 'download'])
       ->name('<types>.pdf.download');
   Route::get('/<types>/{<type>}/pdf/view', [<Type>PdfController::class, 'stream'])
       ->name('<types>.pdf.stream');
   ```

## Output

```markdown
## PDF Generation: <Type>

### Files Created
- app/Pdf/<Type>Pdf.php
- app/Http/Controllers/<Type>PdfController.php
- resources/views/pdf/<type>/template.blade.php
- resources/views/pdf/<type>/header.blade.php
- resources/views/pdf/<type>/footer.blade.php

### Package
- spatie/laravel-pdf (or barryvdh/laravel-dompdf)

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
1. Customize template in resources/views/pdf/<type>/
2. Add routing in routes/web.php
3. Test with a sample record
```
