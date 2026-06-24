# Distance Queries and Spatial Scopes

## Location Model with Haversine Scopes

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Services\GeocodingService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;

final class Location extends Model
{
    protected $guarded = ['id'];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    /**
     * Geocode address before saving.
     */
    protected static function booted(): void
    {
        static::saving(function (Location $location) {
            if ($location->isDirty('address') && !$location->latitude) {
                $geocoder = app(GeocodingService::class);
                $result = $geocoder->geocode($location->address);

                if ($result) {
                    $location->latitude = $result['lat'];
                    $location->longitude = $result['lng'];
                    $location->formatted_address = $result['formatted_address'];
                }
            }
        });
    }

    /**
     * Find locations within radius (km).
     * Uses Haversine formula for distance calculation.
     */
    public function scopeWithinRadius(Builder $query, float $lat, float $lng, float $radiusKm): Builder
    {
        return $query->selectRaw("
            *, (
                6371 * acos(
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                )
            ) AS distance
        ", [$lat, $lng, $lat])
        ->having('distance', '<=', $radiusKm)
        ->orderBy('distance');
    }

    /**
     * Find nearest locations.
     */
    public function scopeNearest(Builder $query, float $lat, float $lng, int $limit = 10): Builder
    {
        return $query->selectRaw("
            *, (
                6371 * acos(
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                )
            ) AS distance
        ", [$lat, $lng, $lat])
        ->orderBy('distance')
        ->limit($limit);
    }

    /**
     * Get distance to another location.
     */
    public function distanceTo(Location $other): float
    {
        return app(GeocodingService::class)->calculateDistance(
            $this->latitude,
            $this->longitude,
            $other->latitude,
            $other->longitude
        );
    }
}
```

## Migration

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('locations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('address');
            $table->string('formatted_address')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('city')->nullable();
            $table->string('state', 10)->nullable();
            $table->string('postal_code', 20)->nullable();
            $table->string('country', 2)->nullable();
            $table->timestamps();

            // Spatial index for fast proximity queries
            $table->index(['latitude', 'longitude']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('locations');
    }
};
```

## Query Examples

### Find Locations Within Radius

```php
// Find all stores within 50km of user location
$stores = Store::withinRadius(
    latitude: 37.7749,
    longitude: -122.4194,
    radiusKm: 50
)->get();

foreach ($stores as $store) {
    echo "{$store->name} - {$store->distance} km away\n";
}
```

### Find Nearest Locations

```php
// Find 5 nearest coffee shops
$shops = CoffeeShop::nearest(37.7749, -122.4194, 5)->get();

foreach ($shops as $shop) {
    echo "{$shop->name} - {$shop->distance} km away\n";
}
```

### Distance Between Models

```php
$office = Location::find(1);
$warehouse = Location::find(2);

$distance = $office->distanceTo($warehouse);
echo "Distance: {$distance} km\n";
```

### Combined Filters

```php
// Find open stores within 20km, sorted by distance
$stores = Store::withinRadius(37.7749, -122.4194, 20)
    ->where('is_open', true)
    ->where('hours_start', '<=', now())
    ->where('hours_end', '>=', now())
    ->orderBy('distance')
    ->get();
```

### Address-Based Search

```php
$geocoder = app(GeocodingService::class);

// User provides address
$address = "Times Square, New York";
$coords = $geocoder->geocode($address);

if ($coords) {
    $nearbyLocations = Location::withinRadius(
        $coords['lat'],
        $coords['lng'],
        25
    )->get();
}
```

## Performance Considerations

- **Index Strategy:** The composite index on `[latitude, longitude]` helps database optimize radius searches
- **Batch Geocoding:** Batch address geocoding to avoid rate limits
- **Caching:** Cache geocoding results to reduce API calls
- **Pagination:** Use pagination for large result sets

```php
// Cached geocoding
$coords = Cache::remember(
    "geocode:{$address}",
    now()->addDay(),
    fn () => $geocoder->geocode($address)
);

// Paginated radius search
$stores = Store::withinRadius($lat, $lng, 50)
    ->paginate(20);
```
