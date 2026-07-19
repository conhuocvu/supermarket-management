package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.service.StaffRequestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
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
}