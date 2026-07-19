package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestFormProductDTO {
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String unitName;
    private BigDecimal currentStock;
    private BigDecimal reorderLevel;
    private List<ProductSupplierInfoDTO> suppliers;
}
