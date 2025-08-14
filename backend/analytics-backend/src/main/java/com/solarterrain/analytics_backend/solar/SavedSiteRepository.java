package com.solarterrain.analytics_backend.solar;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SavedSiteRepository extends JpaRepository<SavedSite, Long> {
    List<SavedSite> findByUserIdOrderByCreatedAtDesc(String userId);
}
