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
public class StockInItemDTO {
    private Integer productNumber;
    private String productName;
    private String sku; // barcode
    private BigDecimal requestedQuantity;
    private BigDecimal importPrice;
    private String unitName;
}
