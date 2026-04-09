package com.tujuhsembilan.smartedutelu.domain.identity.controller;

import com.tujuhsembilan.smartedutelu.common.dto.ApiResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.request.*;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.LoginResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.SessionResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.UserResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Auth", description = "Authentication & profile management")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Registrasi user baru")
    public ResponseEntity<ApiResponse<UserResponse>> register(@Valid @RequestBody RegisterRequest request) {
        UserResponse user = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Registrasi berhasil", user));
    }

    @PostMapping("/login")
    @Operation(summary = "Login dan dapatkan JWT token")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        LoginResponse response = authService.login(request, httpRequest);
        return ResponseEntity.ok(ApiResponse.success("Login berhasil", response));
    }

    @PostMapping("/logout")
    @Operation(summary = "Logout dan hapus semua sesi aktif")
    public ResponseEntity<ApiResponse<Void>> logout(Authentication authentication) {
        authService.logout(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success("Logout berhasil", null));
    }

    @PostMapping("/refresh-token")
    @Operation(summary = "Refresh access token menggunakan refresh token")
    public ResponseEntity<ApiResponse<LoginResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        LoginResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.success("Token berhasil di-refresh", response));
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Kirim email reset password")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.ok(ApiResponse.success("Jika email terdaftar, link reset password telah dikirim", null));
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password menggunakan token dari email")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.success("Password berhasil direset", null));
    }

    @GetMapping("/me")
    @Operation(summary = "Get profil user yang sedang login")
    public ResponseEntity<ApiResponse<UserResponse>> getProfile(Authentication authentication) {
        UserResponse user = authService.getProfile(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(user));
    }

    @PutMapping("/me")
    @Operation(summary = "Update profil sendiri")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            Authentication authentication,
            @Valid @RequestBody UpdateProfileRequest request) {
        UserResponse user = authService.updateProfile(authentication.getName(), request);
        return ResponseEntity.ok(ApiResponse.success("Profil berhasil diperbarui", user));
    }

    @PutMapping("/me/password")
    @Operation(summary = "Ganti password sendiri")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            Authentication authentication,
            @Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(authentication.getName(), request);
        return ResponseEntity.ok(ApiResponse.success("Password berhasil diubah", null));
    }

    @GetMapping("/me/sessions")
    @Operation(summary = "List sesi login aktif")
    public ResponseEntity<ApiResponse<List<SessionResponse>>> getSessions(Authentication authentication) {
        List<SessionResponse> sessions = authService.getSessions(authentication.getName());
        return ResponseEntity.ok(ApiResponse.success(sessions));
    }

    @DeleteMapping("/me/sessions/{id}")
    @Operation(summary = "Revoke sesi tertentu")
    public ResponseEntity<Void> revokeSession(
            Authentication authentication,
            @PathVariable UUID id) {
        authService.revokeSession(authentication.getName(), id);
        return ResponseEntity.noContent().build();
    }
}
