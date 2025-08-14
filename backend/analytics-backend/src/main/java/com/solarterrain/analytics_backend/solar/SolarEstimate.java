package com.solarterrain.analytics_backend.solar;

import java.util.List;
import java.util.Map;

public record SolarEstimate(
        double areaM2,
        double usableAreaM2,
        double assumedSystemKWp,
        double annualEnergyKWh,
        List<Map<String, Object>> enhancedHeatmapData,
        Map<String, Object> enhancedAnalysisData) {
}
