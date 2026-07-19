package com.supermarket.backend.controller;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.WorkScheduleDTO;
import com.supermarket.backend.service.WorkScheduleService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/work-schedules")
@RequiredArgsConstructor
public class WorkScheduleController {

    private final WorkScheduleService workScheduleService;

    /** Monthly assigned shifts for the Work Schedule calendar. */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<List<WorkScheduleDTO>>> getMonthlySchedule(
            @PathVariable UUID userId,
            @RequestParam int year,
            @RequestParam int month,
            HttpServletRequest request) {
        try {
            verifyOwnership(request, userId);
            if (month < 1 || month > 12) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("Month must be between 1 and 12."));
            }
            List<WorkScheduleDTO> schedule = workScheduleService.getMonthlySchedule(userId, year, month);
            return ResponseEntity.ok(ApiResponse.success("Work schedule retrieved successfully.", schedule));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load work schedule: " + e.getMessage()));
        }
    }

    /**
     * Verifies the JWT subject matches the target user (IDOR protection).
     * Decode only, no signature verification — same approach as AttendanceController.
     */
    private void verifyOwnership(HttpServletRequest request, UUID userId) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new SecurityException("Authentication required.");
        }
        try {
            String token = authHeader.substring(7);
            DecodedJWT decoded = JWT.decode(token);
            String sub = decoded.getSubject();
            if (sub == null || !sub.equals(userId.toString())) {
                throw new SecurityException("You are not authorised to access this schedule.");
            }
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("Invalid authentication token: " + e.getMessage());
        }
    }
}
