package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductAdjustmentDTO {
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String unitName;
    private BigDecimal availableQuantity;
}
