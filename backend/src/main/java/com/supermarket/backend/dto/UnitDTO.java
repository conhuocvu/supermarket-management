package com.supermarket.backend.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnitDTO {
    private Integer unitNumber;
    private String unitName;
}
