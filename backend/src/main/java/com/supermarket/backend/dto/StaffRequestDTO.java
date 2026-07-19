package com.supermarket.backend.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Unified response DTO used by the Manager Request Management screen.
 *
 * It represents either:
 * - a leave request
 * - a shift change request
 *
 * This DTO is read-only and does not perform database mutations.
 */
public class StaffRequestDTO {

    private Integer requestNumber;
    private String requestType;
    private UUID userId;
    private String employeeName;
    private String reason;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;
    private LocalDateTime createdDate;
    private LocalDateTime approvedDate;

    public StaffRequestDTO() {
    }

    public StaffRequestDTO(
            Integer requestNumber,
            String requestType,
            UUID userId,
            String employeeName,
            String reason,
            LocalDate startDate,
            LocalDate endDate,
            String status,
            LocalDateTime createdDate,
            LocalDateTime approvedDate) {
        this.requestNumber = requestNumber;
        this.requestType = requestType;
        this.userId = userId;
        this.employeeName = employeeName;
        this.reason = reason;
        this.startDate = startDate;
        this.endDate = endDate;
        this.status = status;
        this.createdDate = createdDate;
        this.approvedDate = approvedDate;
    }

    public Integer getRequestNumber() {
        return requestNumber;
    }

    public void setRequestNumber(Integer requestNumber) {
        this.requestNumber = requestNumber;
    }

    public String getRequestType() {
        return requestType;
    }

    public void setRequestType(String requestType) {
        this.requestType = requestType;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getEmployeeName() {
        return employeeName;
    }

    public void setEmployeeName(String employeeName) {
        this.employeeName = employeeName;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(LocalDateTime createdDate) {
        this.createdDate = createdDate;
    }

    public LocalDateTime getApprovedDate() {
        return approvedDate;
    }

    public void setApprovedDate(LocalDateTime approvedDate) {
        this.approvedDate = approvedDate;
    }
}