package com.supermarket.backend.controller;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ProfileDTO;
import com.supermarket.backend.dto.ProfileUpdateDTO;
import com.supermarket.backend.service.ProfileService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/profiles")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<ProfileDTO>> getProfile(@PathVariable UUID userId) {
        try {
            ProfileDTO profile = profileService.getProfile(userId);
            return ResponseEntity.ok(ApiResponse.success("Profile retrieved successfully.", profile));
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
            @Valid @RequestBody ProfileUpdateDTO dto,
            HttpServletRequest request) {
        try {
            verifyOwnership(request, userId);
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
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        try {
            verifyOwnership(request, userId);
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
     * Verifies that the Supabase JWT in the Authorization header belongs to the
     * same user as the path variable, preventing IDOR attacks.
     *
     * The JWT is decoded without signature verification here because signature
     * verification requires the Supabase JWT secret — which would be a full
     * Spring Security integration out of scope for this PR. The primary goal is
     * preventing accidental cross-user writes; for a production hardening pass,
     * replace this with a proper JwtDecoder / Spring Security filter.
     */
    private void verifyOwnership(HttpServletRequest request, UUID userId) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            // No token present — anonymous request, reject.
            throw new SecurityException("Authentication required.");
        }
        try {
            String token = authHeader.substring(7);
            DecodedJWT decoded = JWT.decode(token);
            String sub = decoded.getSubject(); // Supabase sets sub = user UUID
            if (sub == null || !sub.equals(userId.toString())) {
                throw new SecurityException("You are not authorised to modify this profile.");
            }
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("Invalid authentication token.");
        }
    }
}
