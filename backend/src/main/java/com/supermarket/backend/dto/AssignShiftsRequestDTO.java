package com.supermarket.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class AssignShiftsRequestDTO {
    /** List of daily shift assignments for the week */
    private List<DayShiftDTO> schedule;

    @Data
    public static class DayShiftDTO {
        private String workDate;     // yyyy-MM-dd
        private Integer shiftNumber; // null = day off
    }
}
