package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DisposalFormDataDTO {
    private Integer stockInDetailNumber;
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String batchNumber;
    private LocalDate expiryDate;
    private BigDecimal remainingQuantity;
    private String unitName;
    private BigDecimal importPrice;
    private BigDecimal sellingPrice;
}
