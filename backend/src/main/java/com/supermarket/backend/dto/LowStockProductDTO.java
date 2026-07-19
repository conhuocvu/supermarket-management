package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LowStockProductDTO {
    private Integer productNumber;
    private String productName;
    private String sku;
    private BigDecimal currentStock;
    private BigDecimal reorderLevel;
    private String unitName;
    private BigDecimal suggestedQuantity;
    private BigDecimal minOrderQuantity;
    private BigDecimal importPrice;
    private String suggestion;
    private boolean critical;
}
