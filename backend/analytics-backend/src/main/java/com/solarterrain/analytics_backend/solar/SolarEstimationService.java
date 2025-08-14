package com.solarterrain.analytics_backend.solar;

import com.solarterrain.analytics_backend.geo.LatLng;
import net.sf.geographiclib.Geodesic;
import net.sf.geographiclib.PolygonArea;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;

@Service
public class SolarEstimationService {

    @Autowired
    private GoogleSolarClient googleSolarClient;

    @Autowired
    private GoogleWeatherClient googleWeatherClient;

    @Autowired
    private EnhancedShadingService enhancedShadingService;

    @Value("${solar.default.panel-efficiency:0.20}")
    double defaultPanelEfficiency; // module efficiency
    @Value("${solar.default.performance-ratio:0.75}")
    double defaultPerformanceRatio; // after losses
    @Value("${solar.default.usable-fraction:0.7}")
    double defaultUsableFraction;

    public SolarEstimationService() {
    }

    public SolarEstimate estimate(List<LatLng> points) {
        if (points == null || points.size() < 3)
            throw new IllegalArgumentException("Polygon requires >=3 points");

        // Accurate geodesic area (GeographicLib returns signed area meters^2).
        PolygonArea poly = new PolygonArea(Geodesic.WGS84, false);
        for (LatLng p : points)
            poly.AddPoint(p.lat(), p.lng());
        var r = poly.Compute();
        double areaM2 = Math.abs(r.area);

        double usableArea = areaM2 * defaultUsableFraction; // can refine (roof tilt/spacing)

        double centroidLat = points.stream().mapToDouble(LatLng::lat).average().orElse(0);
        double centroidLon = points.stream().mapToDouble(LatLng::lng).average().orElse(0);

        // Portugal (continental) rough bounding box validation
        if (centroidLat < 36.8 || centroidLat > 42.3 || centroidLon < -9.6 || centroidLon > -6.0) {
            throw new IllegalArgumentException("Area centroid outside Portugal supported bounds");
        }

        // **NEW: Get enhanced data from multiple sources**

        // 1. Get Google Solar data for comparison
        var googleSolarData = googleSolarClient.getSolarDataForRegion(
                points.stream().map(p -> Map.of("lat", p.lat(), "lng", p.lng())).toList());

        // 2. Get weather data for meteorological effects
        var monthlyWeatherData = googleWeatherClient.getMonthlyWeatherPatterns(centroidLat, centroidLon);

        // 3. Get enhanced shading analysis
        var shadingAnalysis = enhancedShadingService.calculateDetailedShading(
                centroidLat, centroidLon,
                points.stream().map(p -> Map.of("lat", p.lat(), "lng", p.lng())).toList());

        // **Calculate enhanced solar potential**
        double enhancedKwpPerM2 = calculateEnhancedKwpPerM2(googleSolarData, monthlyWeatherData);
        double systemKWp = usableArea * enhancedKwpPerM2;

        // **Calculate weather-adjusted production**
        double averageWeatherFactor = monthlyWeatherData.stream()
                .mapToDouble(wd -> wd.getSolarEfficiencyFactor())
                .average()
                .orElse(0.8);

        // **Calculate shading-adjusted production**
        double shadingFactor = 1.0 - shadingAnalysis.getAverageShading();

        // **Enhanced heatmap generation**
        var enhancedHeatmap = generateEnhancedHeatmap(points, googleSolarData, shadingAnalysis, monthlyWeatherData);

        // **Final production calculations with all factors**
        double baseAnnualKwh = systemKWp * getPortugalAverageGhi() * defaultPerformanceRatio;
        double weatherAdjustedKwh = baseAnnualKwh * averageWeatherFactor;
        double finalAnnualKwh = weatherAdjustedKwh * shadingFactor;

        return new SolarEstimate(
                areaM2,
                usableArea,
                systemKWp,
                finalAnnualKwh,
                enhancedHeatmap,
                createEnhancedAnalysisData(googleSolarData, monthlyWeatherData, shadingAnalysis, averageWeatherFactor,
                        shadingFactor));
    }

    private double calculateEnhancedKwpPerM2(List<GoogleSolarClient.GoogleSolarDataPoint> googleData,
            List<GoogleWeatherClient.MonthlyWeatherData> weatherData) {
        if (googleData != null && !googleData.isEmpty()) {
            // Use Google Solar data if available
            double avgGoogleSolar = googleData.stream()
                    .filter(d -> d.getYearlyEnergyDcKwh() != null)
                    .mapToDouble(d -> d.getYearlyEnergyDcKwh())
                    .average()
                    .orElse(0.0);

            if (avgGoogleSolar > 0) {
                // Convert Google's kWh/year to kWp/m2 equivalent
                return Math.min(avgGoogleSolar / (getPortugalAverageGhi() * 365 * 24), 0.25); // Cap at 25% efficiency
            }
        }

        // Fallback to enhanced calculation based on weather data
        double weatherEfficiency = weatherData.stream()
                .mapToDouble(wd -> wd.getSolarEfficiencyFactor())
                .average()
                .orElse(0.8);

        return defaultPanelEfficiency * weatherEfficiency;
    }

