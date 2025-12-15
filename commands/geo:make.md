---
description: "Create geolocation feature using spatie/geocoder"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /geo:make - Create Geolocation Feature

Generate location-based features using spatie/geocoder for Google Maps geocoding.

## Input
$ARGUMENTS = `<FeatureName>`

Examples:
- `/geo:make StoreLocator`
- `/geo:make DeliveryZones`
- `/geo:make AddressAutocomplete`
- `/geo:make NearbySearch`

## Process

1. **Install Package**
   ```bash
   composer require spatie/geocoder
   ```

2. **Publish Config**
   ```bash
   php artisan vendor:publish --provider="Spatie\Geocoder\GeocoderServiceProvider" --tag="config"
   ```

3. **Create Feature Structure**
   ```
   app/
   ├── Services/
   │   └── GeocodingService.php
   ├── Http/
   │   └── Controllers/
   │       └── <Feature>Controller.php
   └── Models/
       └── Location.php (or Address.php)
   ```

4. **Add Environment Variables**
   ```env
   GOOGLE_MAPS_GEOCODING_API_KEY=your-api-key
   ```

5. **Create Migration** (if storing locations)

## Templates

### Geocoding Service
```php
<?php

declare(strict_types=1);

namespace App\Services;

use Spatie\Geocoder\Geocoder;

final class GeocodingService
{
    public function __construct(
        private readonly Geocoder $geocoder,
    ) {}

    /**
     * Get coordinates from address.
     *
     * @return array{lat: float, lng: float, accuracy: string, formatted_address: string}|null
     */
    public function geocode(string $address): ?array
    {
        $result = $this->geocoder->getCoordinatesForAddress($address);

        if ($result['lat'] === 0 && $result['lng'] === 0) {
            return null;
        }

        return $result;
    }

    /**
     * Get address from coordinates.
     *
     * @return array{address: string, street_number: string, route: string, city: string, state: string, country: string, postal_code: string}|null
     */
    public function reverseGeocode(float $lat, float $lng): ?array
    {
        $results = $this->geocoder->getAddressForCoordinates($lat, $lng);

        if (empty($results)) {
            return null;
        }

        return $this->parseAddressComponents($results);
    }

    /**
     * Get multiple results for ambiguous address.
     */
    public function geocodeMultiple(string $address): array
    {
        return $this->geocoder->getAllCoordinatesForAddress($address);
    }

    /**
     * Calculate distance between two points in kilometers.
     */
    public function calculateDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371; // km

        $latDiff = deg2rad($lat2 - $lat1);
        $lngDiff = deg2rad($lng2 - $lng1);

        $a = sin($latDiff / 2) * sin($latDiff / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($lngDiff / 2) * sin($lngDiff / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    private function parseAddressComponents(array $results): array
    {
        $components = $results['address_components'] ?? [];

        $parsed = [
            'address' => $results['formatted_address'] ?? '',
            'street_number' => '',
            'route' => '',
            'city' => '',
            'state' => '',
            'country' => '',
            'postal_code' => '',
        ];

        foreach ($components as $component) {
            $types = $component['types'] ?? [];

            if (in_array('street_number', $types)) {
                $parsed['street_number'] = $component['long_name'];
            }
            if (in_array('route', $types)) {
                $parsed['route'] = $component['long_name'];
            }
            if (in_array('locality', $types)) {
                $parsed['city'] = $component['long_name'];
            }
            if (in_array('administrative_area_level_1', $types)) {
                $parsed['state'] = $component['short_name'];
            }
            if (in_array('country', $types)) {
                $parsed['country'] = $component['short_name'];
            }
            if (in_array('postal_code', $types)) {
                $parsed['postal_code'] = $component['long_name'];
            }
        }

        return $parsed;
    }
}
```

### Location Model
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
     */
    public function scopeWithinRadius(Builder $query, float $lat, float $lng, float $radiusKm): Builder
    {
        // Haversine formula
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
     * Find nearest location.
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

### Store Locator Controller
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Store;
use App\Services\GeocodingService;
use Illuminate\Http\Request;

final class StoreLocatorController extends Controller
{
    public function __construct(
        private readonly GeocodingService $geocoder,
    ) {}

    public function index(Request $request)
    {
        $stores = Store::query()
            ->when($request->filled(['lat', 'lng']), function ($query) use ($request) {
                $query->withinRadius(
                    $request->float('lat'),
                    $request->float('lng'),
                    $request->float('radius', 50) // Default 50km
                );
            })
            ->when($request->filled('address'), function ($query) use ($request) {
                $coords = $this->geocoder->geocode($request->input('address'));
                if ($coords) {
                    $query->withinRadius($coords['lat'], $coords['lng'], 50);
                }
            })
            ->paginate(20);

        return view('stores.locator', compact('stores'));
    }

    public function nearest(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $stores = Store::nearest(
            $request->float('lat'),
            $request->float('lng'),
            5
        )->get();

        return response()->json([
            'data' => $stores->map(fn ($store) => [
                'id' => $store->id,
                'name' => $store->name,
                'address' => $store->formatted_address,
                'distance_km' => round($store->distance, 2),
                'lat' => $store->latitude,
                'lng' => $store->longitude,
            ]),
        ]);
    }
}
```

### Migration
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

## Config
```php
// config/geocoder.php
return [
    'key' => env('GOOGLE_MAPS_GEOCODING_API_KEY'),
    'language' => 'en',
    'region' => 'us',
];
```

## Output

```markdown
## Geolocation Feature: <Name>

### Package Installed
- spatie/geocoder

### Environment Variables
```env
GOOGLE_MAPS_GEOCODING_API_KEY=your-api-key
```

### Files Created
- app/Services/GeocodingService.php
- app/Models/Location.php (or modified existing)
- app/Http/Controllers/<Name>Controller.php
- database/migrations/xxxx_create_locations_table.php
- config/geocoder.php

### Available Methods
```php
// Geocode address
$coords = $geocoder->geocode('123 Main St, City, Country');
// Returns: ['lat' => 40.7128, 'lng' => -74.0060, ...]

// Reverse geocode
$address = $geocoder->reverseGeocode(40.7128, -74.0060);

// Find nearby
$stores = Store::withinRadius($lat, $lng, 10)->get(); // 10km radius

// Find nearest
$stores = Store::nearest($lat, $lng, 5)->get(); // 5 closest
```

### Next Steps
1. Get Google Maps API key from https://console.cloud.google.com
2. Enable Geocoding API in Google Cloud Console
3. Add GOOGLE_MAPS_GEOCODING_API_KEY to .env
4. Run `php artisan migrate`
```
