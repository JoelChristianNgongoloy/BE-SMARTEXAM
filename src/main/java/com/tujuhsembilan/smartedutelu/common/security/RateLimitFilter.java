package com.tujuhsembilan.smartedutelu.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tujuhsembilan.smartedutelu.common.dto.ApiResponse;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;

/**
 * Redis-backed rate limiter for authentication endpoints.
 * Limits requests per IP to prevent brute-force attacks.
 * Cluster-safe: works across multiple application instances.
 */
@Slf4j
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final String KEY_PREFIX = "rate_limit:auth:";

    private final int maxRequests;
    private final long windowMs;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public RateLimitFilter(
            StringRedisTemplate redisTemplate,
            @Value("${application.rate-limit.max-requests:10}") int maxRequests,
            @Value("${application.rate-limit.window-ms:60000}") long windowMs
    ) {
        this.redisTemplate = redisTemplate;
        this.maxRequests = maxRequests;
        this.windowMs = windowMs;
    }

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        String path = request.getServletPath();
        return !path.startsWith("/v1/auth/");
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {

        String clientIp = request.getRemoteAddr();
        String key = KEY_PREFIX + clientIp;

        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count != null && count == 1) {
                // First request in window — set TTL
                redisTemplate.expire(key, Duration.ofMillis(windowMs));
            }

            if (count != null && count > maxRequests) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);

                ApiResponse<Void> body = ApiResponse.error(
                        "SE_CMN_008",
                        "Terlalu banyak permintaan",
                        "Coba lagi dalam 1 menit"
                );

                objectMapper.findAndRegisterModules();
                objectMapper.writeValue(response.getOutputStream(), body);
                return;
            }
        } catch (Exception e) {
            // If Redis is down, allow the request (fail-open) but log the issue
            log.warn("Rate limiter Redis error, allowing request: {}", e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
