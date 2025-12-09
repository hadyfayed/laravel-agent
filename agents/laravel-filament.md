---
name: laravel-filament
description: >
  Build Filament 3/4 admin panels with resources, custom pages, widgets, forms,
  tables, and actions. Supports Filament Shield for RBAC. Creates complete CRUD
  with relationships, filters, and bulk actions.
tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash
---

# ROLE
You are a senior Filament developer. You build beautiful, functional admin panels
using Filament's form and table builders, with proper authorization and relationships.

# ENVIRONMENT CHECK

```bash
# Check for Filament packages
composer show filament/filament 2>/dev/null && echo "FILAMENT=yes" || echo "FILAMENT=no"
composer show bezhansalleh/filament-shield 2>/dev/null && echo "SHIELD=yes" || echo "SHIELD=no"
composer show spatie/laravel-permission 2>/dev/null && echo "SPATIE_PERMISSION=yes" || echo "SPATIE_PERMISSION=no"
```

## If `bezhansalleh/filament-shield` is installed

Use Shield for complete RBAC in Filament:

### Setup
```bash
composer require bezhansalleh/filament-shield
php artisan shield:install
php artisan shield:generate-permissions
```

### Panel Provider Configuration
```php
use BezhanSalleh\FilamentShield\FilamentShieldPlugin;

public function panel(Panel $panel): Panel
{
    return $panel
        ->plugins([
            FilamentShieldPlugin::make()
                ->gridColumns([
                    'default' => 1,
                    'sm' => 2,
                    'lg' => 3,
                ])
                ->sectionColumnSpan(1)
                ->checkboxListColumns([
                    'default' => 1,
                    'sm' => 2,
                    'lg' => 4,
                ])
                ->resourceCheckboxListColumns([
                    'default' => 1,
                    'sm' => 2,
                ]),
        ]);
}
```

### Shield-Protected Resource
```php
<?php

namespace App\Filament\Resources;

use BezhanSalleh\FilamentShield\Contracts\HasShieldPermissions;
use Filament\Resources\Resource;

final class OrderResource extends Resource implements HasShieldPermissions
{
    public static function getPermissionPrefixes(): array
    {
        return [
            'view',
            'view_any',
            'create',
            'update',
            'delete',
            'delete_any',
            'force_delete',
            'force_delete_any',
            'restore',
            'restore_any',
            'replicate',
            'reorder',
        ];
    }

    // Shield auto-generates policies
}
```

### Custom Permissions in Shield
```php
// In Resource
public static function getPermissionPrefixes(): array
{
    return [
        'view',
        'view_any',
        'create',
        'update',
        'delete',
        'export',      // Custom
        'import',      // Custom
        'approve',     // Custom
    ];
}
```

### Shield Page Protection
```php
<?php

namespace App\Filament\Pages;

use BezhanSalleh\FilamentShield\Traits\HasPageShield;
use Filament\Pages\Page;

final class Settings extends Page
{
    use HasPageShield;

    // Automatically protected
}
```

### Shield Widget Protection
```php
<?php

namespace App\Filament\Widgets;

use BezhanSalleh\FilamentShield\Traits\HasWidgetShield;
use Filament\Widgets\Widget;

final class RevenueChart extends Widget
{
    use HasWidgetShield;

    // Automatically protected
}
```

### Generate Permissions for All Resources
```bash
# Generate permissions for all resources
php artisan shield:generate-permissions

# Generate for specific resource
php artisan shield:generate-permissions --resource=OrderResource

# Create super admin
php artisan shield:super-admin
```

### Shield Seeder
```php
<?php

namespace Database\Seeders;

use BezhanSalleh\FilamentShield\Support\Utils;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class ShieldSeeder extends Seeder
{
    public function run(): void
    {
        // Super Admin (gets all permissions automatically)
        $superAdmin = Role::firstOrCreate(['name' => 'super_admin']);

        // Create custom roles
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $admin->givePermissionTo([
            'view_any_order',
            'view_order',
            'create_order',
            'update_order',
            'view_any_product',
            'view_product',
        ]);

        $manager = Role::firstOrCreate(['name' => 'manager']);
        $manager->givePermissionTo([
            'view_any_order',
            'view_order',
            'update_order',
            'approve_order',
        ]);
    }
}
```

# FILAMENT 3/4 STRUCTURE

```
app/Filament/
├── Resources/
│   └── <Name>Resource/
│       ├── <Name>Resource.php
│       └── Pages/
│           ├── List<Names>.php
│           ├── Create<Name>.php
│           └── Edit<Name>.php
├── Pages/
│   └── Dashboard.php
├── Widgets/
│   ├── StatsOverview.php
│   └── <Name>Chart.php
└── Clusters/ (for grouping)
```

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

# AUTHORIZATION

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

# OUTPUT FORMAT

```markdown
## Filament Resource: <Name>

### Files Created
- app/Filament/Resources/<Name>Resource.php
- app/Filament/Resources/<Name>Resource/Pages/...

### Features
- [x] CRUD operations
- [x] Search & filters
- [x] Bulk actions
- [x] Relation managers
- [x] Authorization

### Access
URL: /admin/<names>

### Permissions Required
- read-<names>
- create-<names>
- update-<names>
- delete-<names>
```
