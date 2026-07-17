package com.supermarket.backend.controller;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/staff")
@RequiredArgsConstructor
public class StaffController {

    private final StaffService staffService;

    /**
     * GET /api/staff
     *
     * Query params:
     *   keyword   - optional: search by full name or phone
     *   status    - optional: ALL | ON_DUTY | OFF_DUTY | ON_LEAVE (default ALL)
     */
    @GetMapping
    public ResponseEntity<ApiResponse<StaffSummaryDTO>> getStaff(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status", required = false, defaultValue = "ALL") String status) {

        try {
            StaffSummaryDTO data = staffService.getStaffList(keyword, status);
            return ResponseEntity.ok(ApiResponse.success("Staff list loaded successfully.", data));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load staff list: " + e.getMessage()));
        }
    }

    /**
     * GET /api/staff/{userId}  — UC-ST-02 View Staff Details
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<StaffDetailDTO>> getStaffDetail(@PathVariable String userId) {
        try {
            StaffDetailDTO data = staffService.getStaffDetail(userId);
            return ResponseEntity.ok(ApiResponse.success("Staff detail loaded.", data));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load staff detail: " + e.getMessage()));
        }
    }

    /**
     * PUT /api/staff/{userId}/role  — UC-ST-03 Set Role
     */
    @PutMapping("/{userId}/role")
    public ResponseEntity<ApiResponse<Void>> setRole(
            @PathVariable String userId,
            @RequestBody SetRoleRequestDTO request) {
        try {
            if (request.getRoleNumber() == null) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Please select a new role."));
            }
            staffService.setStaffRole(userId, request.getRoleNumber());
            return ResponseEntity.ok(ApiResponse.success("Staff role updated successfully.", null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to update staff role."));
        }
    }

    /**
     * POST /api/staff/{userId}/shifts  — UC-ST-04 Assign Employee Shifts
     */
    @PostMapping("/{userId}/shifts")
    public ResponseEntity<ApiResponse<Void>> assignShifts(
            @PathVariable String userId,
            @RequestBody AssignShiftsRequestDTO request) {
        try {
            staffService.assignShifts(userId, request);
            return ResponseEntity.ok(ApiResponse.success("Shift assignment saved successfully.", null));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to save shift assignment."));
        }
    }

    /**
     * GET /api/staff/meta/roles  — Fetch all available roles
     */
    @GetMapping("/meta/roles")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getRoles() {
        try {
            List<Object[]> rows = staffService.getRoles();
            List<Map<String, Object>> data = rows.stream().map(r -> Map.<String, Object>of(
                    "roleNumber", r[0],
                    "roleName", r[1],
                    "description", r[2] != null ? r[2] : ""
            )).collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success("Roles loaded.", data));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load roles."));
        }
    }

    /**
     * GET /api/staff/meta/shifts  — Fetch all available shifts
     */
    @GetMapping("/meta/shifts")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getShifts() {
        try {
            List<Object[]> rows = staffService.getShifts();
            List<Map<String, Object>> data = rows.stream().map(r -> Map.<String, Object>of(
                    "shiftNumber", r[0],
                    "shiftName", r[1],
                    "startTime", r[2] != null ? r[2] : "",
                    "endTime", r[3] != null ? r[3] : ""
            )).collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success("Shifts loaded.", data));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load shifts."));
        }
    }
}
