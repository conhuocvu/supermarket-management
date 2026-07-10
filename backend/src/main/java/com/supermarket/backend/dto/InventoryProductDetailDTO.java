package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryProductDetailDTO {
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
    private LocalDate expiryDate;

    // Supplier Info
    private Integer supplierNumber;
    private String supplierName;
    private BigDecimal importPrice;
    private BigDecimal minimumOrderQuantity;

    // Stock History
    private List<StockHistoryDTO> stockHistory;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StockHistoryDTO {
        private String date;
        private String action;
        private BigDecimal quantity;
    }
}
