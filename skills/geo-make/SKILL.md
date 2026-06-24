---
name: geo-make
description: Scaffold geolocation features with distance queries, geocoding, spatial indexes; when adding location-based functionality.
disable-model-invocation: true
allowed-tools: Bash(php artisan make:*) Bash(composer require) Read Write Edit
argument-hint: "<FeatureName>"
---

## Task

Generate geolocation/geospatial features using spatie/geocoder and Haversine distance calculations for location-based queries.

## Input

- **FeatureName:** Feature name (e.g., `StoreLocator`, `DeliveryZones`, `NearbySearch`)

## Steps

1. **Install spatie/geocoder** if not present:
   ```bash
   composer require spatie/geocoder
   ```

2. **Publish config:**
   ```bash
   php artisan vendor:publish --provider="Spatie\Geocoder\GeocoderServiceProvider" --tag="config"
   ```

3. **Create core service** in `app/Services/GeocodingService.php`:
   - `geocode($address)` — Convert address to coordinates
   - `reverseGeocode($lat, $lng)` — Convert coordinates to address
   - `calculateDistance($lat1, $lng1, $lat2, $lng2)` — Haversine formula
   - `parseAddressComponents()` — Extract fields from API response

4. **Create Location model** with spatial scope methods:
   - `withinRadius($lat, $lng, $radiusKm)` — Distance query using Haversine
   - `nearest($lat, $lng, $limit)` — Find N closest locations
   - `distanceTo($otherLocation)` — Distance between two models

5. **Create migration** for locations table:
   - `latitude`, `longitude` decimal columns (10,8 precision)
   - Index on `[latitude, longitude]` for fast proximity queries
   - Store `formatted_address` and address components

6. **Environment setup:**
   - Add `GOOGLE_MAPS_GEOCODING_API_KEY` to `.env`
   - Optionally configure language/region in config

7. **Create controller** for location endpoints (optional):
   - Index with radius search
   - Nearest with coordinates
   - Geocode address input into coordinates

## Reference

For comprehensive patterns and example implementations:
- `${CLAUDE_SKILL_DIR}/references/geocoding-service.md` — Service methods and API integration
- `${CLAUDE_SKILL_DIR}/references/distance-queries.md` — Haversine formula and spatial scopes
- `${CLAUDE_SKILL_DIR}/references/controller-examples.md` — Route handlers and endpoints

## Security guardrails

- Never log or cache raw address input containing sensitive location data
- Validate and sanitize address components before storing
- Rate-limit geocoding API calls (Google charges per request)
- Use fallback coordinates for failed geocodes
- Validate latitude/longitude bounds (-90 to 90, -180 to 180)
- Consider privacy: allow anonymous location searches without authentication if needed