    private List<Map<String, Object>> generateEnhancedHeatmap(List<LatLng> points,
            List<GoogleSolarClient.GoogleSolarDataPoint> googleData,
            EnhancedShadingService.ShadingAnalysis shadingAnalysis,
            List<GoogleWeatherClient.MonthlyWeatherData> weatherData) {

        var heatmapData = new ArrayList<Map<String, Object>>();
        var bounds = calculateBounds(points);
        int gridSize = 20; // 20x20 grid for detailed heatmap

        double latStep = (bounds.maxLat() - bounds.minLat()) / (gridSize - 1);
        double lngStep = (bounds.maxLng() - bounds.minLng()) / (gridSize - 1);

        // Average weather efficiency factor
        double avgWeatherFactor = weatherData.stream()
                .mapToDouble(wd -> wd.getSolarEfficiencyFactor())
                .average()
                .orElse(0.8);

        for (int i = 0; i < gridSize; i++) {
            for (int j = 0; j < gridSize; j++) {
                double lat = bounds.minLat() + (i * latStep);
                double lng = bounds.minLng() + (j * lngStep);

                if (isPointInPolygon(lat, lng, points)) {
                    // Base solar intensity calculation
                    double baseSolarIntensity = calculateBaseSolarIntensity(lat, lng);

                    // Apply Google Solar data if available
                    double googleSolarFactor = getGoogleSolarFactor(lat, lng, googleData);
                    double enhancedIntensity = baseSolarIntensity * googleSolarFactor;

                    // Apply weather effects
                    double weatherAdjustedIntensity = enhancedIntensity * avgWeatherFactor;

                    // Apply shading effects
                    double shadingFactor = getShadingFactorForPoint(lat, lng, shadingAnalysis);
                    double finalIntensity = weatherAdjustedIntensity * (1.0 - shadingFactor);

                    // Create enhanced color based on multiple factors
                    String color = calculateEnhancedColor(finalIntensity, shadingFactor, avgWeatherFactor);

                    var point = new HashMap<String, Object>();
                    point.put("lat", lat);
                    point.put("lng", lng);
                    point.put("intensity", finalIntensity);
                    point.put("baseIntensity", baseSolarIntensity);
                    point.put("googleSolarFactor", googleSolarFactor);
                    point.put("weatherFactor", avgWeatherFactor);
                    point.put("shadowFactor", shadingFactor);
                    point.put("color", color);
                    point.put("monthlyProduction", calculateMonthlyProduction(finalIntensity, weatherData));

                    heatmapData.add(point);
                }
            }
        }

        return heatmapData;
    }

    private double getGoogleSolarFactor(double lat, double lng,
            List<GoogleSolarClient.GoogleSolarDataPoint> googleData) {
        if (googleData == null || googleData.isEmpty()) {
            return 1.0; // No adjustment if no Google data
        }

        // Find nearest Google Solar data point
        return googleData.stream()
                .min((a, b) -> Double.compare(
                        calculateDistance(lat, lng, a.getLatitude(), a.getLongitude()),
                        calculateDistance(lat, lng, b.getLatitude(), b.getLongitude())))
                .map(point -> {
                    if (point.getYearlyEnergyDcKwh() != null) {
                        // Normalize Google's data to our scale (0.5 to 1.5 factor)
                        double normalizedValue = point.getYearlyEnergyDcKwh() / 1500.0; // Assume 1500 kWh as baseline
                        return Math.max(0.5, Math.min(1.5, normalizedValue));
                    }
                    return 1.0;
                })
                .orElse(1.0);
    }

