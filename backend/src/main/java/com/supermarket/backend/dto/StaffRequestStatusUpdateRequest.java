package com.supermarket.backend.dto;

/**
 * Request body used when a manager approves or rejects a staff request.
 */
public class StaffRequestStatusUpdateRequest {

    private String requestType;
    private String status;

    public StaffRequestStatusUpdateRequest() {
    }

    public StaffRequestStatusUpdateRequest(
            String requestType,
            String status) {
        this.requestType = requestType;
        this.status = status;
    }

    public String getRequestType() {
        return requestType;
    }

    public void setRequestType(String requestType) {
        this.requestType = requestType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
