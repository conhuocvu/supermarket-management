package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestSaveDraftItemDTO {
    private Integer productNumber;
    private Integer supplierNumber;
    private BigDecimal requestedQuantity;
    private String reason;
    private String notes;
}