    private double getShadingFactorForPoint(double lat, double lng,
            EnhancedShadingService.ShadingAnalysis shadingAnalysis) {
        // Get shading factor for this specific point from the detailed analysis
        var elevationData = shadingAnalysis.getElevationData();

        if (elevationData.isEmpty()) {
            return shadingAnalysis.getAverageShading();
        }

        // Find nearest elevation point and use its shading
        return elevationData.stream()
                .min((a, b) -> Double.compare(
                        calculateDistance(lat, lng, a.getLatitude(), a.getLongitude()),
                        calculateDistance(lat, lng, b.getLatitude(), b.getLongitude())))
                .map(point -> {
                    // Calculate local shading based on elevation difference
                    double avgElevation = elevationData.stream().mapToDouble(ep -> ep.getElevation()).average()
                            .orElse(0);
                    double elevationDiff = point.getElevation() - avgElevation;

                    // Higher elevation = less shading, lower elevation = more shading
                    double elevationFactor = Math.max(0, Math.min(0.5, elevationDiff / 100.0)); // ±50m = ±0.5 shading
                                                                                                // factor
                    return Math.max(0, shadingAnalysis.getAverageShading() - elevationFactor);
                })
                .orElse(shadingAnalysis.getAverageShading());
    }

    private String calculateEnhancedColor(double intensity, double shadingFactor, double weatherFactor) {
        // Enhanced color calculation considering multiple factors
        double normalizedIntensity = Math.max(0, Math.min(1, intensity / 2000.0)); // Normalize to 0-1

        // Adjust color based on shading and weather
        double colorIntensity = normalizedIntensity * (1.0 - shadingFactor * 0.5) * weatherFactor;

        if (colorIntensity >= 0.8)
            return "#00FF00"; // Excellent (bright green)
        if (colorIntensity >= 0.6)
            return "#80FF00"; // Very good (yellow-green)
        if (colorIntensity >= 0.4)
            return "#FFFF00"; // Good (yellow)
        if (colorIntensity >= 0.2)
            return "#FF8000"; // Fair (orange)
        return "#FF0000"; // Poor (red)
    }

    private List<Double> calculateMonthlyProduction(double intensity,
            List<GoogleWeatherClient.MonthlyWeatherData> weatherData) {
        return weatherData.stream()
                .map(monthData -> {
                    double monthlyIntensity = intensity * monthData.getSolarEfficiencyFactor();
                    double daysInMonth = 30.44; // Average days per month
                    return monthlyIntensity * daysInMonth;
                })
                .toList();
    }

    private Map<String, Object> createEnhancedAnalysisData(List<GoogleSolarClient.GoogleSolarDataPoint> googleData,
            List<GoogleWeatherClient.MonthlyWeatherData> weatherData,
            EnhancedShadingService.ShadingAnalysis shadingAnalysis,
            double weatherFactor,
            double shadingFactor) {
        var analysisData = new HashMap<String, Object>();

        // Enhanced shadow analysis
        analysisData.put("averageShading", shadingAnalysis.getAverageShading());
        analysisData.put("morningShading", shadingAnalysis.getMorningShading());
        analysisData.put("noonShading", shadingAnalysis.getNoonShading());
        analysisData.put("eveningShading", shadingAnalysis.getEveningShading());
        analysisData.put("winterShading", shadingAnalysis.getWinterShading());
        analysisData.put("summerShading", shadingAnalysis.getSummerShading());

        // Weather impact analysis
        analysisData.put("averageWeatherFactor", weatherFactor);
        analysisData.put("monthlyWeatherData", weatherData);
        analysisData.put("bestProductionMonths", getBestProductionMonths(weatherData));
        analysisData.put("worstProductionMonths", getWorstProductionMonths(weatherData));

        // Google Solar comparison
        if (googleData != null && !googleData.isEmpty()) {
            analysisData.put("googleSolarDataAvailable", true);
            analysisData.put("googleSolarAverageProduction",
                    googleData.stream()
                            .filter(d -> d.getYearlyEnergyDcKwh() != null)
                            .mapToDouble(d -> d.getYearlyEnergyDcKwh())
                            .average()
                            .orElse(0.0));
        } else {
            analysisData.put("googleSolarDataAvailable", false);
        }

        // Overall efficiency factors
        analysisData.put("overallShadingFactor", shadingFactor);
        analysisData.put("overallWeatherFactor", weatherFactor);
        analysisData.put("combinedEfficiencyFactor", shadingFactor * weatherFactor);

        // Recommendations
        analysisData.put("recommendations", generateRecommendations(shadingAnalysis, weatherData, googleData));

        return analysisData;
    }

    private List<String> getBestProductionMonths(List<GoogleWeatherClient.MonthlyWeatherData> weatherData) {
        String[] monthNames = { "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December" };

        return weatherData.stream()
                .filter(wd -> wd.getSolarEfficiencyFactor() > 0.85)
                .map(wd -> monthNames[wd.getMonth() - 1]) // Convert 1-12 to month name
                .toList();
    }

