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
public class StaffSummaryDTO {
    private long totalStaff;
    private long onShiftCount;
    private List<StaffListDTO> staff;
}
