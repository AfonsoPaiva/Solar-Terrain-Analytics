package com.solarterrain.analytics_backend.solar;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.solarterrain.analytics_backend.geo.LatLng;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class GoogleSolarClient {

    @Value("${google.api.key:}")
    private String googleApiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String SOLAR_API_BASE_URL = "https://solar.googleapis.com/v1";

    /**
     * Get solar data for a specific location using Google Solar API
     */
    public GoogleSolarResult getSolarData(double latitude, double longitude) {
        try {
            String url = String.format(Locale.US,
                    "%s/buildingInsights:findClosest?location.latitude=%.6f&location.longitude=%.6f&key=%s",
                    SOLAR_API_BASE_URL, latitude, longitude, googleApiKey);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<String> entity = new HttpEntity<>(headers);

            return restTemplate.exchange(url, HttpMethod.GET, entity, GoogleSolarResult.class).getBody();
        } catch (Exception e) {
            System.err.println("Error fetching Google Solar data: " + e.getMessage());
            return null;
        }
    }

    /**
     * Get solar insights for a region (polygon area)
     */
    public List<GoogleSolarDataPoint> getSolarDataForRegion(List<Map<String, Double>> polygon) {
        // For now, we'll sample key points in the polygon and get solar data for each
        // In the future, Google may provide direct polygon analysis

        // Sample points across the polygon using a grid approach
        var bounds = calculateBounds(polygon);
        var gridPoints = generateGridPoints(bounds, 5); // 5x5 grid for sampling

        return gridPoints.stream()
                .map(point -> {
                    var solarData = getSolarData(point.lat(), point.lng());
                    return new GoogleSolarDataPoint(
                            point.lat(),
                            point.lng(),
                            solarData != null ? solarData.getSolarPotential() : null,
                            solarData != null ? solarData.getYearlyEnergyDcKwh() : null,
                            solarData != null ? solarData.getSunshineQuantiles() : null);
                })
                .toList();
    }

    private Bounds calculateBounds(List<Map<String, Double>> polygon) {
        double minLat = polygon.stream().mapToDouble(p -> p.get("lat")).min().orElse(0);
        double maxLat = polygon.stream().mapToDouble(p -> p.get("lat")).max().orElse(0);
        double minLng = polygon.stream().mapToDouble(p -> p.get("lng")).min().orElse(0);
        double maxLng = polygon.stream().mapToDouble(p -> p.get("lng")).max().orElse(0);

        return new Bounds(minLat, maxLat, minLng, maxLng);
    }

    private List<LatLng> generateGridPoints(Bounds bounds, int gridSize) {
        var points = new java.util.ArrayList<LatLng>();

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

    private static record Bounds(double minLat, double maxLat, double minLng, double maxLng) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GoogleSolarResult {
        @JsonProperty("solarPotential")
        private SolarPotential solarPotential;

        @JsonProperty("imageryDate")
        private ImageryDate imageryDate;

        public SolarPotential getSolarPotential() {
            return solarPotential;
        }

        public ImageryDate getImageryDate() {
            return imageryDate;
        }

        public Double getYearlyEnergyDcKwh() {
            return solarPotential != null ? solarPotential.getYearlyEnergyDcKwh() : null;
        }

        public List<Double> getSunshineQuantiles() {
            return solarPotential != null ? solarPotential.getSunshineQuantiles() : null;
        }

        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class SolarPotential {
            @JsonProperty("yearlyEnergyDcKwh")
            private Double yearlyEnergyDcKwh;

            @JsonProperty("sunshineQuantiles")
            private List<Double> sunshineQuantiles;

            @JsonProperty("carbonOffsetFactorKgPerMwh")
            private Double carbonOffsetFactorKgPerMwh;

            @JsonProperty("wholeRoofStats")
            private RoofStats wholeRoofStats;

            public Double getYearlyEnergyDcKwh() {
                return yearlyEnergyDcKwh;
            }

            public List<Double> getSunshineQuantiles() {
                return sunshineQuantiles;
            }

            public Double getCarbonOffsetFactorKgPerMwh() {
                return carbonOffsetFactorKgPerMwh;
            }

            public RoofStats getWholeRoofStats() {
                return wholeRoofStats;
            }
        }

        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class RoofStats {
            @JsonProperty("areaMeters2")
            private Double areaMeters2;

            @JsonProperty("sunshineQuantiles")
            private List<Double> sunshineQuantiles;

            @JsonProperty("groundAreaMeters2")
            private Double groundAreaMeters2;

            public Double getAreaMeters2() {
                return areaMeters2;
            }

            public List<Double> getSunshineQuantiles() {
                return sunshineQuantiles;
            }

            public Double getGroundAreaMeters2() {
                return groundAreaMeters2;
            }
        }

        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class ImageryDate {
            @JsonProperty("year")
            private Integer year;

            @JsonProperty("month")
            private Integer month;

            @JsonProperty("day")
            private Integer day;

            public Integer getYear() {
                return year;
            }

            public Integer getMonth() {
                return month;
            }

            public Integer getDay() {
                return day;
            }
        }
    }

    public static class GoogleSolarDataPoint {
        private final double latitude;
        private final double longitude;
        private final GoogleSolarResult.SolarPotential solarPotential;
        private final Double yearlyEnergyDcKwh;
        private final List<Double> sunshineQuantiles;

        public GoogleSolarDataPoint(double latitude, double longitude,
                GoogleSolarResult.SolarPotential solarPotential,
                Double yearlyEnergyDcKwh, List<Double> sunshineQuantiles) {
            this.latitude = latitude;
            this.longitude = longitude;
            this.solarPotential = solarPotential;
            this.yearlyEnergyDcKwh = yearlyEnergyDcKwh;
            this.sunshineQuantiles = sunshineQuantiles;
        }

        // Getters
        public double getLatitude() {
            return latitude;
        }

        public double getLongitude() {
            return longitude;
        }

        public GoogleSolarResult.SolarPotential getSolarPotential() {
            return solarPotential;
        }

        public Double getYearlyEnergyDcKwh() {
            return yearlyEnergyDcKwh;
        }

        public List<Double> getSunshineQuantiles() {
            return sunshineQuantiles;
        }
    }
}
