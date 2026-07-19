package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExpiringProductDTO {
    private Integer stockInDetailNumber;
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String batchNumber;
    private BigDecimal quantity;
    private LocalDate expiryDate;
    private Long daysRemaining;
    private boolean critical;
    private Integer expiryWarningDays;
    private BigDecimal importPrice;
}
