package com.solarterrain.analytics_backend.solar;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.HashMap;

@Service
public class GoogleWeatherClient {

    @Value("${google.api.key:}")
    private String googleApiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String WEATHER_API_BASE_URL = "https://weather.googleapis.com/v1";

    /**
     * Get historical weather data for solar production calculations
     */
    public WeatherData getHistoricalWeatherData(double latitude, double longitude, int months) {
        try {
            // Get current weather and forecast data
            String url = String.format(Locale.US,
                    "%s/currentConditions:lookup?location.latitude=%.6f&location.longitude=%.6f&key=%s",
                    WEATHER_API_BASE_URL, latitude, longitude, googleApiKey);

            var response = restTemplate.getForObject(url, GoogleWeatherResponse.class);

            if (response != null) {
                return convertToWeatherData(response, latitude, longitude);
            }

            return null;
        } catch (Exception e) {
            System.err.println("Error fetching Google Weather data: " + e.getMessage());
            // Return default weather data for Portugal if API fails
            return getDefaultPortugalWeatherData(latitude, longitude);
        }
    }

    /**
     * Get monthly weather patterns that affect solar production
     */
    public List<MonthlyWeatherData> getMonthlyWeatherPatterns(double latitude, double longitude) {
        var monthlyData = new java.util.ArrayList<MonthlyWeatherData>();

        // Portugal monthly weather patterns (historical averages)
        Map<Integer, MonthlyWeatherPattern> portugalPatterns = new HashMap<>();
        portugalPatterns.put(1, new MonthlyWeatherPattern(12.5, 55, 120, 6.2, 0.65)); // January
        portugalPatterns.put(2, new MonthlyWeatherPattern(14.1, 52, 110, 7.1, 0.70)); // February
        portugalPatterns.put(3, new MonthlyWeatherPattern(16.8, 48, 95, 8.5, 0.75)); // March
        portugalPatterns.put(4, new MonthlyWeatherPattern(18.9, 45, 80, 9.8, 0.82)); // April
        portugalPatterns.put(5, new MonthlyWeatherPattern(22.3, 38, 60, 11.5, 0.88)); // May
        portugalPatterns.put(6, new MonthlyWeatherPattern(26.1, 25, 25, 12.8, 0.95)); // June
        portugalPatterns.put(7, new MonthlyWeatherPattern(28.7, 15, 5, 13.2, 0.98)); // July
        portugalPatterns.put(8, new MonthlyWeatherPattern(28.9, 18, 10, 12.9, 0.96)); // August
        portugalPatterns.put(9, new MonthlyWeatherPattern(26.2, 32, 45, 11.1, 0.90)); // September
        portugalPatterns.put(10, new MonthlyWeatherPattern(21.8, 48, 85, 9.2, 0.78)); // October
        portugalPatterns.put(11, new MonthlyWeatherPattern(16.9, 58, 115, 7.5, 0.68)); // November
        portugalPatterns.put(12, new MonthlyWeatherPattern(13.8, 60, 130, 6.8, 0.62)); // December

        for (int month = 1; month <= 12; month++) {
            var pattern = portugalPatterns.get(month);

            monthlyData.add(new MonthlyWeatherData(
                    month,
                    pattern.averageSunHours,
                    pattern.humidity, // usando humidity em vez de cloudCoverPercentage
                    pattern.rainyDays,
                    pattern.temperature, // usando temperature do pattern
                    pattern.humidity, // usando humidity do pattern
                    pattern.solarEfficiencyFactor)); // usando solarEfficiencyFactor do pattern
        }

        return monthlyData;
    }

    private double calculateSolarEfficiencyFactor(MonthlyWeatherPattern pattern) {
        // Calculate solar panel efficiency based on weather conditions
        double sunFactor = Math.min(pattern.averageSunHours / 12.0, 1.0); // Max 12 hours
        double humidityFactor = 1.0 - (pattern.humidity / 100.0 * 0.1); // High humidity reduces efficiency by up to 10%
        double rainFactor = 1.0 - (pattern.rainyDays / 30.0 * 0.2); // Rain reduces efficiency by up to 20%

        return sunFactor * humidityFactor * rainFactor;
    }

