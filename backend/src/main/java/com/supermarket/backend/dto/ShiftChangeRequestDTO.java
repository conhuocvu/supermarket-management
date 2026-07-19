package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Payload for creating and returning shift change requests.
 * Includes structured fields for both the current (from) shift
 * and the target (to) shift.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShiftChangeRequestDTO {

    private Integer requestNumber;

    @NotNull(message = "userId is required")
    private String userId;

    private String reason;

    private String status;
    private LocalDateTime createdDate;
    private LocalDateTime approvedDate;

    // ── Current shift (ca hiện tại) ────────────────────────────────────────────
    @NotNull(message = "currentShiftDate is required")
    private LocalDate currentShiftDate;

    @NotNull(message = "currentShiftType is required")
    private String currentShiftType;

    @NotNull(message = "currentShiftStart is required")
    private LocalTime currentShiftStart;

    @NotNull(message = "currentShiftEnd is required")
    private LocalTime currentShiftEnd;

    // ── Target shift (ca muốn đổi sang) ───────────────────────────────────────
    @NotNull(message = "targetShiftDate is required")
    private LocalDate targetShiftDate;

    @NotNull(message = "targetShiftType is required")
    private String targetShiftType;

    @NotNull(message = "targetShiftStart is required")
    private LocalTime targetShiftStart;

    @NotNull(message = "targetShiftEnd is required")
    private LocalTime targetShiftEnd;
}
