# Laravel Database Migrations Reference

## Complete Migration Example

```php
<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('shipping_address_id')->nullable()->constrained('addresses');
            $table->string('order_number', 32)->unique();
            $table->enum('status', ['pending', 'processing', 'shipped', 'delivered', 'cancelled'])
                  ->default('pending');
            $table->decimal('subtotal', 10, 2);
            $table->decimal('tax', 10, 2)->default(0);
            $table->decimal('total', 10, 2);
            $table->text('notes')->nullable();
            $table->timestamp('shipped_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // Composite indexes for common queries
            $table->index(['user_id', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

## Relationship Patterns

```php
// One to Many
public function orders(): HasMany
{
    return $this->hasMany(Order::class);
}

// Many to Many with Pivot
public function roles(): BelongsToMany
{
    return $this->belongsToMany(Role::class)
        ->withPivot(['expires_at'])
        ->withTimestamps();
}

// Has Many Through
public function orderItems(): HasManyThrough
{
    return $this->hasManyThrough(OrderItem::class, Order::class);
}
```

## Database Transactions

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function () {
    $order = Order::create([...]);
    $order->items()->createMany([...]);
});
```
