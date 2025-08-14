package com.solarterrain.analytics_backend.solar;

import com.solarterrain.analytics_backend.geo.PolygonAreaRequest;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/solar")
public class SolarController {
    private final SolarEstimationService service;

    public SolarController(SolarEstimationService service) {
        this.service = service;
    }

    @PostMapping("/estimate")
    public Map<String, Object> estimate(@RequestBody PolygonAreaRequest req) {
        var est = service.estimate(req.points());
        return Map.ofEntries(
                Map.entry("areaM2", est.areaM2()),
                Map.entry("usableAreaM2", est.usableAreaM2()),
                Map.entry("assumedSystemKWp", est.assumedSystemKWp()),
                Map.entry("annualEnergyKWh", est.annualEnergyKWh()),
                Map.entry("enhancedHeatmapData", est.enhancedHeatmapData()),
                Map.entry("enhancedAnalysisData", est.enhancedAnalysisData()));
    }
}
