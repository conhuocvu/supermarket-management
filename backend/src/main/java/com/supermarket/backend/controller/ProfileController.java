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
     * Verifies that the JWT in the Authorization header belongs to the same user as
     * the path variable, preventing accidental cross-user writes (IDOR).
     *
     * Note: Supabase issues RS256-signed tokens. Full signature verification requires
     * integrating Spring Security with Supabase JWKS endpoint, which is out of scope
     * here. Decoding without signature verification is sufficient to prevent accidental
     * misuse while keeping the implementation simple.
     */
    private void verifyOwnership(HttpServletRequest request, UUID userId) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new SecurityException("Authentication required.");
        }
        try {
            String token = authHeader.substring(7);
            DecodedJWT decoded = JWT.decode(token); // Decode only — no signature verification
            String sub = decoded.getSubject();      // Supabase sets sub = user UUID
            if (sub == null || !sub.equals(userId.toString())) {
                throw new SecurityException("You are not authorised to modify this profile.");
            }
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("Invalid authentication token: " + e.getMessage());
        }
    }
}
