package com.solarterrain.analytics_backend;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(FirebaseAuthFilter.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            try {
                log.debug("Verifying Firebase ID token for path {}", request.getRequestURI());
                FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(token);
                String uid = decoded.getUid();
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(uid, null, null);
                SecurityContextHolder.getContext().setAuthentication(auth);
                log.debug("Auth success uid={} path={}", uid, request.getRequestURI());
            } catch (Exception e) {
                log.warn("Invalid Firebase ID token: {}", e.getMessage());
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("Invalid Firebase ID token");
                return;
            }
        } else {
            if (request.getRequestURI().startsWith("/api/counter")) {
                log.debug("No Authorization header for protected path {}", request.getRequestURI());
            }
        }
        filterChain.doFilter(request, response);
    }
}
