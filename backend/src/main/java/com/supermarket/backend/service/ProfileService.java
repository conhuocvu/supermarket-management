package com.supermarket.backend.service;

import com.supermarket.backend.dto.ProfileDTO;
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

        String publicUrl = supabaseStorageService.uploadAvatar(userId, file);
        // Cache-bust so clients refresh the image even though the path is stable
        String versionedUrl = publicUrl + "?v=" + System.currentTimeMillis();

        profile.setAvatarUrl(versionedUrl);
        profileRepository.save(profile);

        return mapToDTO(profile);
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
