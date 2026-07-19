package com.supermarket.backend.controller;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.LeaveRequestDTO;
import com.supermarket.backend.service.LeaveRequestService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/leave-requests")
@RequiredArgsConstructor
public class LeaveRequestController {

    private final LeaveRequestService leaveRequestService;

    /** A user's own leave requests. */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<List<LeaveRequestDTO>>> getUserLeaveRequests(
            @PathVariable UUID userId,
            HttpServletRequest request) {
        try {
            verifyOwnership(request, userId);
            List<LeaveRequestDTO> records = leaveRequestService.getUserLeaveRequests(userId);
            return ResponseEntity.ok(ApiResponse.success("Leave requests retrieved successfully.", records));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load leave requests: " + e.getMessage()));
        }
    }

    /** Create a leave request for the authenticated user. */
    @PostMapping
    public ResponseEntity<ApiResponse<LeaveRequestDTO>> createLeaveRequest(
            @Valid @RequestBody LeaveRequestDTO dto,
            HttpServletRequest request) {
        try {
            verifyOwnership(request, UUID.fromString(dto.getUserId()));
            LeaveRequestDTO created = leaveRequestService.createLeaveRequest(dto);
            return ResponseEntity.ok(ApiResponse.success("Leave request submitted successfully.", created));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to create leave request: " + e.getMessage()));
        }
    }

    /** Cancel a pending leave request owned by the authenticated user. */
    @PutMapping("/{leaveNumber}/cancel")
    public ResponseEntity<ApiResponse<LeaveRequestDTO>> cancelLeaveRequest(
            @PathVariable Integer leaveNumber,
            @RequestParam UUID userId,
            HttpServletRequest request) {
        try {
            verifyOwnership(request, userId);
            LeaveRequestDTO cancelled = leaveRequestService.cancelLeaveRequest(leaveNumber, userId);
            return ResponseEntity.ok(ApiResponse.success("Leave request cancelled successfully.", cancelled));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to cancel leave request: " + e.getMessage()));
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
                throw new SecurityException("You are not authorised to access this leave request.");
            }
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("Invalid authentication token: " + e.getMessage());
        }
    }
}
