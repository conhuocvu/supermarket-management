package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.ProfileDTO;
import com.supermarket.backend.service.ProfileService;
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

    @PutMapping("/{userId}/avatar")
    public ResponseEntity<ApiResponse<ProfileDTO>> updateAvatar(
            @PathVariable UUID userId,
            @RequestParam("file") MultipartFile file) {
        try {
            ProfileDTO profile = profileService.updateAvatar(userId, file);
            return ResponseEntity.ok(ApiResponse.success("Profile photo updated successfully.", profile));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to update profile photo: " + e.getMessage()));
        }
    }
}
