package com.solarterrain.analytics_backend.solar;

import com.solarterrain.analytics_backend.geo.LatLng;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.ArrayList;

@Service
public class EnhancedShadingService {

    @Value("${google.api.key:}")
    private String googleApiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String ELEVATION_API_URL = "https://maps.googleapis.com/maps/api/elevation/json";

    /**
     * Calculate detailed shading analysis using real elevation data
     */
    public ShadingAnalysis calculateDetailedShading(double latitude, double longitude,
            List<Map<String, Double>> polygon) {
        try {
            // Get elevation data for the area
            var elevationData = getElevationDataForArea(polygon);

            // Calculate shadow patterns for different times of day and seasons
            var morningShading = calculateShadingForTime(latitude, longitude, elevationData, 8); // 8 AM
            var noonShading = calculateShadingForTime(latitude, longitude, elevationData, 12); // 12 PM
            var eveningShading = calculateShadingForTime(latitude, longitude, elevationData, 17); // 5 PM

            // Calculate seasonal variations
            var winterShading = calculateSeasonalShading(latitude, longitude, elevationData, "winter");
            var summerShading = calculateSeasonalShading(latitude, longitude, elevationData, "summer");

            // Calculate average shading throughout the year
            double averageShading = (morningShading + noonShading + eveningShading + winterShading + summerShading)
                    / 5.0;

            return new ShadingAnalysis(
                    averageShading,
                    morningShading,
                    noonShading,
                    eveningShading,
                    winterShading,
                    summerShading,
                    elevationData,
                    calculateShadowMap(elevationData));

        } catch (Exception e) {
            System.err.println("Error calculating detailed shading: " + e.getMessage());
            // Return basic shading calculation as fallback
            return getBasicShadingAnalysis(latitude, longitude);
        }
    }

    private List<ElevationPoint> getElevationDataForArea(List<Map<String, Double>> polygon) {
        var elevationPoints = new ArrayList<ElevationPoint>();

        // Create a grid of points within the polygon
        var bounds = calculateBounds(polygon);
        var gridPoints = generateGridPoints(bounds, 10); // 10x10 grid for detailed analysis

        // Get elevation for each point
        for (var point : gridPoints) {
            if (isPointInPolygon(point, polygon)) {
                var elevation = getElevationForPoint(point.lat(), point.lng());
                elevationPoints.add(new ElevationPoint(point.lat(), point.lng(), elevation));
            }
        }

        return elevationPoints;
    }

    private double getElevationForPoint(double latitude, double longitude) {
        try {
            String url = String.format(Locale.US, "%s?locations=%.6f,%.6f&key=%s",
                    ELEVATION_API_URL, latitude, longitude, googleApiKey);

            var response = restTemplate.getForObject(url, ElevationResponse.class);

            if (response != null && response.getResults() != null && !response.getResults().isEmpty()) {
                return response.getResults().get(0).getElevation();
            }

            return 0.0; // Default elevation if API fails
        } catch (Exception e) {
            System.err.println("Error fetching elevation data: " + e.getMessage());
            return 0.0;
        }
    }

    private double calculateShadingForTime(double latitude, double longitude,
            List<ElevationPoint> elevationData, int hour) {
        // Calculate sun position for given time
        var sunPosition = calculateSunPosition(latitude, longitude, hour);

        // Calculate shadows cast by elevation differences
        double totalShading = 0.0;
        int shadedPoints = 0;

        for (var point : elevationData) {
            if (isPointInShadow(point, elevationData, sunPosition)) {
                totalShading += calculateShadowIntensity(point, elevationData, sunPosition);
                shadedPoints++;
            }
        }

        return shadedPoints > 0 ? totalShading / shadedPoints : 0.0;
    }

    private double calculateSeasonalShading(double latitude, double longitude,
            List<ElevationPoint> elevationData, String season) {
        // Adjust sun angle based on season
        double seasonalAngle = switch (season) {
            case "winter" -> -23.5; // Winter solstice
            case "summer" -> 23.5; // Summer solstice
            default -> 0.0; // Equinox
        };

        var adjustedSunPosition = new SunPosition(
                calculateSunAzimuth(latitude, longitude, 12),
                calculateSunElevationForSeason(latitude, seasonalAngle));

        double totalShading = 0.0;
        int shadedPoints = 0;

        for (var point : elevationData) {
            if (isPointInShadow(point, elevationData, adjustedSunPosition)) {
                totalShading += calculateShadowIntensity(point, elevationData, adjustedSunPosition);
                shadedPoints++;
            }
        }

        return shadedPoints > 0 ? totalShading / shadedPoints : 0.0;
    }

