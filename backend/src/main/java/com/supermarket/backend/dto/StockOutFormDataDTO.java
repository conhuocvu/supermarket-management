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
public class StockOutFormDataDTO {
    private Integer reportNumber;
    private Integer productNumber;
    private String productName;
    private String sku;
    private BigDecimal quantity; // reported quantity
    private String unitName;
    private String location;
    private String description; // original report description
    private String reportType;
    private String issueType;
    private BigDecimal availableQuantity; // current available stock in inventories
}
