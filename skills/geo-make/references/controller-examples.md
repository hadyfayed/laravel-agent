# Controller Examples

## Store Locator Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Store;
use App\Services\GeocodingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

final class StoreLocatorController extends Controller
{
    public function __construct(
        private readonly GeocodingService $geocoder,
    ) {}

    /**
     * Display store locator page.
     */
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

    /**
     * Find nearest stores via API.
     */
    public function nearest(Request $request): JsonResponse
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'limit' => 'integer|min:1|max:50',
        ]);

        $stores = Store::nearest(
            $request->float('lat'),
            $request->float('lng'),
            $request->integer('limit', 5)
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

    /**
     * Search by address.
     */
    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'address' => 'required|string|min:3',
            'radius' => 'numeric|min:1|max:100',
        ]);

        $coords = $this->geocoder->geocode($request->input('address'));

        if (!$coords) {
            return response()->json(
                ['error' => 'Address not found'],
                404
            );
        }

        $stores = Store::withinRadius(
            $coords['lat'],
            $coords['lng'],
            $request->float('radius', 50)
        )->get();

        return response()->json([
            'address' => $coords['formatted_address'],
            'data' => $stores->map(fn ($store) => [
                'id' => $store->id,
                'name' => $store->name,
                'distance_km' => round($store->distance, 2),
            ]),
        ]);
    }

    /**
     * Geocode endpoint (internal use).
     */
    public function geocode(Request $request): JsonResponse
    {
        $request->validate(['address' => 'required|string']);

        $result = $this->geocoder->geocode($request->input('address'));

        if (!$result) {
            return response()->json(
                ['error' => 'Could not geocode address'],
                404
            );
        }

        return response()->json($result);
    }
}
```

## Routes

```php
Route::prefix('stores')->group(function () {
    Route::get('/', [StoreLocatorController::class, 'index'])->name('stores.index');
    Route::get('/nearest', [StoreLocatorController::class, 'nearest'])->name('stores.nearest');
    Route::get('/search', [StoreLocatorController::class, 'search'])->name('stores.search');
    Route::get('/geocode', [StoreLocatorController::class, 'geocode'])->name('stores.geocode');
});
```

## Blade Template

```blade
<!-- resources/views/stores/locator.blade.php -->
<div class="store-locator">
    <form id="search-form" class="mb-6">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <input
                type="text"
                id="address"
                name="address"
                placeholder="Enter address or zip code"
                class="px-4 py-2 border rounded"
            />

            <select name="radius" class="px-4 py-2 border rounded">
                <option value="10">Within 10 km</option>
                <option value="25">Within 25 km</option>
                <option value="50" selected>Within 50 km</option>
                <option value="100">Within 100 km</option>
            </select>

            <button type="submit" class="px-6 py-2 bg-blue-600 text-white rounded">
                Find Stores
            </button>
        </div>
    </form>

    <div id="stores-list" class="grid grid-cols-1 md:grid-cols-2 gap-4">
        @forelse($stores as $store)
            <div class="p-4 border rounded shadow">
                <h3 class="font-bold text-lg">{{ $store->name }}</h3>
                <p class="text-gray-600">{{ $store->formatted_address }}</p>
                @if($store->distance)
                    <p class="text-sm text-blue-600 mt-2">
                        <strong>{{ round($store->distance, 1) }} km away</strong>
                    </p>
                @endif
                <a href="tel:{{ $store->phone }}" class="text-blue-600">
                    {{ $store->phone }}
                </a>
            </div>
        @empty
            <div class="col-span-2 p-4 text-center text-gray-500">
                No stores found. Try adjusting your search.
            </div>
        @endforelse
    </div>
</div>

<script>
document.getElementById('search-form').addEventListener('submit', async (e) => {
    e.preventDefault();

    const address = document.getElementById('address').value;
    const radius = document.querySelector('select[name="radius"]').value;

    const response = await fetch(`/stores/search?address=${encodeURIComponent(address)}&radius=${radius}`);
    const data = await response.json();

    if (data.error) {
        alert(data.error);
        return;
    }

    // Update list with results
    console.log(data);
});
</script>
```

## Delivery Zone Controller

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\DeliveryZone;
use App\Services\GeocodingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class DeliveryZoneController extends Controller
{
    public function __construct(
        private readonly GeocodingService $geocoder,
    ) {}

    /**
     * Check if address is in delivery zone.
     */
    public function check(Request $request): JsonResponse
    {
        $request->validate(['address' => 'required|string']);

        $coords = $this->geocoder->geocode($request->input('address'));

        if (!$coords) {
            return response()->json(['deliverable' => false]);
        }

        $zone = DeliveryZone::withinRadius(
            $coords['lat'],
            $coords['lng'],
            0.01 // Check if within any zone
        )->first();

        return response()->json([
            'deliverable' => $zone !== null,
            'zone' => $zone?->name,
            'coordinates' => [
                'lat' => $coords['lat'],
                'lng' => $coords['lng'],
            ],
        ]);
    }
}
```
