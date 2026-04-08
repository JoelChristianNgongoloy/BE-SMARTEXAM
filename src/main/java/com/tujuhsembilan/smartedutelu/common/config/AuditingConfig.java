package com.tujuhsembilan.smartedutelu.common.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

@Configuration
@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
public class AuditingConfig {

    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> {
            // Mengambil konteks keamanan saat ini
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

            // Jika tidak ada user yang login (misal: registrasi awal atau proses internal sistem)
            if (authentication == null || !authentication.isAuthenticated() || authentication.getPrincipal().equals("anonymousUser")) {
                return Optional.of("SYSTEM");
            }

            // Mengembalikan username atau ID pengguna yang diekstrak oleh JwtAuthenticationFilter
            return Optional.of(authentication.getName());
        };
    }
}