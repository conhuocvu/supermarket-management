package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {
    private Integer notificationNumber;
    private String userId;
    private String title;
    private String content;
    private Boolean isRead;
    private LocalDateTime createdDate;
}
