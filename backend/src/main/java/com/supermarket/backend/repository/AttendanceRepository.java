package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Integer> {

    /** The currently open (not yet checked-out) record for a user, if any. */
    @Query("SELECT a FROM Attendance a WHERE a.userId = :userId AND a.checkOutTime IS NULL "
            + "ORDER BY a.checkInTime DESC")
    List<Attendance> findOpenRecords(@Param("userId") UUID userId);

    default Optional<Attendance> findOpenRecord(UUID userId) {
        return findOpenRecords(userId).stream().findFirst();
    }

    /** Today's latest record (open or closed) — used to display check-in/out times. */
    Optional<Attendance> findFirstByUserIdAndWorkDateOrderByCheckInTimeDesc(
            UUID userId, LocalDate workDate);

    /** Attendance history within a period (e.g. a month) for the schedule calendar. */
    List<Attendance> findByUserIdAndWorkDateBetweenOrderByWorkDateAsc(
            UUID userId, LocalDate startDate, LocalDate endDate);
}
