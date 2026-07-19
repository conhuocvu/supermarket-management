package com.supermarket.backend.repository;

import com.supermarket.backend.entity.WorkSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface WorkScheduleRepository extends JpaRepository<WorkSchedule, Integer> {

    /** One calendar row: the assignment joined with its shift's name and hours. */
    interface ScheduleRow {
        Integer getScheduleNumber();
        LocalDate getWorkDate();
        String getStatus();
        Integer getShiftNumber();
        String getShiftName();
        LocalTime getStartTime();
        LocalTime getEndTime();
    }

    /**
     * Assigned schedule within a period (e.g. a month) for the Work Schedule
     * calendar. Native query so the Postgres enum status can be cast to text
     * and the shifts table joined for shift name and hours.
     */
    @Query(value = """
            SELECT ws.schedule_number AS "scheduleNumber",
                   ws.work_date       AS "workDate",
                   ws.status::text    AS "status",
                   ws.shift_number    AS "shiftNumber",
                   s.shift_name       AS "shiftName",
                   s.start_time       AS "startTime",
                   s.end_time         AS "endTime"
            FROM work_schedules ws
            LEFT JOIN shifts s ON s.shift_number = ws.shift_number
            WHERE ws.user_id = :userId
              AND ws.work_date BETWEEN :startDate AND :endDate
            ORDER BY ws.work_date ASC
            """, nativeQuery = true)
    List<ScheduleRow> findScheduleForPeriod(
            @Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
