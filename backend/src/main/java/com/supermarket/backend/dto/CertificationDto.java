package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CertificationDto {
    private Long id;
    private String name;
    private LocalDate obtainedDate;
    private LocalDate expiryDate;
}
