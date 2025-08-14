package com.solarterrain.analytics_backend;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.Firestore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

@Configuration
public class FirebaseConfig {
    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${firebase.key.path:}")
    private String firebaseKeyPathProp;
    @Value("${firebase.project-id:}")
    private String firebaseProjectId;

    @Bean
    public Firestore firestore() throws IOException {
        if (FirebaseApp.getApps().isEmpty()) {
            String keyPath = System.getenv("FIREBASE_KEY_PATH");
            if (keyPath == null || keyPath.isBlank()) {
                if (firebaseKeyPathProp != null && !firebaseKeyPathProp.isBlank()) {
                    keyPath = firebaseKeyPathProp;
                    log.info("Using firebase.key.path property");
                }
            }
            log.info("Resolved service account path={}", keyPath);
            if (keyPath == null || keyPath.isBlank()) {
                throw new IllegalStateException(
                        "Environment variable FIREBASE_KEY_PATH or property firebase.key.path not set");
            }
            Path p = Path.of(keyPath);
            if (!Files.exists(p)) {
                throw new IllegalStateException("Service account file not found at " + p);
            }
            try (FileInputStream serviceAccount = new FileInputStream(p.toFile())) {
                FirebaseOptions.Builder ob = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount));
                if (firebaseProjectId != null && !firebaseProjectId.isBlank()) {
                    ob.setProjectId(firebaseProjectId);
                    log.info("Using explicit firebase.project-id={}", firebaseProjectId);
                }
                FirebaseOptions options = ob.build();
                FirebaseApp.initializeApp(options);
                log.info("FirebaseApp initialized successfully");
            }
        }
        Firestore fs = FirestoreClient.getFirestore();
        try {
            fs.collection("__startupCheck").document("ping").set(Map.of("ts", System.currentTimeMillis()));
            log.info("Firestore ping scheduled");
        } catch (Exception e) {
            log.warn("Startup ping failed: {}", e.getMessage());
        }
        return fs;
    }
}