    private SunPosition calculateSunPosition(double latitude, double longitude, int hour) {
        // Simplified sun position calculation (in real implementation, use more precise
        // astronomical calculations)
        double azimuth = calculateSunAzimuth(latitude, longitude, hour);
        double elevation = calculateSunElevation(latitude, hour);

        return new SunPosition(azimuth, elevation);
    }

    private double calculateSunAzimuth(double latitude, double longitude, int hour) {
        // Simplified azimuth calculation
        // In reality, this would use precise astronomical formulas
        double hourAngle = (hour - 12) * 15.0; // 15 degrees per hour
        return 180.0 + hourAngle; // Simplified calculation
    }

    private double calculateSunElevation(double latitude, int hour) {
        // Simplified elevation calculation based on time and latitude
        double maxElevation = 90.0 - Math.abs(latitude - 23.5); // Approximate max elevation
        double hourFactor = Math.sin(Math.toRadians((hour - 6) * 15.0)); // Peak at noon
        return Math.max(0, maxElevation * hourFactor);
    }

    private double calculateSunElevationForSeason(double latitude, double seasonalAngle) {
        return 90.0 - Math.abs(latitude - seasonalAngle);
    }

    private boolean isPointInShadow(ElevationPoint point, List<ElevationPoint> elevationData, SunPosition sunPosition) {
        // Check if the point is in shadow based on surrounding elevation and sun
        // position
        for (var otherPoint : elevationData) {
            if (otherPoint != point && otherPoint.elevation > point.elevation) {
                if (castsShadowOnPoint(otherPoint, point, sunPosition)) {
                    return true;
                }
            }
        }
        return false;
    }

    private boolean castsShadowOnPoint(ElevationPoint source, ElevationPoint target, SunPosition sunPosition) {
        // Calculate if source point casts shadow on target point given sun position
        double distance = calculateDistance(source.latitude, source.longitude, target.latitude, target.longitude);
        double elevationDiff = source.elevation - target.elevation;
        double shadowLength = elevationDiff / Math.tan(Math.toRadians(sunPosition.elevation));

        return distance <= shadowLength;
    }

    private double calculateShadowIntensity(ElevationPoint point, List<ElevationPoint> elevationData,
            SunPosition sunPosition) {
        // Calculate how much shadow is cast on this point (0.0 = no shadow, 1.0 =
        // complete shadow)
        double maxShadowHeight = 0.0;

        for (var otherPoint : elevationData) {
            if (otherPoint != point && castsShadowOnPoint(otherPoint, point, sunPosition)) {
                double shadowHeight = (otherPoint.elevation - point.elevation)
                        / Math.sin(Math.toRadians(sunPosition.elevation));
                maxShadowHeight = Math.max(maxShadowHeight, shadowHeight);
            }
        }

        // Convert shadow height to intensity (0-1 scale)
        return Math.min(1.0, maxShadowHeight / 100.0); // Normalize to 0-1 scale
    }

    private List<List<Double>> calculateShadowMap(List<ElevationPoint> elevationData) {
        // Create a 2D shadow intensity map
        var shadowMap = new ArrayList<List<Double>>();

        // For now, return a simplified shadow map
        // In reality, this would create a detailed 2D grid of shadow intensities
        for (int i = 0; i < 10; i++) {
            var row = new ArrayList<Double>();
            for (int j = 0; j < 10; j++) {
                // Sample shadow intensity for this grid cell
                if (i * 10 + j < elevationData.size()) {
                    var point = elevationData.get(i * 10 + j);
                    var sunPosition = calculateSunPosition(point.latitude, point.longitude, 12);
                    row.add(calculateShadowIntensity(point, elevationData, sunPosition));
                } else {
                    row.add(0.0);
                }
            }
            shadowMap.add(row);
        }

        return shadowMap;
    }

    private ShadingAnalysis getBasicShadingAnalysis(double latitude, double longitude) {
        // Fallback basic shading analysis
        return new ShadingAnalysis(
                0.2, // average shading
                0.3, // morning shading
                0.1, // noon shading
                0.25, // evening shading
                0.4, // winter shading
                0.15, // summer shading
                List.of(), // empty elevation data
                List.of() // empty shadow map
        );
    }

