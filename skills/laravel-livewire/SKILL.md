---
name: laravel-livewire
description: >
  Build reactive Livewire 3 components for Laravel applications. Use when the user
  wants to create interactive components, real-time updates, or dynamic forms without
  writing JavaScript. Triggers: "livewire", "reactive", "component", "real-time form",
  "dynamic table", "interactive", "SPA-like".
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash, Task
---

# Laravel Livewire Skill

Build reactive components with Livewire 3 for dynamic interfaces.

## When to Use

- Creating interactive forms
- Building data tables with sorting/filtering
- Real-time search
- Dynamic UI without JavaScript
- Modals and wizards

## Quick Start

```bash
/laravel-agent:livewire:make <ComponentName>
```

## Component Structure

```php
<?php

namespace App\Livewire;

use App\Models\Product;
use Livewire\Component;
use Livewire\WithPagination;

final class ProductTable extends Component
{
    use WithPagination;

    public string $search = '';
    public string $sortBy = 'name';
    public string $sortDirection = 'asc';

    public function updatedSearch(): void
    {
        $this->resetPage();
    }

    public function sort(string $column): void
    {
        if ($this->sortBy === $column) {
            $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            $this->sortBy = $column;
            $this->sortDirection = 'asc';
        }
    }

    public function render()
    {
        return view('livewire.product-table', [
            'products' => Product::query()
                ->where('name', 'like', "%{$this->search}%")
                ->orderBy($this->sortBy, $this->sortDirection)
                ->paginate(10),
        ]);
    }
}
```

## Key Features

### Forms
```php
use Livewire\Attributes\Validate;

#[Validate('required|min:3')]
public string $name = '';

#[Validate('required|email')]
public string $email = '';

public function save(): void
{
    $this->validate();
    User::create($this->only(['name', 'email']));
    $this->reset();
}
```

### File Uploads
```php
use Livewire\WithFileUploads;

final class ProfilePhoto extends Component
{
    use WithFileUploads;

    public $photo;

    public function save(): void
    {
        $this->validate(['photo' => 'image|max:1024']);
        $path = $this->photo->store('photos', 'public');
    }
}
```

### Modals
```php
public bool $showModal = false;

public function openModal(): void
{
    $this->showModal = true;
}

public function closeModal(): void
{
    $this->showModal = false;
    $this->reset();
}
```

### Real-time Validation
```php
public function updated($property): void
{
    $this->validateOnly($property);
}
```

## Blade Template

```blade
<div>
    <input wire:model.live="search" placeholder="Search...">

    <table>
        @foreach($products as $product)
            <tr wire:key="{{ $product->id }}">
                <td>{{ $product->name }}</td>
                <td>
                    <button wire:click="delete({{ $product->id }})"
                            wire:confirm="Are you sure?">
                        Delete
                    </button>
                </td>
            </tr>
        @endforeach
    </table>

    {{ $products->links() }}
</div>
```

## Loading States

```blade
<div>
    <button wire:click="save" wire:loading.attr="disabled">
        <span wire:loading.remove>Save</span>
        <span wire:loading>Saving...</span>
    </button>

    {{-- Target specific actions --}}
    <div wire:loading wire:target="save">
        Processing...
    </div>
</div>
```

## Computed Properties

```php
use Livewire\Attributes\Computed;

#[Computed]
public function total(): float
{
    return $this->items->sum('price');
}

// Access in blade: $this->total
```

## Events & Communication

```php
// Dispatch from component
$this->dispatch('order-created', orderId: $order->id);

// Listen in another component
#[On('order-created')]
public function handleOrderCreated(int $orderId): void
{
    $this->orders = Order::latest()->get();
}

// Dispatch to parent
$this->dispatch('itemAdded')->to(Cart::class);

// Browser events
$this->dispatch('notify', message: 'Saved!');
```

## Polling & Auto-refresh

```blade
{{-- Poll every 2 seconds --}}
<div wire:poll.2s>
    {{ $notifications->count() }} new notifications
</div>

{{-- Keep alive visible only --}}
<div wire:poll.visible.5s>
    Current time: {{ now() }}
</div>
```

## Common Pitfalls

1. **Missing wire:key** - Always use `wire:key` in loops to prevent DOM issues
   ```blade
   @foreach($items as $item)
       <div wire:key="item-{{ $item->id }}">...</div>
   @endforeach
   ```

2. **N+1 Queries in render()** - Eager load relationships
   ```php
   // Bad
   public function render()
   {
       return view('livewire.posts', [
           'posts' => Post::all(), // N+1 when accessing $post->author
       ]);
   }

   // Good
   public function render()
   {
       return view('livewire.posts', [
           'posts' => Post::with('author')->get(),
       ]);
   }
   ```

3. **Large Component State** - Keep public properties minimal
   ```php
   // Bad - storing entire collection
   public Collection $products;

   // Good - store IDs, query when needed
   public array $productIds = [];
   ```

4. **Not Debouncing Search** - Causes excessive requests
   ```blade
   {{-- Bad --}}
   <input wire:model.live="search">

   {{-- Good --}}
   <input wire:model.live.debounce.300ms="search">
   ```

5. **Forgetting to Reset Pagination** - When filters change
   ```php
   public function updatedSearch(): void
   {
       $this->resetPage(); // Reset to page 1
   }
   ```

6. **Memory Leaks with File Uploads** - Clean up temporary files
   ```php
   public function save(): void
   {
       $path = $this->photo->store('photos');
       $this->reset('photo'); // Clear temporary upload
   }
   ```

## Best Practices

- Use `wire:key` for list items
- Debounce search inputs: `wire:model.live.debounce.300ms`
- Use `#[Computed]` for derived data
- Keep components focused (single responsibility)
- Use events for cross-component communication
- Prefer `wire:navigate` for SPA-like navigation
- Use loading states for better UX
