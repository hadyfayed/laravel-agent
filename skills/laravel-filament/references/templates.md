---
name: laravel-filament
description: Code templates for Filament resources, forms, tables, relation managers, pages, and widgets
---

# RESOURCE COMPONENT

```php
<?php

declare(strict_types=1);

namespace App\Filament\Resources;

use App\Filament\Resources\<Name>Resource\Pages;
use App\Models\<Name>;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

final class <Name>Resource extends Resource
{
    protected static ?string $model = <Name>::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    protected static ?string $navigationGroup = 'Management';

    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Details')
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255)
                            ->live(onBlur: true)
                            ->afterStateUpdated(fn ($state, $set) =>
                                $set('slug', \Str::slug($state))
                            ),

                        Forms\Components\TextInput::make('slug')
                            ->required()
                            ->maxLength(255)
                            ->unique(ignoreRecord: true),

                        Forms\Components\RichEditor::make('description')
                            ->columnSpanFull(),

                        Forms\Components\Select::make('status')
                            ->options([
                                'draft' => 'Draft',
                                'active' => 'Active',
                                'archived' => 'Archived',
                            ])
                            ->required()
                            ->default('draft'),

                        Forms\Components\Select::make('category_id')
                            ->relationship('category', 'name')
                            ->searchable()
                            ->preload()
                            ->createOptionForm([
                                Forms\Components\TextInput::make('name')
                                    ->required(),
                            ]),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Pricing')
                    ->schema([
                        Forms\Components\TextInput::make('price')
                            ->numeric()
                            ->prefix('$')
                            ->maxValue(999999.99),

                        Forms\Components\TextInput::make('compare_price')
                            ->numeric()
                            ->prefix('$')
                            ->gt('price'),
                    ])
                    ->columns(2),

                Forms\Components\Section::make('Media')
                    ->schema([
                        Forms\Components\FileUpload::make('image')
                            ->image()
                            ->directory('<names>')
                            ->imageEditor(),

                        Forms\Components\FileUpload::make('gallery')
                            ->image()
                            ->multiple()
                            ->directory('<names>/gallery')
                            ->reorderable(),
                    ]),

                Forms\Components\Section::make('SEO')
                    ->schema([
                        Forms\Components\TextInput::make('meta_title')
                            ->maxLength(60),

                        Forms\Components\Textarea::make('meta_description')
                            ->maxLength(160),
                    ])
                    ->collapsed(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('image')
                    ->circular(),

                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),

                Tables\Columns\TextColumn::make('category.name')
                    ->sortable(),

                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'gray' => 'draft',
                        'success' => 'active',
                        'danger' => 'archived',
                    ]),

                Tables\Columns\TextColumn::make('price')
                    ->money('USD')
                    ->sortable(),

                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'draft' => 'Draft',
                        'active' => 'Active',
                        'archived' => 'Archived',
                    ]),

                Tables\Filters\SelectFilter::make('category')
                    ->relationship('category', 'name'),

                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\ForceDeleteBulkAction::make(),
                    Tables\Actions\RestoreBulkAction::make(),

                    Tables\Actions\BulkAction::make('updateStatus')
                        ->label('Update Status')
                        ->icon('heroicon-o-check')
                        ->form([
                            Forms\Components\Select::make('status')
                                ->options([
                                    'draft' => 'Draft',
                                    'active' => 'Active',
                                    'archived' => 'Archived',
                                ])
                                ->required(),
                        ])
                        ->action(function ($records, array $data) {
                            $records->each->update(['status' => $data['status']]);
                        }),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [
            // RelationManagers\TagsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\List<Names>::route('/'),
            'create' => Pages\Create<Name>::route('/create'),
            'edit' => Pages\Edit<Name>::route('/{record}/edit'),
        ];
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->withoutGlobalScopes([
                SoftDeletingScope::class,
            ]);
    }

    public static function getGloballySearchableAttributes(): array
    {
        return ['name', 'description'];
    }
}
```

# RELATION MANAGER

