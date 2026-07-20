package com.supermarket.backend.service;

import com.supermarket.backend.dto.NotificationDTO;
import com.supermarket.backend.entity.Notification;
import com.supermarket.backend.repository.NotificationRepository;
import com.supermarket.backend.repository.ProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class NotificationServiceTests {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private ProfileRepository profileRepository;

    @Spy
    private Clock clock = Clock.fixed(Instant.parse("2026-07-20T10:00:00Z"), ZoneId.of("UTC"));

    @InjectMocks
    private NotificationService notificationService;

    private UUID userId;
    private Notification notification;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        notification = Notification.builder()
                .notificationNumber(10)
                .userId(userId)
                .title("Shift Assigned")
                .content("You have been assigned to morning shift.")
                .isRead(false)
                .createdDate(LocalDateTime.now(clock))
                .build();
    }

    @Test
    void testGetUserNotifications_ActiveAccount_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(notificationRepository.findByUserIdOrderByCreatedDateDesc(userId))
                .thenReturn(Collections.singletonList(notification));

        List<NotificationDTO> list = notificationService.getUserNotifications(userId);

        assertNotNull(list);
        assertEquals(1, list.size());
        assertEquals("Shift Assigned", list.get(0).getTitle());
        assertEquals(userId.toString(), list.get(0).getUserId());
    }

    @Test
    void testGetUserNotifications_InactiveAccount_ThrowsSecurityException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("INACTIVE");

        assertThrows(SecurityException.class, () -> notificationService.getUserNotifications(userId));
    }

    @Test
    void testGetUserNotifications_ProfileNotFound_ThrowsIllegalArgumentException() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn(null);

        assertThrows(IllegalArgumentException.class, () -> notificationService.getUserNotifications(userId));
    }

    @Test
    void testGetUnreadCount_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(notificationRepository.countByUserIdAndIsReadFalse(userId)).thenReturn(5L);

        long count = notificationService.getUnreadCount(userId);

        assertEquals(5L, count);
    }

    @Test
    void testMarkAsRead_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(notificationRepository.findById(10)).thenReturn(Optional.of(notification));

        NotificationDTO result = notificationService.markAsRead(10, userId);

        assertNotNull(result);
        assertTrue(result.getIsRead());
        verify(notificationRepository, times(1)).save(notification);
    }

    @Test
    void testMarkAsRead_NotOwner_ThrowsSecurityException() {
        when(notificationRepository.findById(10)).thenReturn(Optional.of(notification));

        UUID anotherUser = UUID.randomUUID();
        when(profileRepository.checkAccountStatus(anotherUser)).thenReturn("ACTIVE");

        assertThrows(SecurityException.class, () -> notificationService.markAsRead(10, anotherUser));
        verify(notificationRepository, never()).save(any(Notification.class));
    }

    @Test
    void testMarkAllAsRead_Success() {
        when(profileRepository.checkAccountStatus(userId)).thenReturn("ACTIVE");
        when(notificationRepository.markAllRead(userId)).thenReturn(3);

        int count = notificationService.markAllAsRead(userId);

        assertEquals(3, count);
    }

    @Test
    void testCreateNotification_Success() {
        when(notificationRepository.save(any(Notification.class))).thenAnswer(invocation -> invocation.getArgument(0));

        NotificationDTO result = notificationService.createNotification(userId, "System Warning", "Disk space is low.");

        assertNotNull(result);
        assertEquals("System Warning", result.getTitle());
        assertEquals("Disk space is low.", result.getContent());
        assertFalse(result.getIsRead());
        assertEquals(LocalDateTime.now(clock), result.getCreatedDate());
    }
}
