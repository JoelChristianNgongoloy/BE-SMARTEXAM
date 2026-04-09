package com.tujuhsembilan.smartedutelu.domain.identity.repository;

import com.tujuhsembilan.smartedutelu.domain.identity.entity.UserSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSession, UUID> {

    List<UserSession> findByUserIdAndExpiredAtAfterOrderByLastActiveDesc(UUID userId, LocalDateTime now);

    Optional<UserSession> findByIdAndExpiredAtAfter(UUID id, LocalDateTime now);

    void deleteByExpiredAtBefore(LocalDateTime now);
}
