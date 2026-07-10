package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventoryTransactionDTO {
    private Integer transactionNumber;
    private Integer productNumber;
    private String productName;
    private String type;
    private BigDecimal quantity;
    private String unitName;
    private String referenceType;
    private Integer referenceId;
    private String reason;
    private String createdBy;
    private LocalDateTime createdAt;
}
