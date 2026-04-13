package com.tujuhsembilan.smartedutelu.domain.identity.service;

import com.tujuhsembilan.smartedutelu.common.enums.ErrorCode;
import com.tujuhsembilan.smartedutelu.common.exception.BusinessException;
import com.tujuhsembilan.smartedutelu.common.exception.DuplicateResourceException;
import com.tujuhsembilan.smartedutelu.common.exception.ResourceNotFoundException;
import com.tujuhsembilan.smartedutelu.common.security.JwtUtil;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.request.*;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.LoginResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.SessionResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.UserResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.entity.*;
import com.tujuhsembilan.smartedutelu.domain.identity.repository.*;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final UserRoleRepository userRoleRepository;
    private final UserSessionRepository userSessionRepository;
    private final PasswordResetRepository passwordResetRepository;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final EmailService emailService;

    @Transactional
    public UserResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("User", "email", request.getEmail());
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .phone(request.getPhone())
                .status("active")
                .build();

        user = userRepository.save(user);

        // Assign default role: student
        Role studentRole = roleRepository.findByName("student")
                .orElseGet(() -> roleRepository.save(Role.builder().name("student").description("Default student role").build()));

        UserRole userRole = UserRole.builder()
                .user(user)
                .role(studentRole)
                .build();
        userRoleRepository.save(userRole);

        return toUserResponse(user, List.of(studentRole.getName()));
    }

    @Transactional
    public LoginResponse login(LoginRequest request, HttpServletRequest httpRequest) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
            );
        } catch (BadCredentialsException | DisabledException | LockedException e) {
            log.warn("Login gagal untuk email: [MASKED] — alasan: {}", e.getClass().getSimpleName());
            throw new BusinessException(ErrorCode.SE_AUT_001, "Email atau password salah");
        }

        User user = userRepository.findByEmailWithRoles(request.getEmail())
                .orElseThrow(() -> new ResourceNotFoundException("User", request.getEmail()));

        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getEmail());

        // Create session
        UserSession session = UserSession.builder()
                .user(user)
                .ipAddress(getClientIp(httpRequest))
                .userAgent(httpRequest.getHeader("User-Agent"))
                .device(parseDevice(httpRequest.getHeader("User-Agent")))
                .lastActive(LocalDateTime.now())
                .expiredAt(LocalDateTime.now().plus(Duration.ofMillis(jwtUtil.getRefreshExpiration())))
                .build();
        session = userSessionRepository.save(session);

        String accessToken = jwtUtil.generateToken(Map.of(), userDetails);
        String refreshToken = jwtUtil.generateRefreshToken(userDetails, session.getId());

        List<String> roles = user.getUserRoles().stream()
                .map(ur -> ur.getRole().getName())
                .toList();

        log.info("Login berhasil untuk user ID: {}", user.getId());

        return LoginResponse.builder()
                .token(accessToken)
                .refreshToken(refreshToken)
                .user(toUserResponse(user, roles))
                .build();
    }

    @Transactional
    public void logout(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        // Delete all active sessions for this user
        List<UserSession> sessions = userSessionRepository
                .findByUserIdAndExpiredAtAfterOrderByLastActiveDesc(user.getId(), LocalDateTime.now());
        userSessionRepository.deleteAll(sessions);

        log.info("Logout: {} sesi dihapus untuk user ID: {}", sessions.size(), user.getId());
    }

    @Transactional
    public LoginResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();

        String email;
        UUID sessionId;
        try {
            // Validate token type is "refresh" — prevents access token reuse
            String tokenType = jwtUtil.extractTokenType(refreshToken);
            if (!"refresh".equals(tokenType)) {
                throw new BusinessException(ErrorCode.SE_AUT_002, "Token bukan refresh token");
            }
            email = jwtUtil.extractUsername(refreshToken);
            sessionId = jwtUtil.extractSessionId(refreshToken);
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException(ErrorCode.SE_AUT_002, "Refresh token tidak valid");
        }

        if (jwtUtil.isTokenExpired(refreshToken)) {
            throw new BusinessException(ErrorCode.SE_AUT_002, "Refresh token sudah expired");
        }

        // Verify session exists and is still valid
        UserSession session = userSessionRepository.findByIdAndExpiredAtAfter(sessionId, LocalDateTime.now())
                .orElseThrow(() -> new BusinessException(ErrorCode.SE_AUT_002, "Session tidak valid atau sudah expired"));

        // Update last active
        session.setLastActive(LocalDateTime.now());
        userSessionRepository.save(session);

        UserDetails userDetails = userDetailsService.loadUserByUsername(email);
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        String newAccessToken = jwtUtil.generateToken(Map.of(), userDetails);
        String newRefreshToken = jwtUtil.generateRefreshToken(userDetails, sessionId);

        List<String> roles = user.getUserRoles().stream()
                .map(ur -> ur.getRole().getName())
                .toList();

        return LoginResponse.builder()
                .token(newAccessToken)
                .refreshToken(newRefreshToken)
                .user(toUserResponse(user, roles))
                .build();
    }

    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        // Always return success to prevent email enumeration
        userRepository.findByEmail(request.getEmail()).ifPresent(user -> {
            // Delete any existing reset tokens
            passwordResetRepository.deleteByUserId(user.getId());

            String token = UUID.randomUUID().toString();
            PasswordReset passwordReset = PasswordReset.builder()
                    .user(user)
                    .token(token)
                    .expiredAt(LocalDateTime.now().plusHours(1))
                    .build();
            passwordResetRepository.save(passwordReset);

            emailService.sendPasswordResetEmail(user.getEmail(), token);
        });
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        PasswordReset passwordReset = passwordResetRepository
                .findByTokenAndExpiredAtAfter(request.getToken(), LocalDateTime.now())
                .orElseThrow(() -> new BusinessException(ErrorCode.SE_AUT_005, "Token reset password tidak valid atau sudah expired"));

        User user = passwordReset.getUser();
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Delete used token
        passwordResetRepository.delete(passwordReset);

        log.info("Password reset berhasil untuk user ID: {}", user.getId());

        log.debug("Password reset berhasil untuk user: {}", user.getEmail());
    }

    @Transactional(readOnly = true)
    public UserResponse getProfile(String email) {
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        List<String> roles = user.getUserRoles().stream()
                .map(ur -> ur.getRole().getName())
                .toList();

        return toUserResponse(user, roles);
    }

    @Transactional
    public UserResponse updateProfile(String email, UpdateProfileRequest request) {
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        if (request.getName() != null) user.setName(request.getName());
        if (request.getPhone() != null) user.setPhone(request.getPhone());
        if (request.getPicture() != null) user.setPicture(request.getPicture());
        if (request.getLocale() != null) user.setLocale(request.getLocale());
        if (request.getTimezone() != null) user.setTimezone(request.getTimezone());

        user = userRepository.save(user);

        List<String> roles = user.getUserRoles().stream()
                .map(ur -> ur.getRole().getName())
                .toList();

        return toUserResponse(user, roles);
    }

    @Transactional
    public void changePassword(String email, ChangePasswordRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new BusinessException(ErrorCode.SE_AUT_006, "Password saat ini tidak sesuai");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        log.info("Password diubah untuk user ID: {}", user.getId());
    }

    @Transactional(readOnly = true)
    public List<SessionResponse> getSessions(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        return userSessionRepository
                .findByUserIdAndExpiredAtAfterOrderByLastActiveDesc(user.getId(), LocalDateTime.now())
                .stream()
                .map(this::toSessionResponse)
                .toList();
    }

    @Transactional
    public void revokeSession(String email, UUID sessionId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", email));

        UserSession session = userSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session", sessionId));

        if (!session.getUser().getId().equals(user.getId())) {
            throw new BusinessException(ErrorCode.SE_CMN_004, "Anda tidak memiliki akses ke session ini");
        }

        userSessionRepository.delete(session);

        log.info("Sesi {} dicabut untuk user ID: {}", sessionId, user.getId());
    }

    // ── Helper Methods ──────────────────────────────────────────

    private UserResponse toUserResponse(User user, List<String> roles) {
        return UserResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .picture(user.getPicture())
                .locale(user.getLocale())
                .timezone(user.getTimezone())
                .status(user.getStatus())
                .roles(roles)
                .build();
    }

    private SessionResponse toSessionResponse(UserSession session) {
        return SessionResponse.builder()
                .id(session.getId())
                .ipAddress(session.getIpAddress())
                .userAgent(session.getUserAgent())
                .device(session.getDevice())
                .lastActive(session.getLastActive())
                .expiredAt(session.getExpiredAt())
                .build();
    }

    private String getClientIp(HttpServletRequest request) {
        String remoteAddr = request.getRemoteAddr();
        // Only trust X-Forwarded-For from private/loopback (reverse proxy)
        if (isPrivateOrLoopback(remoteAddr)) {
            String xForwardedFor = request.getHeader("X-Forwarded-For");
            if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
                return xForwardedFor.split(",")[0].trim();
            }
        }
        return remoteAddr;
    }

    private boolean isPrivateOrLoopback(String ip) {
        if (ip == null) return false;
        // IPv4 loopback
        if (ip.startsWith("127.")) return true;
        // IPv4 private ranges (RFC 1918)
        if (ip.startsWith("10.")) return true;
        if (ip.startsWith("192.168.")) return true;
        if (ip.startsWith("172.")) {
            try {
                int second = Integer.parseInt(ip.split("\\.")[1]);
                if (second >= 16 && second <= 31) return true;
            } catch (NumberFormatException | ArrayIndexOutOfBoundsException e) {
                return false;
            }
        }
        // IPv6 loopback
        if ("0:0:0:0:0:0:0:1".equals(ip) || "::1".equals(ip)) return true;
        // IPv6 private (fc00::/7, fe80::/10)
        String lower = ip.toLowerCase();
        if (lower.startsWith("fc") || lower.startsWith("fd") || lower.startsWith("fe80")) return true;
        return false;
    }

    private String parseDevice(String userAgent) {
        if (userAgent == null) return "Unknown";
        if (userAgent.contains("Mobile")) return "Mobile";
        if (userAgent.contains("Tablet")) return "Tablet";
        return "Desktop";
    }
}
