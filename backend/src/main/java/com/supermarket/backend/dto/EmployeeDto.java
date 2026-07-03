package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeDto {
    private Long id;
    private String employeeCode; // Format: EMP-XXX (e.g., EMP-042)
    private String name;
    private String email;
    private String phone;
    private String location;
    private LocalDate joinedDate;
    private String role;
    private String status;
    private Double attendanceRate;
    private Integer completedShifts;
    private Double performanceScore;
    private String managersNote;
    private LocalDate returnsDate;
    private String imageUrl;
    private List<ShiftDto> recentShifts;
    private List<CertificationDto> certifications;
}
