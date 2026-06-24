# Geocoding Service

## Core Service Implementation

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

## Service Provider Registration

Register in `config/app.php` providers:

```php
App\Providers\GeocodingServiceProvider::class,
```

Create the provider:

```php
<?php

declare(strict_types=1);

namespace App\Providers;

use App\Services\GeocodingService;
use Illuminate\Support\ServiceProvider;
use Spatie\Geocoder\Geocoder;

final class GeocodingServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(GeocodingService::class, function ($app) {
            $geocoder = new Geocoder(
                apiKey: config('geocoder.key'),
                language: config('geocoder.language', 'en'),
                region: config('geocoder.region', 'us'),
            );

            return new GeocodingService($geocoder);
        });
    }
}
```

## Config File

Create `config/geocoder.php`:

```php
<?php

return [
    'key' => env('GOOGLE_MAPS_GEOCODING_API_KEY'),
    'language' => env('GEOCODER_LANGUAGE', 'en'),
    'region' => env('GEOCODER_REGION', 'us'),
];
```

## Usage Examples

```php
use App\Services\GeocodingService;

$geocoder = app(GeocodingService::class);

// Geocode address to coordinates
$result = $geocoder->geocode('123 Main St, San Francisco, CA');
// ['lat' => 37.7749, 'lng' => -122.4194, 'accuracy' => 'ROOFTOP', 'formatted_address' => '123 Main Street...']

// Reverse geocode
$address = $geocoder->reverseGeocode(37.7749, -122.4194);
// ['address' => '...', 'city' => 'San Francisco', 'state' => 'CA', ...]

// Distance calculation
$distance = $geocoder->calculateDistance(
    37.7749, -122.4194,  // San Francisco
    37.3382, -121.8863   // San Jose
);
// 49.23 km
```
