package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierProductDTO {
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String categoryName;
    private String unitName;
    private BigDecimal stock;
    private BigDecimal sellingPrice;
    private String status;
    private String imageUrl;
    
    // Fields from ProductSupplier mapping
    private BigDecimal importPrice;
    private BigDecimal minimumOrderQuantity;
}
