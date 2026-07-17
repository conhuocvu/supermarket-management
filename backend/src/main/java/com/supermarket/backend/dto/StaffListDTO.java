package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StaffListDTO {
    private String userId;
    private String fullName;
    private String phone;
    private String avatarUrl;
    private String status;
    private Integer roleNumber;
    private String roleName;
    private String workStatus;     // ON_DUTY | OFF_DUTY | ON_LEAVE
    private String shiftName;
    private String shiftStartTime;
    private String shiftEndTime;
}
