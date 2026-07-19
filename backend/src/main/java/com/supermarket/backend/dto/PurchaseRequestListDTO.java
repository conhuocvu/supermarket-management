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
public class PurchaseRequestListDTO {
    private Integer purchaseRequestNumber;
    private String createdById;   // UUID of the creator — used for exact ownership checks
    private String createdBy;     // Display name of the creator
    private String status;
    private LocalDateTime createdDate;
    private String approvedBy;
    private LocalDateTime approvedDate;
    private String supplierName;
    private BigDecimal totalQuantity;
    private Integer totalItems;
}
