package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductAssignmentDTO {
    private Integer productNumber;
    private BigDecimal importPrice;
    private BigDecimal minimumOrderQuantity;
}
