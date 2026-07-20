package com.supermarket.backend.service;

import com.supermarket.backend.dto.ProfileDTO;
import com.supermarket.backend.dto.ProfileUpdateDTO;
import com.supermarket.backend.entity.Profile;
import com.supermarket.backend.repository.ProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ProfileServiceTests {

    @Mock
    private ProfileRepository profileRepository;

    @Mock
    private SupabaseStorageService supabaseStorageService;

    @InjectMocks
    private ProfileService profileService;

    private UUID userId;
    private Profile profile;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        profile = Profile.builder()
                .userId(userId)
                .roleNumber(1)
                .fullName("Nguyen Van A")
                .phone("0123456789")
                .status("ACTIVE")
                .createdAt(OffsetDateTime.now())
                .avatarUrl("http://supabase.com/avatar.png")
                .address("Hanoi")
                .build();
    }

    @Test
    void testViewProfile_ActiveAccount_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(profileRepository.findProfile(userId)).thenReturn(Optional.of(profile));
        when(profileRepository.getLastLogin(userId)).thenReturn(Instant.now());

        ProfileDTO dto = profileService.viewProfile(userId);

        assertNotNull(dto);
        assertEquals("Nguyen Van A", dto.getFullName());
        assertEquals("ACTIVE", dto.getStatus());
    }

    @Test
    void testViewProfile_InactiveAccount_ThrowsSecurityException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("INACTIVE");

        assertThrows(SecurityException.class, () -> profileService.viewProfile(userId));
    }

    @Test
    void testViewProfile_ProfileNotFound_ThrowsIllegalArgumentException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn(null);

        assertThrows(IllegalArgumentException.class, () -> profileService.viewProfile(userId));
    }

    @Test
    void testUpdateProfile_Success() {
        when(profileRepository.findById(userId)).thenReturn(Optional.of(profile));
        when(profileRepository.getLastLogin(userId)).thenReturn(Instant.now());

        ProfileUpdateDTO updateDTO = new ProfileUpdateDTO();
        updateDTO.setFullName("Updated Name ");
        updateDTO.setPhone("0987 654 321");
        updateDTO.setAddress("  Danang  ");

        ProfileDTO dto = profileService.updateProfile(userId, updateDTO);

        assertNotNull(dto);
        assertEquals("Updated Name", dto.getFullName());
        assertEquals("0987654321", dto.getPhone());
        assertEquals("Danang", dto.getAddress());
        verify(profileRepository, times(1)).save(profile);
    }

    @Test
    void testUpdateAvatar_Success() throws IOException {
        MockMultipartFile file = new MockMultipartFile(
                "file", "avatar.png", "image/png", new byte[100]);

        when(profileRepository.findById(userId)).thenReturn(Optional.of(profile));
        when(supabaseStorageService.uploadAvatar(eq(userId), any(MultipartFile.class)))
                .thenReturn("http://supabase.com/new-avatar.png");
        when(profileRepository.getLastLogin(userId)).thenReturn(Instant.now());

        ProfileDTO dto = profileService.updateAvatar(userId, file);

        assertNotNull(dto);
        assertTrue(dto.getAvatarUrl().contains("http://supabase.com/new-avatar.png"));
        assertEquals("http://supabase.com/new-avatar.png", profile.getAvatarUrl());
        verify(profileRepository, times(1)).save(profile);
    }

    @Test
    void testUpdateAvatar_InvalidType_ThrowsIllegalArgumentException() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "document.pdf", "application/pdf", new byte[100]);

        assertThrows(IllegalArgumentException.class, () -> profileService.updateAvatar(userId, file));
    }

    @Test
    void testUpdateAvatar_TooLarge_ThrowsIllegalArgumentException() {
        // Size = 3MB (limit is 2MB)
        MockMultipartFile file = new MockMultipartFile(
                "file", "avatar.png", "image/png", new byte[3 * 1024 * 1024]);

        assertThrows(IllegalArgumentException.class, () -> profileService.updateAvatar(userId, file));
    }

    @Test
    void testUpdateAvatar_EmptyFile_ThrowsIllegalArgumentException() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "avatar.png", "image/png", new byte[0]);

        assertThrows(IllegalArgumentException.class, () -> profileService.updateAvatar(userId, file));
    }
}
