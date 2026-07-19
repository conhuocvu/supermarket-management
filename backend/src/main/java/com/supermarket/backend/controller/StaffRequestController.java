package com.supermarket.backend.controller;

import com.supermarket.backend.service.StaffRequestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Read-only API for the Manager Request Management screen.
 */
@RestController
@RequestMapping("/api/manager/staff-requests")
public class StaffRequestController {

    private final StaffRequestService staffRequestService;

    public StaffRequestController(
            StaffRequestService staffRequestService) {
        this.staffRequestService = staffRequestService;
    }

    /**
     * Returns leave requests and shift change requests
     * in one unified paginated list.
     *
     * Example:
     * GET /api/manager/staff-requests
     * ?page=0
     * &size=10
     * &requestType=ALL
     * &status=PENDING
     * &keyword=Nguyen
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getStaffRequests(
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

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("success", true);
        response.put(
                "message",
                "Staff requests loaded successfully.");
        response.put("data", data);

        return ResponseEntity.ok(response);
    }
}