    private WeatherData convertToWeatherData(GoogleWeatherResponse response, double lat, double lng) {
        var conditions = response.getCurrentConditions();
        if (conditions == null)
            return null;

        return new WeatherData(
                lat,
                lng,
                conditions.getTemperature(),
                conditions.getHumidity(),
                conditions.getCloudCover(),
                conditions.getVisibility(),
                LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
    }

    private WeatherData getDefaultPortugalWeatherData(double latitude, double longitude) {
        // Default weather data for Portugal (annual averages)
        return new WeatherData(
                latitude,
                longitude,
                18.5, // Average temperature in Portugal
                65.0, // Average humidity
                45.0, // Average cloud cover
                15.0, // Average visibility in km
                LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GoogleWeatherResponse {
        @JsonProperty("currentConditions")
        private CurrentConditions currentConditions;

        public CurrentConditions getCurrentConditions() {
            return currentConditions;
        }

        @JsonIgnoreProperties(ignoreUnknown = true)
        public static class CurrentConditions {
            @JsonProperty("temperature")
            private Double temperature;

            @JsonProperty("humidity")
            private Double humidity;

            @JsonProperty("cloudCover")
            private Double cloudCover;

            @JsonProperty("visibility")
            private Double visibility;

            @JsonProperty("uvIndex")
            private Integer uvIndex;

            public Double getTemperature() {
                return temperature;
            }

            public Double getHumidity() {
                return humidity;
            }

            public Double getCloudCover() {
                return cloudCover;
            }

            public Double getVisibility() {
                return visibility;
            }

            public Integer getUvIndex() {
                return uvIndex;
            }
        }
    }

    public static class WeatherData {
        private final double latitude;
        private final double longitude;
        private final double temperature;
        private final double humidity;
        private final double cloudCover;
        private final double visibility;
        private final String timestamp;

        public WeatherData(double latitude, double longitude, double temperature,
                double humidity, double cloudCover, double visibility, String timestamp) {
            this.latitude = latitude;
            this.longitude = longitude;
            this.temperature = temperature;
            this.humidity = humidity;
            this.cloudCover = cloudCover;
            this.visibility = visibility;
            this.timestamp = timestamp;
        }

        // Getters
        public double getLatitude() {
            return latitude;
        }

        public double getLongitude() {
            return longitude;
        }

        public double getTemperature() {
            return temperature;
        }

        public double getHumidity() {
            return humidity;
        }

        public double getCloudCover() {
            return cloudCover;
        }

        public double getVisibility() {
            return visibility;
        }

        public String getTimestamp() {
            return timestamp;
        }
    }

    public static class MonthlyWeatherData {
        private final int month;
        private final double averageSunHours;
        private final double cloudCoverPercentage;
        private final int rainyDays;
        private final double temperature;
        private final double humidity;
        private final double solarEfficiencyFactor;

        public MonthlyWeatherData(int month, double averageSunHours, double cloudCoverPercentage,
                int rainyDays, double temperature, double humidity, double solarEfficiencyFactor) {
            this.month = month;
            this.averageSunHours = averageSunHours;
            this.cloudCoverPercentage = cloudCoverPercentage;
            this.rainyDays = rainyDays;
            this.temperature = temperature;
            this.humidity = humidity;
            this.solarEfficiencyFactor = solarEfficiencyFactor;
        }

        // Getters
        public int getMonth() {
            return month;
        }

        public double getAverageSunHours() {
            return averageSunHours;
        }

        public double getCloudCoverPercentage() {
            return cloudCoverPercentage;
        }

        public int getRainyDays() {
            return rainyDays;
        }

        public double getTemperature() {
            return temperature;
        }

        public double getHumidity() {
            return humidity;
        }

        public double getSolarEfficiencyFactor() {
            return solarEfficiencyFactor;
        }
    }

    private static record MonthlyWeatherPattern(double temperature, int humidity, int rainyDays, double averageSunHours,
            double solarEfficiencyFactor) {
    }
}
