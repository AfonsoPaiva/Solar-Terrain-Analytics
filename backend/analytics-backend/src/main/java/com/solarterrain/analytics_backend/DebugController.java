package com.solarterrain.analytics_backend;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
public class DebugController {
    @GetMapping("/api/debug/principal")
    public Map<String, Object> principal(Authentication auth) {
        return Map.of(
                "authenticated", auth != null,
                "principal", auth != null ? auth.getPrincipal() : null);
    }
}
