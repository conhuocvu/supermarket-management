package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProfileDTO {
    private String userId;
    private Integer roleNumber;
    private String fullName;
    private String phone;
    private String status;
    private OffsetDateTime createdAt;
    private String avatarUrl;
    private String address;
    private OffsetDateTime lastLogin;
}

