package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.NotificationDTO;
import com.supermarket.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    /** A user's notifications, newest first. */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<List<NotificationDTO>>> getUserNotifications(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            List<NotificationDTO> records = notificationService.getUserNotifications(userId);
            return ResponseEntity.ok(ApiResponse.success("Notifications retrieved successfully.", records));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load notifications: " + e.getMessage()));
        }
    }

    /** Number of unread notifications, for badge counters. */
    @GetMapping("/{userId}/unread-count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            long count = notificationService.getUnreadCount(userId);
            return ResponseEntity.ok(
                    ApiResponse.success("Unread count retrieved successfully.", Map.of("count", count)));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load unread count: " + e.getMessage()));
        }
    }

    /** Marks a single notification as read (owner only). */
    @PutMapping("/{notificationNumber}/read")
    public ResponseEntity<ApiResponse<NotificationDTO>> markAsRead(
            @PathVariable Integer notificationNumber,
            @RequestParam UUID userId) {
        try {
            verifyOwnership(userId);
            NotificationDTO updated = notificationService.markAsRead(notificationNumber, userId);
            return ResponseEntity.ok(ApiResponse.success("Notification marked as read.", updated));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to mark notification as read: " + e.getMessage()));
        }
    }

    /** Marks all of the user's notifications as read. */
    @PutMapping("/{userId}/read-all")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> markAllAsRead(
            @PathVariable UUID userId) {
        try {
            verifyOwnership(userId);
            int updated = notificationService.markAllAsRead(userId);
            return ResponseEntity.ok(
                    ApiResponse.success("All notifications marked as read.", Map.of("updated", updated)));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to mark notifications as read: " + e.getMessage()));
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
            throw new SecurityException("You are not authorised to access these notifications.");
        }
    }
}
