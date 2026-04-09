package com.tujuhsembilan.smartedutelu.domain.identity.repository;

import com.tujuhsembilan.smartedutelu.domain.identity.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    @Query("SELECT u FROM User u LEFT JOIN FETCH u.userRoles ur LEFT JOIN FETCH ur.role WHERE u.email = :email")
    Optional<User> findByEmailWithRoles(String email);

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);
}
