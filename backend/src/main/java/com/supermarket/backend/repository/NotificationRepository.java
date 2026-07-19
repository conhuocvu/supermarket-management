package com.supermarket.backend.repository;

import com.supermarket.backend.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {

    /** A user's notifications, newest first. */
    List<Notification> findByUserIdOrderByCreatedDateDesc(UUID userId);

    /** Number of unread notifications for the badge counter. */
    long countByUserIdAndIsReadFalse(UUID userId);

    /** Marks every unread notification of the user as read. Returns rows updated. */
    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true "
            + "WHERE n.userId = :userId AND n.isRead = false")
    int markAllRead(@Param("userId") UUID userId);
}
