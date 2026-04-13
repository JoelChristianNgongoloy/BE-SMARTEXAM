package com.tujuhsembilan.smartedutelu.config;

import com.tujuhsembilan.smartedutelu.domain.identity.entity.Role;
import com.tujuhsembilan.smartedutelu.domain.identity.entity.User;
import com.tujuhsembilan.smartedutelu.domain.identity.entity.UserRole;
import com.tujuhsembilan.smartedutelu.domain.identity.repository.RoleRepository;
import com.tujuhsembilan.smartedutelu.domain.identity.repository.UserRepository;
import com.tujuhsembilan.smartedutelu.domain.identity.repository.UserRoleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataSeeder implements ApplicationRunner {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final UserRoleRepository userRoleRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${application.seeder.enabled:true}")
    private boolean seederEnabled;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (!seederEnabled) {
            log.info("DataSeeder disabled via configuration");
            return;
        }
        seedUsers();
    }

    private void seedUsers() {
        List<SeedUser> seeds = List.of(
                new SeedUser("Super Admin", "admin@smartexam.com", "admin123", "admin"),
                new SeedUser("Budi Santoso", "teacher@smartexam.com", "teacher123", "teacher"),
                new SeedUser("Siti Nurhaliza", "student@smartexam.com", "student123", "student")
        );

        for (SeedUser seed : seeds) {
            if (userRepository.existsByEmail(seed.email())) {
                log.info("Seed user already exists: {}", seed.email());
                continue;
            }

            Role role = roleRepository.findByName(seed.roleName())
                    .orElseThrow(() -> new IllegalStateException(
                            "Role '" + seed.roleName() + "' not found. Make sure V13 migration has run."));

            User user = userRepository.save(User.builder()
                    .name(seed.name())
                    .email(seed.email())
                    .passwordHash(passwordEncoder.encode(seed.password()))
                    .status("active")
                    .build());

            userRoleRepository.save(UserRole.builder()
                    .user(user)
                    .role(role)
                    .build());

            log.info("Seeded user: {} [{}]", seed.email(), seed.roleName());
        }
    }

    private record SeedUser(String name, String email, String password, String roleName) {}
}
