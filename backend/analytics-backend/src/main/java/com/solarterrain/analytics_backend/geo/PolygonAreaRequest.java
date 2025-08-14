package com.solarterrain.analytics_backend.geo;

import java.util.List;

/**
 * Request payload containing a polygon (list of coordinates) for which to
 * estimate solar potential.
 */
public record PolygonAreaRequest(
        List<LatLng> points,
        Integer year,
        Double panelEfficiency, // module efficiency (0-1)
        Double performanceRatio, // system losses combined (0-1)
        Double dcPowerPerM2 // kWp per m2 of usable area (derived from efficiency)
) {
}
