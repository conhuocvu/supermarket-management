package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductSupplierInfoDTO {
    private Integer supplierNumber;
    private String supplierName;
    private BigDecimal importPrice;
    private BigDecimal minimumOrderQuantity;
}
