package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Maps the notifications table (Feature 5.1 - View Notifications).
 * Columns: notification_number, user_id, title, content, is_read, created_date.
 */
@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notification_number")
    private Integer notificationNumber;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "title")
    private String title;

    @Column(name = "content")
    private String content;

    @Column(name = "is_read")
    private Boolean isRead;

    @Column(name = "created_date")
    private LocalDateTime createdDate;
}
