package com.tujuhsembilan.smartedutelu.domain.identity.repository;

import com.tujuhsembilan.smartedutelu.domain.identity.entity.PasswordReset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PasswordResetRepository extends JpaRepository<PasswordReset, UUID> {

    Optional<PasswordReset> findByTokenAndExpiredAtAfter(String token, LocalDateTime now);

    void deleteByExpiredAtBefore(LocalDateTime now);

    void deleteByUserId(UUID userId);
}
