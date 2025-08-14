package com.solarterrain.analytics_backend.geo;

public record LatLng(double lat, double lng) {
    public LatLng {
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            throw new IllegalArgumentException("Invalid coordinate lat=" + lat + " lng=" + lng);
        }
    }
}
