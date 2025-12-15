---
name: laravel-filament
description: >
  Build admin panels and CRUD interfaces with Filament 3. Use when the user wants
  to create an admin panel, back-office, dashboard, or manage resources through a UI.
  Triggers: "filament", "admin panel", "admin dashboard", "resource management",
  "back-office", "crud interface", "admin area".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Filament Skill

Build beautiful admin panels with Filament 3.

## When to Use

- Creating admin panels
- Building CRUD interfaces
- Dashboard and reporting
- Resource management UIs
- Back-office systems

## Quick Start

```bash
/laravel-agent:filament:make <Resource>
```

## Installation

```bash
composer require filament/filament
php artisan filament:install --panels
php artisan make:filament-user
```

## Resource Structure

```php
<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductResource\Pages;
use App\Models\Product;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

final class ProductResource extends Resource
{
    protected static ?string $model = Product::class;
    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';
    protected static ?string $navigationGroup = 'Shop';

    public static function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Section::make()->schema([
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),

                Forms\Components\TextInput::make('price')
                    ->required()
                    ->numeric()
                    ->prefix('$'),

                Forms\Components\RichEditor::make('description')
                    ->columnSpanFull(),

                Forms\Components\Select::make('category_id')
                    ->relationship('category', 'name')
                    ->searchable()
                    ->preload(),

                Forms\Components\Toggle::make('is_active')
                    ->default(true),
            ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('price')
                    ->money()
                    ->sortable(),

                Tables\Columns\TextColumn::make('category.name')
                    ->sortable(),

                Tables\Columns\IconColumn::make('is_active')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('category')
                    ->relationship('category', 'name'),

                Tables\Filters\TernaryFilter::make('is_active'),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit' => Pages\EditProduct::route('/{record}/edit'),
        ];
    }
}
```

## Key Components

### Form Components
- TextInput, Textarea, RichEditor
- Select, Radio, Checkbox, Toggle
- DatePicker, TimePicker
- FileUpload, SpatieMediaLibraryFileUpload
- Repeater, Builder, KeyValue

### Table Features
- Searchable, Sortable columns
- Filters (Select, Ternary, Custom)
- Actions (Edit, Delete, Custom)
- Bulk actions

### Widgets
```php
final class StatsOverview extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Total Orders', Order::count()),
            Stat::make('Revenue', '$' . Order::sum('total')),
        ];
    }
}
```

## Relation Managers

```php
<?php

namespace App\Filament\Resources\ProductResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

final class ReviewsRelationManager extends RelationManager
{
    protected static string $relationship = 'reviews';

    public function form(Form $form): Form
    {
        return $form->schema([
            Forms\Components\Textarea::make('content')
                ->required()
                ->maxLength(1000),

            Forms\Components\Select::make('rating')
                ->options([1 => '1 Star', 2 => '2 Stars', 3 => '3 Stars', 4 => '4 Stars', 5 => '5 Stars'])
                ->required(),
        ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name'),
                Tables\Columns\TextColumn::make('rating'),
                Tables\Columns\TextColumn::make('created_at')->dateTime(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ]);
    }
}
```

## Custom Actions

```php
use Filament\Tables\Actions\Action;

Tables\Actions\Action::make('approve')
    ->icon('heroicon-o-check')
    ->color('success')
    ->requiresConfirmation()
    ->action(fn (Product $record) => $record->approve())
    ->visible(fn (Product $record) => $record->isPending()),

Tables\Actions\Action::make('export')
    ->icon('heroicon-o-arrow-down-tray')
    ->action(function () {
        return response()->download(
            (new ProductExport)->store('exports/products.xlsx')
        );
    }),
```

## Custom Pages

```php
<?php

namespace App\Filament\Pages;

use Filament\Pages\Page;

final class Dashboard extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-chart-bar';
    protected static string $view = 'filament.pages.dashboard';

    protected function getHeaderWidgets(): array
    {
        return [
            StatsOverview::class,
            OrdersChart::class,
        ];
    }
}
```

## Form Dependencies

```php
Forms\Components\Select::make('country_id')
    ->relationship('country', 'name')
    ->live()
    ->afterStateUpdated(fn (Set $set) => $set('city_id', null)),

Forms\Components\Select::make('city_id')
    ->options(fn (Get $get) => City::where('country_id', $get('country_id'))->pluck('name', 'id'))
    ->disabled(fn (Get $get) => !$get('country_id')),
```

## Authorization

```php
// In Resource
public static function canViewAny(): bool
{
    return auth()->user()->can('view_products');
}

public static function canCreate(): bool
{
    return auth()->user()->can('create_products');
}

public static function canEdit(Model $record): bool
{
    return auth()->user()->can('edit_products');
}

public static function canDelete(Model $record): bool
{
    return auth()->user()->can('delete_products');
}
```

## Common Pitfalls

1. **Missing Navigation Icon** - Filament requires icons
   ```php
   protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';
   ```

2. **Not Registering Resources** - Add to Panel Provider
   ```php
   ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
   ```

3. **Form Field Name Mismatch** - Field names must match model attributes
   ```php
   // Bad - if column is 'product_name'
   Forms\Components\TextInput::make('name'),

   // Good
   Forms\Components\TextInput::make('product_name'),
   ```

4. **Missing Relationship Method** - Ensure model has the relationship
   ```php
   // Model must have:
   public function category(): BelongsTo
   {
       return $this->belongsTo(Category::class);
   }
   ```

5. **Select Without Searchable** - Large lists need search
   ```php
   Forms\Components\Select::make('category_id')
       ->relationship('category', 'name')
       ->searchable()  // Add this!
       ->preload(),
   ```

6. **Not Using Soft Deletes** - Add restore action
   ```php
   Tables\Actions\RestoreAction::make(),
   Tables\Actions\ForceDeleteAction::make(),

   // And in filters
   Tables\Filters\TrashedFilter::make(),
   ```

7. **Heavy Queries in Table** - Use column relationships
   ```php
   // Bad
   Tables\Columns\TextColumn::make('total')
       ->getStateUsing(fn ($record) => $record->items->sum('price')),

   // Good - add accessor or use withSum
   Tables\Columns\TextColumn::make('items_sum_price')
       ->label('Total'),
   ```

## Package Integration

- **bezhansalleh/filament-shield** - Roles and permissions
- **ralphjsmit/laravel-seo** - SEO fields
- **filament/spatie-laravel-media-library-plugin** - Media management
- **filament/spatie-laravel-settings-plugin** - Settings management

## Best Practices

- Use Sections to organize forms
- Add search to Select fields
- Use soft deletes with restore action
- Implement proper authorization
- Add global search
- Use relation managers for related data
- Keep forms under 15 fields per section
- Use tabs for complex resources
