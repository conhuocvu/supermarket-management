package com.supermarket.backend.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeStatsDto {
    private int totalStaffCount;
    private int onShiftCount;
    private String staffCountGrowth; // e.g. "+3 this month"
}
