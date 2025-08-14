package com.solarterrain.analytics_backend.solar;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Component
public class PVGISClient {
    private static final Logger log = LoggerFactory.getLogger(PVGISClient.class);
    private final RestTemplate rt = new RestTemplate();

    public PVGISResult pvcalc(double lat, double lon, double peakpower) {
        log.info("Calling PVGIS for lat={}, lon={}, peakpower={}", lat, lon, peakpower);

        URI uri = UriComponentsBuilder.fromHttpUrl("https://re.jrc.ec.europa.eu/api/v5_2/PVcalc")
                .queryParam("lat", lat)
                .queryParam("lon", lon)
                .queryParam("peakpower", peakpower)
                .queryParam("pvtechchoice", "crystSi")
                .queryParam("mountingplace", "free")
                .queryParam("angle", 35) // optimal for Portugal
                .queryParam("aspect", 0) // south-facing
                .queryParam("loss", 14) // default system losses %
                .queryParam("optimalangles", 1)
                .queryParam("outputformat", "json")
                .build(true).toUri();
        try {
            ResponseEntity<?> rawResp = rt.getForEntity(uri, Map.class);
            @SuppressWarnings("unchecked")
            ResponseEntity<Map<String, Object>> resp = (ResponseEntity<Map<String, Object>>) rawResp;
            if (!resp.getStatusCode().is2xxSuccessful() || resp.getBody() == null) {
                throw new RuntimeException("PVGIS error status=" + resp.getStatusCode());
            }
            Map<String, Object> body = resp.getBody();
            Map<String, Object> outputs = (Map<String, Object>) body.get("outputs");
            Map<String, Object> monthly = (Map<String, Object>) outputs.get("monthly");
            List<Map<String, Object>> monthlyData = (List<Map<String, Object>>) monthly.get("fixed");

            double totalAnnual = 0.0;
            List<Double> monthlyValues = new ArrayList<>();
            for (Map<String, Object> month : monthlyData) {
                Object emValue = month.get("E_m");
                double monthlyKWh = emValue instanceof Number ? ((Number) emValue).doubleValue() : 0.0;
                monthlyValues.add(monthlyKWh);
                totalAnnual += monthlyKWh;
            }

            Map<String, Object> totals = (Map<String, Object>) outputs.get("totals");
            Map<String, Object> totalFixed = (Map<String, Object>) totals.get("fixed");
            Object eyValue = totalFixed.get("E_y");
            if (eyValue instanceof Number) {
                totalAnnual = ((Number) eyValue).doubleValue();
            }

            return new PVGISResult(totalAnnual, monthlyValues);
        } catch (Exception e) {
            log.error("PVGIS API error for lat={}, lon={}: {}", lat, lon, e.getMessage());
            // Return default fallback values for Portugal
            double fallbackKWhPerKWp = 1400; // conservative estimate for Portugal
            double annualKWh = peakpower * fallbackKWhPerKWp;
            List<Double> monthlyFallback = new ArrayList<>();
            // Distribute annually with seasonal variation (summer higher, winter lower)
            double[] monthlyFactors = { 0.06, 0.07, 0.09, 0.11, 0.12, 0.13, 0.14, 0.13, 0.11, 0.09, 0.07, 0.06 };
            for (double factor : monthlyFactors) {
                monthlyFallback.add(annualKWh * factor);
            }
            return new PVGISResult(annualKWh, monthlyFallback);
        }
    }

    public record PVGISResult(double annualKWh, List<Double> monthlyKWh) {
    }
}