    private List<String> getWorstProductionMonths(List<GoogleWeatherClient.MonthlyWeatherData> weatherData) {
        String[] monthNames = { "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December" };

        return weatherData.stream()
                .filter(wd -> wd.getSolarEfficiencyFactor() < 0.6)
                .map(wd -> monthNames[wd.getMonth() - 1]) // Convert 1-12 to month name
                .toList();
    }

    private List<String> generateRecommendations(EnhancedShadingService.ShadingAnalysis shadingAnalysis,
            List<GoogleWeatherClient.MonthlyWeatherData> weatherData,
            List<GoogleSolarClient.GoogleSolarDataPoint> googleData) {
        var recommendations = new ArrayList<String>();

        // Shading recommendations
        if (shadingAnalysis.getAverageShading() > 0.3) {
            recommendations.add("High shading detected. Consider tree trimming or alternative panel placement.");
        }
        if (shadingAnalysis.getMorningShading() > 0.4) {
            recommendations.add(
                    "Significant morning shading. Consider east-facing installations for better afternoon production.");
        }
        if (shadingAnalysis.getEveningShading() > 0.4) {
            recommendations.add("Evening shading detected. West-facing panels may be less efficient.");
        }

        // Weather recommendations
        double avgWeatherFactor = weatherData.stream()
                .mapToDouble(wd -> wd.getSolarEfficiencyFactor())
                .average()
                .orElse(0.8);

        if (avgWeatherFactor < 0.7) {
            recommendations.add("Weather conditions may reduce efficiency. Consider higher-efficiency panels.");
        }

        var winterMonths = weatherData.stream()
                .filter(wd -> wd.getMonth() == 12 || wd.getMonth() == 1 || wd.getMonth() == 2) // December, January,
                                                                                               // February
                .mapToDouble(wd -> wd.getSolarEfficiencyFactor())
                .average()
                .orElse(0.5);

        if (winterMonths < 0.4) {
            recommendations.add("Low winter production expected. Consider battery storage or grid-tie systems.");
        }

        // Google Solar recommendations
        if (googleData != null && !googleData.isEmpty()) {
            double avgGoogleProduction = googleData.stream()
                    .filter(d -> d.getYearlyEnergyDcKwh() != null)
                    .mapToDouble(d -> d.getYearlyEnergyDcKwh())
                    .average()
                    .orElse(0.0);

            if (avgGoogleProduction > 1800) {
                recommendations.add("Excellent solar potential according to Google Solar data. High ROI expected.");
            } else if (avgGoogleProduction < 1000) {
                recommendations.add("Lower solar potential detected. Consider alternative energy solutions.");
            }
        }

        return recommendations;
    }

    private double getPortugalAverageGhi() {
        // Portugal average Global Horizontal Irradiance in kWh/m2/year
        return 1650.0; // Typical for Portugal
    }

    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        // Simple distance calculation (Haversine formula approximation)
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return 6371000 * c; // Earth radius in meters
    }

    private record Bounds(double minLat, double maxLat, double minLng, double maxLng) {
    }

    private Bounds calculateBounds(List<LatLng> points) {
        double minLat = points.stream().mapToDouble(LatLng::lat).min().orElse(0);
        double maxLat = points.stream().mapToDouble(LatLng::lat).max().orElse(0);
        double minLng = points.stream().mapToDouble(LatLng::lng).min().orElse(0);
        double maxLng = points.stream().mapToDouble(LatLng::lng).max().orElse(0);
        return new Bounds(minLat, maxLat, minLng, maxLng);
    }

    // ray casting algo
    private boolean isPointInPolygon(double lat, double lng, List<LatLng> points) {
        int count = 0;
        for (int i = 0, j = points.size() - 1; i < points.size(); j = i++) {
            if ((points.get(i).lat() > lat) != (points.get(j).lat() > lat) &&
                    lng < (points.get(j).lng() - points.get(i).lng()) *
                            (lat - points.get(i).lat()) /
                            (points.get(j).lat() - points.get(i).lat()) + points.get(i).lng()) {
                count++;
            }
        }
        return count % 2 == 1;
    }

    private double calculateBaseSolarIntensity(double lat, double lng) {
        // Simple estimate (real lookup would use terrain/climate data)
        // For Portugal: decent solar irradiance,
        // but varies N-S, terrain, etc.
        // Return kWh/m2/year equivalent
        double avgSolarPortugal = 1400; // rough average

        // Apply latitude effect (Northern Portugal gets a bit less)
        double latFactor = 1.0 - (lat - 36.8) * 0.02; // small decrease northward
        double baseSolar = avgSolarPortugal * latFactor;

        // Apply longitude effect (coastal vs inland)
        double lngFactor = 1.0 + (lng + 8.0) * 0.02; // slight coastal bonus

        return baseSolar * lngFactor;
    }
}
