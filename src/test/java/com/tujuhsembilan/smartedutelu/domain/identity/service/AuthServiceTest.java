package com.tujuhsembilan.smartedutelu.domain.identity.service;

import com.tujuhsembilan.smartedutelu.common.enums.ErrorCode;
import com.tujuhsembilan.smartedutelu.common.exception.BusinessException;
import com.tujuhsembilan.smartedutelu.common.exception.DuplicateResourceException;
import com.tujuhsembilan.smartedutelu.common.security.JwtUtil;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.request.LoginRequest;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.request.RegisterRequest;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.LoginResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.dto.response.UserResponse;
import com.tujuhsembilan.smartedutelu.domain.identity.entity.*;
import com.tujuhsembilan.smartedutelu.domain.identity.repository.*;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.*;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests untuk AuthService — auth flow inti.
 * Skeleton ini mencakup: register, login sukses, login gagal, dan duplikat email.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @InjectMocks
    private AuthService authService;

    @Mock private UserRepository userRepository;
    @Mock private RoleRepository roleRepository;
    @Mock private UserRoleRepository userRoleRepository;
    @Mock private UserSessionRepository userSessionRepository;
    @Mock private PasswordResetRepository passwordResetRepository;
    @Mock private AuthenticationManager authenticationManager;
    @Mock private UserDetailsService userDetailsService;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtUtil jwtUtil;
    @Mock private EmailService emailService;

    @Mock private HttpServletRequest httpRequest;

    // ── Register ────────────────────────────────────────────────

    @Test
    @DisplayName("Register: berhasil dengan role default student")
    void register_success() {
        var request = new RegisterRequest();
        request.setName("Test User");
        request.setEmail("test@example.com");
        request.setPassword("StrongPass1");

        when(userRepository.existsByEmail("test@example.com")).thenReturn(false);
        when(passwordEncoder.encode("StrongPass1")).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(roleRepository.findByName("student"))
                .thenReturn(Optional.of(Role.builder().name("student").description("Default").build()));
        when(userRoleRepository.save(any(UserRole.class))).thenAnswer(inv -> inv.getArgument(0));

        UserResponse result = authService.register(request);

        assertThat(result).isNotNull();
        assertThat(result.getName()).isEqualTo("Test User");
        assertThat(result.getEmail()).isEqualTo("test@example.com");
        assertThat(result.getRoles()).contains("student");
        verify(userRepository).save(any(User.class));
    }

    @Test
    @DisplayName("Register: gagal karena email sudah terdaftar")
    void register_duplicateEmail_throws() {
        var request = new RegisterRequest();
        request.setEmail("existing@example.com");
        request.setPassword("Pass123");
        request.setName("Dup");

        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(DuplicateResourceException.class);
    }

    // ── Login ───────────────────────────────────────────────────

    @Test
    @DisplayName("Login: berhasil mendapat access + refresh token")
    void login_success() {
        var request = new LoginRequest();
        request.setEmail("admin@example.com");
        request.setPassword("Admin123");

        Role adminRole = Role.builder().name("admin").description("Admin").build();
        UserRole ur = UserRole.builder().role(adminRole).build();
        User user = User.builder()
                .name("Admin")
                .email("admin@example.com")
                .passwordHash("hashed")
                .status("active")
                .build();
        user.setId(UUID.randomUUID());
        user.setUserRoles(List.of(ur));
        ur.setUser(user);

        when(httpRequest.getRemoteAddr()).thenReturn("127.0.0.1");
        when(httpRequest.getHeader("User-Agent")).thenReturn("TestAgent");
        when(userRepository.findByEmailWithRoles("admin@example.com")).thenReturn(Optional.of(user));

        UserDetails userDetails = org.springframework.security.core.userdetails.User.builder()
                .username("admin@example.com")
                .password("hashed")
                .authorities("ROLE_ADMIN")
                .build();
        when(userDetailsService.loadUserByUsername("admin@example.com")).thenReturn(userDetails);

        UserSession session = UserSession.builder().user(user).build();
        session.setId(UUID.randomUUID());
        when(userSessionRepository.save(any(UserSession.class))).thenReturn(session);

        when(jwtUtil.getRefreshExpiration()).thenReturn(604800000L);
        when(jwtUtil.generateToken(anyMap(), eq(userDetails))).thenReturn("access-token");
        when(jwtUtil.generateRefreshToken(eq(userDetails), any(UUID.class))).thenReturn("refresh-token");

        LoginResponse result = authService.login(request, httpRequest);

        assertThat(result.getToken()).isEqualTo("access-token");
        assertThat(result.getRefreshToken()).isEqualTo("refresh-token");
        assertThat(result.getUser().getEmail()).isEqualTo("admin@example.com");
    }

    @Test
    @DisplayName("Login: gagal — email/password salah")
    void login_badCredentials_throws() {
        var request = new LoginRequest();
        request.setEmail("wrong@example.com");
        request.setPassword("wrong");

        when(authenticationManager.authenticate(any()))
                .thenThrow(new BadCredentialsException("Bad credentials"));

        assertThatThrownBy(() -> authService.login(request, httpRequest))
                .isInstanceOf(BusinessException.class)
                .hasFieldOrPropertyWithValue("errorCode", ErrorCode.SE_AUT_001);
    }

    @Test
    @DisplayName("Login: gagal — akun dinonaktifkan (generic message)")
    void login_disabled_throws_generic() {
        var request = new LoginRequest();
        request.setEmail("disabled@example.com");
        request.setPassword("Pass123");

        when(authenticationManager.authenticate(any()))
                .thenThrow(new DisabledException("Disabled"));

        assertThatThrownBy(() -> authService.login(request, httpRequest))
                .isInstanceOf(BusinessException.class)
                .hasFieldOrPropertyWithValue("errorCode", ErrorCode.SE_AUT_001)
                .extracting("message")
                .isEqualTo("Email atau password salah");
    }

    @Test
    @DisplayName("Login: gagal — akun suspended (generic message)")
    void login_locked_throws_generic() {
        var request = new LoginRequest();
        request.setEmail("locked@example.com");
        request.setPassword("Pass123");

        when(authenticationManager.authenticate(any()))
                .thenThrow(new LockedException("Locked"));

        assertThatThrownBy(() -> authService.login(request, httpRequest))
                .isInstanceOf(BusinessException.class)
                .hasFieldOrPropertyWithValue("errorCode", ErrorCode.SE_AUT_001)
                .extracting("message")
                .isEqualTo("Email atau password salah");
    }
}
