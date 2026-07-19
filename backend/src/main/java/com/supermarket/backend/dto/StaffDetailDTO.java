package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StaffDetailDTO {
    // Profile
    private String userId;
    private String fullName;
    private String phone;
    private String avatarUrl;
    private String address;
    private String status;
    private String createdAt;

    // Role
    private Integer roleNumber;
    private String roleName;

    // Today's shift
    private String workStatus;       // ON_DUTY | OFF_DUTY | ON_LEAVE
    private String shiftName;
    private String shiftStartTime;
    private String shiftEndTime;

    // Weekly schedule (7 days)
    private List<WeeklyShiftDTO> weeklySchedule;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WeeklyShiftDTO {
        private String workDate;        // yyyy-MM-dd
        private String dayOfWeek;       // Monday, Tuesday, ...
        private Integer shiftNumber;
        private String shiftName;
        private String shiftStartTime;
        private String shiftEndTime;
    }
}
