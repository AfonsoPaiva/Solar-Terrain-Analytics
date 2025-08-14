package com.solarterrain.analytics_backend.solar;

import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/solar/shading")
public class ShadingController {
    // Placeholder: real implementation would compute hourly shading factors using
    // DEM & sun position.
    @PostMapping("/day")
    public Map<String, Object> shadingDay(@RequestBody Map<String, Object> body) {
        LocalDate date = LocalDate.parse((String) body.getOrDefault("date", LocalDate.now().toString()));
        // Return flat 0 shading loss for 24 hours as placeholder.
        List<Double> hourlyLoss = java.util.stream.Stream.generate(() -> 0.0).limit(24).toList();
        return Map.of("date", date.toString(), "hourlyShadingLossFraction", hourlyLoss);
    }
}
