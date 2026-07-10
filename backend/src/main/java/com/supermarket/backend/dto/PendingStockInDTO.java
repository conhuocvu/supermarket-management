package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingStockInDTO {
    private Integer purchaseRequestNumber;
    private LocalDateTime createdDate;
    private String supplierName;
    private BigDecimal totalItems;
    private String unitName;
    private String status;
}
