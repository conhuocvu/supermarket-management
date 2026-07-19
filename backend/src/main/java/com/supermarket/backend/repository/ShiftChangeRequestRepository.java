package com.supermarket.backend.repository;

import com.supermarket.backend.entity.ShiftChangeRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ShiftChangeRequestRepository extends JpaRepository<ShiftChangeRequest, Integer> {

    /** A user's shift change requests, newest first. */
    List<ShiftChangeRequest> findByUserIdOrderByCreatedDateDesc(UUID userId);
}
