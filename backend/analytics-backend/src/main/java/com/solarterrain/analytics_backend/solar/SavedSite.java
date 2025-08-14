package com.solarterrain.analytics_backend.solar;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
public class SavedSite {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String userId;
    private String siteName;
    @Column(length = 500)
    private String description;
    @Column(length = 8000)
    private String polygonGeoJson;
    private double areaM2;
    private double usableAreaM2;
    private double systemKWp;
    private double annualEnergyKWh;
    private double annualIrradiationKWhM2;
    private double performanceRatio;
    private Instant createdAt = Instant.now();
    private Instant updatedAt = Instant.now();

    @PreUpdate
    public void preUpdate() {
        updatedAt = Instant.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getSiteName() {
        return siteName;
    }

    public void setSiteName(String siteName) {
        this.siteName = siteName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getPolygonGeoJson() {
        return polygonGeoJson;
    }

    public void setPolygonGeoJson(String polygonGeoJson) {
        this.polygonGeoJson = polygonGeoJson;
    }

    public double getAreaM2() {
        return areaM2;
    }

    public void setAreaM2(double areaM2) {
        this.areaM2 = areaM2;
    }

    public double getUsableAreaM2() {
        return usableAreaM2;
    }

    public void setUsableAreaM2(double usableAreaM2) {
        this.usableAreaM2 = usableAreaM2;
    }

    public double getSystemKWp() {
        return systemKWp;
    }

    public void setSystemKWp(double systemKWp) {
        this.systemKWp = systemKWp;
    }

    public double getAnnualEnergyKWh() {
        return annualEnergyKWh;
    }

    public void setAnnualEnergyKWh(double annualEnergyKWh) {
        this.annualEnergyKWh = annualEnergyKWh;
    }

    public double getAnnualIrradiationKWhM2() {
        return annualIrradiationKWhM2;
    }

    public void setAnnualIrradiationKWhM2(double annualIrradiationKWhM2) {
        this.annualIrradiationKWhM2 = annualIrradiationKWhM2;
    }

    public double getPerformanceRatio() {
        return performanceRatio;
    }

    public void setPerformanceRatio(double performanceRatio) {
        this.performanceRatio = performanceRatio;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
