package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryProductDTO {
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String categoryName;
    private String unitName;
    private BigDecimal stock;
    private BigDecimal sellingPrice;
    private BigDecimal reorderLevel;
    private String status;
    private String description;
    private String imageUrl;
    private Integer expiryWarningDays;
}
