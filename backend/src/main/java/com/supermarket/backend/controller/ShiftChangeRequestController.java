package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ShiftChangeRequestDTO;
import com.supermarket.backend.service.ShiftChangeRequestService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/shift-change-requests")
@RequiredArgsConstructor
public class ShiftChangeRequestController {

    private final ShiftChangeRequestService shiftChangeRequestService;

    /** A user's own shift change requests. */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<List<ShiftChangeRequestDTO>>> getUserRequests(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            List<ShiftChangeRequestDTO> records = shiftChangeRequestService.getUserRequests(userId);
            return ResponseEntity.ok(ApiResponse.success("Shift change requests retrieved successfully.", records));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load shift change requests: " + e.getMessage()));
        }
    }

    /** Create a shift change request for the authenticated user. */
    @PostMapping
    public ResponseEntity<ApiResponse<ShiftChangeRequestDTO>> createRequest(
            @Valid @RequestBody ShiftChangeRequestDTO dto) {
        try {
            verifyOwnership(UUID.fromString(dto.getUserId()));
            ShiftChangeRequestDTO created = shiftChangeRequestService.createRequest(dto);
            return ResponseEntity.ok(ApiResponse.success("Shift change request submitted successfully.", created));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to create shift change request: " + e.getMessage()));
        }
    }

    /** Cancel a pending shift change request owned by the authenticated user. */
    @PutMapping("/{requestNumber}/cancel")
    public ResponseEntity<ApiResponse<ShiftChangeRequestDTO>> cancelRequest(
            @PathVariable Integer requestNumber,
            @RequestParam UUID userId) {
        try {
            verifyOwnership(userId);
            ShiftChangeRequestDTO cancelled = shiftChangeRequestService.cancelRequest(requestNumber, userId);
            return ResponseEntity.ok(ApiResponse.success("Shift change request cancelled successfully.", cancelled));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(409).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to cancel shift change request: " + e.getMessage()));
        }
    }

    /**
     * Verifies the JWT subject matches the target user (IDOR protection).
     * Retrieves the validated subject directly from Spring Security Context.
     */
    private void verifyOwnership(UUID userId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new SecurityException("Authentication required.");
        }
        String principalName = authentication.getName();
        if (principalName == null || !principalName.equals(userId.toString())) {
            throw new SecurityException("You are not authorised to access this request.");
        }
    }
}
