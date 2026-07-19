package com.supermarket.backend.repository;

import com.supermarket.backend.entity.LeaveRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Integer> {

    /** A user's leave requests, newest first. */
    List<LeaveRequest> findByUserIdOrderByCreatedDateDesc(UUID userId);

    /**
     * True when the user already has a PENDING or APPROVED leave request whose
     * date range overlaps [startDate, endDate]. Two ranges overlap when each
     * starts on or before the other ends.
     */
    @Query("""
            SELECT COUNT(r) > 0 FROM LeaveRequest r
            WHERE r.userId = :userId
              AND r.status IN ('PENDING', 'APPROVED')
              AND r.startDate <= :endDate
              AND r.endDate >= :startDate
            """)
    boolean existsOverlappingRequest(@Param("userId") UUID userId,
                                     @Param("startDate") LocalDate startDate,
                                     @Param("endDate") LocalDate endDate);
}
