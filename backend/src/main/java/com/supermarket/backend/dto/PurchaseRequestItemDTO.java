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
public class PurchaseRequestItemDTO {
    private Integer productNumber;
    private String productName;
    private String sku;
    private BigDecimal requestedQuantity;
    private BigDecimal importPrice;
    private String unitName;
    private String supplierName;
    private String reason;
    private String notes;
    private BigDecimal currentStock;
    private BigDecimal reorderLevel;
}
