package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.StaffRequestStatusUpdateRequest;
import com.supermarket.backend.service.StaffRequestService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/manager/staff-requests")
public class StaffRequestController {

    private final StaffRequestService staffRequestService;

    public StaffRequestController(StaffRequestService staffRequestService) {
        this.staffRequestService = staffRequestService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getStaffRequests(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String requestType,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword) {

        Map<String, Object> data = staffRequestService.getStaffRequests(
                page,
                size,
                requestType,
                status,
                keyword);

        return ResponseEntity.ok(
                ApiResponse.success(
                        "Staff requests loaded successfully.",
                        data));
    }

    @PutMapping("/{requestNumber}/status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateStaffRequestStatus(
            @PathVariable Integer requestNumber,
            @RequestBody StaffRequestStatusUpdateRequest request) {

        try {
            Map<String, Object> data =
                    staffRequestService.updateStaffRequestStatus(
                            requestNumber,
                            request.getRequestType(),
                            request.getStatus());

            return ResponseEntity.ok(
                    ApiResponse.success(
                            "Staff request status updated successfully.",
                            data));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error(exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(
                    ApiResponse.error(exception.getMessage()));
        }
    }
}
