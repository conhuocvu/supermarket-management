package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProfileRepository extends JpaRepository<Profile, UUID> {

    @Query("SELECT p.status FROM Profile p WHERE p.userId = :userId")
    String checkAccountStatus(@Param("userId") UUID userId);

    @Query("SELECT p FROM Profile p WHERE p.userId = :userId")
    Optional<Profile> findProfile(@Param("userId") UUID userId);

    @Query(value = "SELECT last_sign_in_at FROM auth.users WHERE id = :userId", nativeQuery = true)
    java.time.Instant getLastLogin(@Param("userId") UUID userId);
}
