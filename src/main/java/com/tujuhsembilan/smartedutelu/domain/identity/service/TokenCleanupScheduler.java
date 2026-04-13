package com.tujuhsembilan.smartedutelu.domain.identity.service;

import com.tujuhsembilan.smartedutelu.domain.identity.repository.PasswordResetRepository;
import com.tujuhsembilan.smartedutelu.domain.identity.repository.UserSessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Scheduled task untuk membersihkan session dan token yang sudah expired.
 * Jalan setiap hari jam 02:00 pagi.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TokenCleanupScheduler {

    private final UserSessionRepository userSessionRepository;
    private final PasswordResetRepository passwordResetRepository;

    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void cleanupExpiredData() {
        LocalDateTime now = LocalDateTime.now();

        userSessionRepository.deleteByExpiredAtBefore(now);
        passwordResetRepository.deleteByExpiredAtBefore(now);

        log.info("Expired sessions and password reset tokens cleaned up");
    }
}
