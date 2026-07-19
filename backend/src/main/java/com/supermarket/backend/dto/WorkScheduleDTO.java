package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * A work_schedules assignment returned to the Work Schedule calendar,
 * joined with its shift's name and hours.
 * Status comes from the schedule_status enum:
 * ASSIGNED / COMPLETED / CANCELLED / MISSED.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkScheduleDTO {
    private Integer scheduleNumber;
    private LocalDate workDate;
    private String status;
    private Integer shiftNumber;
    private String shiftName;
    private LocalTime startTime;
    private LocalTime endTime;
}
