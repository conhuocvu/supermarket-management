package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductAdjustmentRequestDTO {
    private String adjustmentType; // "INCREASE" or "DECREASE"
    private BigDecimal quantity;
    private String reason;
}
