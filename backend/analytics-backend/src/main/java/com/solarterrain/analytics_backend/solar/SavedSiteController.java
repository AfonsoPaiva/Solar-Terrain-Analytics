package com.solarterrain.analytics_backend.solar;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/solar/sites")
public class SavedSiteController {
    private final SavedSiteRepository repo;
    private final SolarEstimationService estimationService;

    public SavedSiteController(SavedSiteRepository repo, SolarEstimationService estimationService) {
        this.repo = repo;
        this.estimationService = estimationService;
    }

    private String uid(Authentication auth) {
        return auth == null ? null : (String) auth.getPrincipal();
    }

    @GetMapping
    public List<SavedSite> list(Authentication auth) {
        return repo.findByUserIdOrderByCreatedAtDesc(uid(auth));
    }

    @PostMapping
    public Map<String, Object> save(@RequestBody Map<String, Object> body, Authentication auth) {
        String userId = uid(auth);
        @SuppressWarnings("unchecked")
        var points = (List<Map<String, Object>>) body.get("points");
        String siteName = (String) body.getOrDefault("name", "Terreno Solar");
        String description = (String) body.getOrDefault("description", "");

        var latLngs = points.stream()
                .map(m -> new com.solarterrain.analytics_backend.geo.LatLng(
                        ((Number) m.get("lat")).doubleValue(),
                        ((Number) m.get("lng")).doubleValue()))
                .toList();

        var est = estimationService.estimate(latLngs);
        SavedSite s = new SavedSite();
        s.setUserId(userId);
        s.setSiteName(siteName);
        s.setDescription(description);

        String coords = points.stream().map(m -> "[" + m.get("lng") + "," + m.get("lat") + "]")
                .reduce((a, b) -> a + "," + b).orElse("");
        s.setPolygonGeoJson("{\"type\":\"Polygon\",\"coordinates\":[[" + coords + "]]}");
        s.setAreaM2(est.areaM2());
        s.setUsableAreaM2(est.usableAreaM2());
        s.setSystemKWp(est.assumedSystemKWp());
        s.setAnnualEnergyKWh(est.annualEnergyKWh());
        // Campos removidos que não existem mais na nova estrutura
        // s.setAnnualIrradiationKWhM2(est.annualIrradiationKWhM2());
        // s.setPerformanceRatio(est.performanceRatio());

        repo.save(s);
        return Map.of(
                "id", s.getId(),
                "message", "Terreno salvo com sucesso!",
                "estimate", est);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SavedSite> getSite(@PathVariable Long id, Authentication auth) {
        Optional<SavedSite> site = repo.findById(id);
        if (site.isPresent() && site.get().getUserId().equals(uid(auth))) {
            return ResponseEntity.ok(site.get());
        }
        return ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteSite(@PathVariable Long id, Authentication auth) {
        Optional<SavedSite> site = repo.findById(id);
        if (site.isPresent() && site.get().getUserId().equals(uid(auth))) {
            repo.delete(site.get());
            return ResponseEntity.ok(Map.of("message", "Terreno deletado com sucesso!"));
        }
        return ResponseEntity.notFound().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateSite(@PathVariable Long id,
            @RequestBody Map<String, Object> body,
            Authentication auth) {
        Optional<SavedSite> siteOpt = repo.findById(id);
        if (siteOpt.isPresent() && siteOpt.get().getUserId().equals(uid(auth))) {
            SavedSite site = siteOpt.get();

            if (body.containsKey("name")) {
                site.setSiteName((String) body.get("name"));
            }
            if (body.containsKey("description")) {
                site.setDescription((String) body.get("description"));
            }

            repo.save(site);
            return ResponseEntity.ok(Map.of(
                    "message", "Terreno atualizado com sucesso!",
                    "site", site));
        }
        return ResponseEntity.notFound().build();
    }
}
