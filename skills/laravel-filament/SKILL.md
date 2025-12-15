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

## Package Integration

- **bezhansalleh/filament-shield** - Roles and permissions
- **ralphjsmit/laravel-seo** - SEO fields
- **filament/spatie-laravel-media-library-plugin** - Media management

## Best Practices

- Use Sections to organize forms
- Add search to Select fields
- Use soft deletes with restore action
- Implement proper authorization
- Add global search
