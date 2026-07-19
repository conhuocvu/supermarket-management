package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromotionDetailDTO {
    private Integer promotionNumber;
    private String promotionName;
    private Double discountValue;
    private String status;
    private LocalDate startDate;
    private LocalDate endDate;
    private String promoCode;
    private String description;
    
    private List<ProductDTO> products;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProductDTO {
        private String productName;
        private String barcode;
        private java.math.BigDecimal sellingPrice;
    }
}