```php
<?php

namespace App\Filament\Resources\<Name>Resource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

final class ItemsRelationManager extends RelationManager
{
    protected static string $relationship = 'items';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),

                Forms\Components\TextInput::make('quantity')
                    ->numeric()
                    ->required()
                    ->default(1),

                Forms\Components\TextInput::make('price')
                    ->numeric()
                    ->required()
                    ->prefix('$'),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name'),
                Tables\Columns\TextColumn::make('quantity'),
                Tables\Columns\TextColumn::make('price')->money('USD'),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make(),
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
}
```

# CUSTOM PAGE

```php
<?php

namespace App\Filament\Pages;

use Filament\Pages\Page;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Forms;
use Filament\Notifications\Notification;

final class Settings extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog';
    protected static string $view = 'filament.pages.settings';
    protected static ?string $navigationGroup = 'System';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'site_name' => config('app.name'),
            'site_email' => config('mail.from.address'),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('General')
                    ->schema([
                        Forms\Components\TextInput::make('site_name')
                            ->required(),
                        Forms\Components\TextInput::make('site_email')
                            ->email()
                            ->required(),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        // Save settings...

        Notification::make()
            ->title('Settings saved')
            ->success()
            ->send();
    }
}
```

# WIDGET - STATS OVERVIEW

```php
<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

final class StatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        return [
            Stat::make('Total Users', User::count())
                ->description('32% increase')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success')
                ->chart([7, 3, 4, 5, 6, 3, 5, 8]),

            Stat::make('Total Orders', Order::count())
                ->description('Orders this month')
                ->color('primary'),

            Stat::make('Revenue', '$' . number_format(Order::sum('total_cents') / 100, 2))
                ->description('12% increase')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success'),
        ];
    }
}
```

# WIDGET - CHART

```php
<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;

final class OrdersChart extends ChartWidget
{
    protected static ?string $heading = 'Orders';
    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $data = Trend::model(Order::class)
            ->between(
                start: now()->subMonths(6),
                end: now(),
            )
            ->perMonth()
            ->count();

        return [
            'datasets' => [
                [
                    'label' => 'Orders',
                    'data' => $data->map(fn (TrendValue $value) => $value->aggregate),
                ],
            ],
            'labels' => $data->map(fn (TrendValue $value) => $value->date),
        ];
    }

    protected function getType(): string
    {
        return 'line'; // line, bar, pie, doughnut
    }
}
```

# CUSTOM ACTION

```php
Tables\Actions\Action::make('approve')
    ->label('Approve')
    ->icon('heroicon-o-check')
    ->color('success')
    ->requiresConfirmation()
    ->modalHeading('Approve Order')
    ->modalDescription('Are you sure you want to approve this order?')
    ->action(function (<Name> $record) {
        $record->update(['status' => 'approved']);

        Notification::make()
            ->title('Order Approved')
            ->success()
            ->send();
    })
    ->visible(fn (<Name> $record) => $record->status === 'pending'),
```

# SHIELD INTEGRATION

For RBAC in Filament, use the **laravel-auth** skill to implement Shield permissions. The auth skill handles:
- Shield configuration (permissions/roles)
- Policy generation with proper permission checks
- Role seeders with appropriate permissions

Simple inline authorization (for basic cases):

```php
// In Resource
public static function canViewAny(): bool
{
    return auth()->user()->hasPermission('read-<names>');
}

public static function canCreate(): bool
{
    return auth()->user()->hasPermission('create-<names>');
}

public static function canEdit(Model $record): bool
{
    return auth()->user()->hasPermission('update-<names>');
}

public static function canDelete(Model $record): bool
{
    return auth()->user()->hasPermission('delete-<names>');
}
```

# MULTI-TENANCY

```php
// In Resource
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->where('created_for_id', auth()->user()->current_tenant_id);
}

// Or use Filament's tenant features
// In Panel Provider
->tenant(Team::class)
->tenantRegistration(RegisterTeam::class)
```
