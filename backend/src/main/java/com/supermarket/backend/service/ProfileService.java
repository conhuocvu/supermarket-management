package com.supermarket.backend.service;

import com.supermarket.backend.dto.ProfileDTO;
import com.supermarket.backend.dto.ProfileUpdateDTO;
import com.supermarket.backend.entity.Profile;
import com.supermarket.backend.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProfileService {

    // Keep in sync with the avatars bucket limits and the Flutter client
    // (frontend/lib/screens/profile_screen.dart)
    private static final long MAX_AVATAR_BYTES = 2 * 1024 * 1024;
    private static final Set<String> ALLOWED_AVATAR_TYPES =
            Set.of("image/jpeg", "image/png", "image/webp");

    private final ProfileRepository profileRepository;
    private final SupabaseStorageService supabaseStorageService;

    public ProfileDTO getProfile(UUID userId) {
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Profile not found"));
        return mapToDTO(profile);
    }

    /**
     * Updates editable profile fields (fullName, phone, address).
     * Returns the updated ProfileDTO so the caller can update state directly
     * without an extra round-trip fetch.
     */
    @Transactional
    public ProfileDTO updateProfile(UUID userId, ProfileUpdateDTO dto) {
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Profile not found"));

        profile.setFullName(dto.getFullName().trim());
        profile.setPhone(dto.getPhone().replaceAll("[\\s\\-]", ""));
        // Treat blank address as null (optional field)
        String address = dto.getAddress();
        profile.setAddress(address != null && !address.isBlank() ? address.trim() : null);

        profileRepository.save(profile);
        return mapToDTO(profile);
    }

    @Transactional
    public ProfileDTO updateAvatar(UUID userId, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("No file was provided.");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_AVATAR_TYPES.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException("Only JPG, PNG or WebP images are allowed.");
        }
        if (file.getSize() > MAX_AVATAR_BYTES) {
            throw new IllegalArgumentException("Image is too large. Maximum size is 2MB.");
        }

        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Profile not found"));

        // Store the clean public URL — no version query parameter.
        // Cache-busting (?v=timestamp) is applied client-side only during the
        // immediate update so the browser/Flutter image cache is invalidated.
        String publicUrl = supabaseStorageService.uploadAvatar(userId, file);
        profile.setAvatarUrl(publicUrl);
        profileRepository.save(profile);

        // Return a versioned URL for the current response so the client can
        // display the new image immediately without an extra fetch.
        ProfileDTO dto = mapToDTO(profile);
        dto.setAvatarUrl(publicUrl + "?v=" + System.currentTimeMillis());
        return dto;
    }

    private ProfileDTO mapToDTO(Profile profile) {
        return ProfileDTO.builder()
                .userId(profile.getUserId().toString())
                .roleNumber(profile.getRoleNumber())
                .fullName(profile.getFullName())
                .phone(profile.getPhone())
                .status(profile.getStatus())
                .createdAt(profile.getCreatedAt())
                .avatarUrl(profile.getAvatarUrl())
                .address(profile.getAddress())
                .build();
    }
}
