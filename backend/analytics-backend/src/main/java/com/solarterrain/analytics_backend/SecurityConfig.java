package com.solarterrain.analytics_backend;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.http.HttpMethod;
import java.util.List;

@Configuration
public class SecurityConfig {

    private final FirebaseAuthFilter firebaseAuthFilter;

    public SecurityConfig(FirebaseAuthFilter firebaseAuthFilter) {
        this.firebaseAuthFilter = firebaseAuthFilter;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        // Flutter web usa uma porta aleatória (ex: 53549). Usamos patterns.
        cfg.setAllowedOriginPatterns(List.of("http://localhost:*", "http://127.0.0.1:*"));
        // Em desenvolvimento podemos liberar todos os métodos e headers necessários.
        cfg.setAllowedMethods(List.of("GET", "POST", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
        // Se não estiver a usar cookies/sessions, credenciais podem ser false.
        // Authorization header funciona sem cookies.
        cfg.setAllowCredentials(false);
        cfg.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", cfg);
        return src;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable());
        http.cors(cors -> {
        }); // ativa CORS
        http.sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll() // preflight livre
                .requestMatchers(HttpMethod.POST, "/api/solar/estimate").permitAll() // estimativas públicas
                .requestMatchers(HttpMethod.POST, "/api/solar/sites/**").authenticated() // salvar terrenos requer
                                                                                         // autenticação
                .requestMatchers(HttpMethod.GET, "/api/solar/sites/**").authenticated() // listar terrenos requer
                                                                                        // autenticação
                .requestMatchers(HttpMethod.DELETE, "/api/solar/sites/**").authenticated() // deletar terrenos requer
                                                                                           // autenticação
                .anyRequest().permitAll());
        http.addFilterBefore(firebaseAuthFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

}
