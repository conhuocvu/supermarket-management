package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.AttendanceDTO;
import com.supermarket.backend.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/attendance")
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    /**
     * Check-in: opens a new attendance record for the authenticated user.
     */
    @PostMapping("/{userId}/check-in")
    public ResponseEntity<ApiResponse<AttendanceDTO>> checkIn(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            AttendanceDTO record = attendanceService.checkIn(userId);
            return ResponseEntity.ok(ApiResponse.success("Checked in successfully.", record));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to check in: " + e.getMessage()));
        }
    }

    /**
     * Check-out: closes the authenticated user's open attendance record.
     */
    @PostMapping("/{userId}/check-out")
    public ResponseEntity<ApiResponse<AttendanceDTO>> checkOut(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            AttendanceDTO record = attendanceService.checkOut(userId);
            return ResponseEntity.ok(ApiResponse.success("Checked out successfully.", record));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to check out: " + e.getMessage()));
        }
    }

    /**
     * Current attendance state for today (open record, or latest closed one).
     * Returns data = null when the user has no record today.
     */
    @GetMapping("/{userId}/today")
    public ResponseEntity<ApiResponse<AttendanceDTO>> getTodayAttendance(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            AttendanceDTO record = attendanceService.getTodayAttendance(userId);
            return ResponseEntity.ok(ApiResponse.success("Attendance retrieved successfully.", record));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load attendance: " + e.getMessage()));
        }
    }

    /**
     * Monthly attendance history for the Work Schedule calendar.
     */
    @GetMapping("/{userId}/history")
    public ResponseEntity<ApiResponse<List<AttendanceDTO>>> getMonthlyAttendance(
            @PathVariable UUID userId,
            @RequestParam int year,
            @RequestParam int month) {
        try {
            verifyOwnership(userId);
            if (month < 1 || month > 12) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Month must be between 1 and 12."));
            }
            List<AttendanceDTO> records = attendanceService.getMonthlyAttendance(userId, year, month);
            return ResponseEntity.ok(ApiResponse.success("Attendance history retrieved successfully.", records));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load attendance history: " + e.getMessage()));
        }
    }

    /**
     * Verifies that the JWT in the Authorization header belongs to the same user as
     * the path variable, preventing accidental cross-user writes (IDOR).
     * Retrieves the validated subject directly from Spring Security Context.
     */
    private void verifyOwnership(UUID userId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new SecurityException("Authentication required.");
        }
        String principalName = authentication.getName();
        if (principalName == null || !principalName.equals(userId.toString())) {
            throw new SecurityException("You are not authorised to access this attendance record.");
        }
    }
}
