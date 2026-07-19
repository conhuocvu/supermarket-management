package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceDTO {
    private Integer attendanceNumber;
    private String userId;
    private LocalDate workDate;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    /** Derived: CHECKED_IN while check_out_time is null, otherwise CHECKED_OUT. */
    private String status;
    /** Worked duration in minutes; null while still checked in. */
    private Long durationMinutes;
}
