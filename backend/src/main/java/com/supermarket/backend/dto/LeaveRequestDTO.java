package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Payload for creating and returning leave requests.
 * On create the client sends userId, reason, startDate, endDate; the rest are
 * populated by the backend and echoed back.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaveRequestDTO {

    private Integer leaveNumber;

    @NotNull(message = "userId is required")
    private String userId;

    @NotBlank(message = "reason is required")
    private String reason;

    @NotNull(message = "startDate is required")
    private LocalDate startDate;

    @NotNull(message = "endDate is required")
    private LocalDate endDate;

    private String status;
    private LocalDateTime createdDate;
    private LocalDateTime approvedDate;
}
