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
public class StockInDetailRequestDTO {
    private Integer productNumber;
    private BigDecimal deliveredQuantity;
    private BigDecimal importPrice;
    private LocalDate manufacturingDate;
    private LocalDate expiryDate;
    private String notes;
}
