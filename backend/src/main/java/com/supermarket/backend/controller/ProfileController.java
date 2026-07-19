package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ProfileDTO;
import com.supermarket.backend.dto.ProfileUpdateDTO;
import com.supermarket.backend.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/profiles")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<ProfileDTO>> loadProfile(@PathVariable UUID userId) {
        try {
            ProfileDTO profile = profileService.viewProfile(userId);
            return ResponseEntity.ok(ApiResponse.success("Profile retrieved successfully.", profile));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Update editable profile fields (fullName, phone, address).
     * Returns the updated ProfileDTO so the client can refresh state in one round-trip.
     */
    @PutMapping("/{userId}")
    public ResponseEntity<ApiResponse<ProfileDTO>> updateProfile(
            @PathVariable UUID userId,
            @Valid @RequestBody ProfileUpdateDTO dto) {
        try {
            verifyOwnership(userId);
            ProfileDTO updated = profileService.updateProfile(userId, dto);
            return ResponseEntity.ok(ApiResponse.success("Profile updated successfully.", updated));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to update profile: " + e.getMessage()));
        }
    }

    @PutMapping("/{userId}/avatar")
    public ResponseEntity<ApiResponse<ProfileDTO>> updateAvatar(
            @PathVariable UUID userId,
            @RequestParam("file") MultipartFile file) {
        try {
            verifyOwnership(userId);
            ProfileDTO profile = profileService.updateAvatar(userId, file);
            return ResponseEntity.ok(ApiResponse.success("Profile photo updated successfully.", profile));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to update profile photo: " + e.getMessage()));
        }
    }

    /**
     * Verifies that the JWT belongs to the same user as the path variable (IDOR protection).
     * Retrieves the validated subject directly from Spring Security Context.
     */
    private void verifyOwnership(UUID userId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new SecurityException("Authentication required.");
        }
        String principalName = authentication.getName();
        if (principalName == null || !principalName.equals(userId.toString())) {
            throw new SecurityException("You are not authorised to modify this profile.");
        }
    }
}
