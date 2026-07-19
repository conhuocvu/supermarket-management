package com.supermarket.backend.service;

import com.supermarket.backend.dto.NotificationDTO;
import com.supermarket.backend.entity.Notification;
import com.supermarket.backend.repository.NotificationRepository;
import com.supermarket.backend.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final ProfileRepository profileRepository;
    private final Clock clock;

    /** A user's notifications, newest first. */
    public List<NotificationDTO> getUserNotifications(UUID userId) {
        verifyActiveAccount(userId);
        return notificationRepository.findByUserIdOrderByCreatedDateDesc(userId)
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    /** Number of unread notifications (for badges). */
    public long getUnreadCount(UUID userId) {
        verifyActiveAccount(userId);
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    /** Marks a single notification as read. Only the owner may do this. */
    @Transactional
    public NotificationDTO markAsRead(Integer notificationNumber, UUID userId) {
        verifyActiveAccount(userId);

        Notification record = notificationRepository.findById(notificationNumber)
                .orElseThrow(() -> new IllegalArgumentException("Notification not found."));

        if (!userId.equals(record.getUserId())) {
            throw new SecurityException("You are not authorised to update this notification.");
        }

        if (!Boolean.TRUE.equals(record.getIsRead())) {
            record.setIsRead(true);
            notificationRepository.save(record);
        }
        return mapToDTO(record);
    }

    /** Marks all of the user's unread notifications as read. */
    @Transactional
    public int markAllAsRead(UUID userId) {
        verifyActiveAccount(userId);
        return notificationRepository.markAllRead(userId);
    }

    /**
     * Creates a notification for a user. Called by other services (leave requests,
     * shift changes, ...) — not exposed as a public API endpoint.
     */
    @Transactional
    public NotificationDTO createNotification(UUID userId, String title, String content) {
        Notification record = Notification.builder()
                .userId(userId)
                .title(title)
                .content(content)
                .isRead(false)
                .createdDate(LocalDateTime.now(clock))
                .build();
        notificationRepository.save(record);
        return mapToDTO(record);
    }

    private void verifyActiveAccount(UUID userId) {
        String status = profileRepository.checkAccountStatus(userId);
        if (status == null) {
            throw new IllegalArgumentException("Profile not found");
        }
        if (!"ACTIVE".equalsIgnoreCase(status)) {
            throw new SecurityException("Account inactive");
        }
    }

    private NotificationDTO mapToDTO(Notification n) {
        return NotificationDTO.builder()
                .notificationNumber(n.getNotificationNumber())
                .userId(n.getUserId().toString())
                .title(n.getTitle())
                .content(n.getContent())
                .isRead(n.getIsRead())
                .createdDate(n.getCreatedDate())
                .build();
    }
}