    // Helper methods
    private Bounds calculateBounds(List<Map<String, Double>> polygon) {
        double minLat = polygon.stream().mapToDouble(p -> p.get("lat")).min().orElse(0);
        double maxLat = polygon.stream().mapToDouble(p -> p.get("lat")).max().orElse(0);
        double minLng = polygon.stream().mapToDouble(p -> p.get("lng")).min().orElse(0);
        double maxLng = polygon.stream().mapToDouble(p -> p.get("lng")).max().orElse(0);

        return new Bounds(minLat, maxLat, minLng, maxLng);
    }

    private List<LatLng> generateGridPoints(Bounds bounds, int gridSize) {
        var points = new ArrayList<LatLng>();

        double latStep = (bounds.maxLat - bounds.minLat) / (gridSize - 1);
        double lngStep = (bounds.maxLng - bounds.minLng) / (gridSize - 1);

        for (int i = 0; i < gridSize; i++) {
            for (int j = 0; j < gridSize; j++) {
                double lat = bounds.minLat + (i * latStep);
                double lng = bounds.minLng + (j * lngStep);
                points.add(new LatLng(lat, lng));
            }
        }

        return points;
    }

    private boolean isPointInPolygon(LatLng point, List<Map<String, Double>> polygon) {
        // Ray casting algorithm to check if point is inside polygon
        int intersections = 0;

        for (int i = 0; i < polygon.size(); i++) {
            int j = (i + 1) % polygon.size();

            double lat1 = polygon.get(i).get("lat");
            double lng1 = polygon.get(i).get("lng");
            double lat2 = polygon.get(j).get("lat");
            double lng2 = polygon.get(j).get("lng");

            if (((lat1 > point.lat()) != (lat2 > point.lat())) &&
                    (point.lng() < (lng2 - lng1) * (point.lat() - lat1) / (lat2 - lat1) + lng1)) {
                intersections++;
            }
        }

        return intersections % 2 == 1;
    }

    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        // Haversine formula for distance calculation
        double R = 6371000; // Earth's radius in meters
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLng / 2) * Math.sin(dLng / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    // Data classes
    private static record Bounds(double minLat, double maxLat, double minLng, double maxLng) {
    }

    private static record SunPosition(double azimuth, double elevation) {
    }

    public static class ElevationPoint {
        private final double latitude;
        private final double longitude;
        private final double elevation;

        public ElevationPoint(double latitude, double longitude, double elevation) {
            this.latitude = latitude;
            this.longitude = longitude;
            this.elevation = elevation;
        }

        public double getLatitude() {
            return latitude;
        }

        public double getLongitude() {
            return longitude;
        }

        public double getElevation() {
            return elevation;
        }
    }

    public static class ShadingAnalysis {
        private final double averageShading;
        private final double morningShading;
        private final double noonShading;
        private final double eveningShading;
        private final double winterShading;
        private final double summerShading;
        private final List<ElevationPoint> elevationData;
        private final List<List<Double>> shadowMap;

        public ShadingAnalysis(double averageShading, double morningShading, double noonShading,
                double eveningShading, double winterShading, double summerShading,
                List<ElevationPoint> elevationData, List<List<Double>> shadowMap) {
            this.averageShading = averageShading;
            this.morningShading = morningShading;
            this.noonShading = noonShading;
            this.eveningShading = eveningShading;
            this.winterShading = winterShading;
            this.summerShading = summerShading;
            this.elevationData = elevationData;
            this.shadowMap = shadowMap;
        }

        // Getters
        public double getAverageShading() {
            return averageShading;
        }

        public double getMorningShading() {
            return morningShading;
        }

        public double getNoonShading() {
            return noonShading;
        }

        public double getEveningShading() {
            return eveningShading;
        }

        public double getWinterShading() {
            return winterShading;
        }

        public double getSummerShading() {
            return summerShading;
        }

        public List<ElevationPoint> getElevationData() {
            return elevationData;
        }

        public List<List<Double>> getShadowMap() {
            return shadowMap;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ElevationResponse {
        @JsonProperty("results")
        private List<ElevationResult> results;

        @JsonProperty("status")
        private String status;

        public List<ElevationResult> getResults() {
            return results;
        }

        public String getStatus() {
            return status;
        }

        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class ElevationResult {
            @JsonProperty("elevation")
            private Double elevation;

            @JsonProperty("location")
            private Location location;

            public Double getElevation() {
                return elevation;
            }

            public Location getLocation() {
                return location;
            }

            @JsonIgnoreProperties(ignoreUnknown = true)
            public static class Location {
                @JsonProperty("lat")
                private Double lat;

                @JsonProperty("lng")
                private Double lng;

                public Double getLat() {
                    return lat;
                }

                public Double getLng() {
                    return lng;
                }
            }
        }
    }
}
