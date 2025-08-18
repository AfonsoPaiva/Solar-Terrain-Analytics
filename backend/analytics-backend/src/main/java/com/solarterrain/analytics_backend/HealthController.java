package com.solarterrain.analytics_backend;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "UP",
                "ts", System.currentTimeMillis());
    }

    @GetMapping("/api/test")
    public Map<String, Object> test() {
        return Map.of(
                "message", "Backend connection successful",
                "status", "OK",
                "timestamp", System.currentTimeMillis());
    }
}
