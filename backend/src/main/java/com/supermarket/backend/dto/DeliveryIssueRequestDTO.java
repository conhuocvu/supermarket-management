package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeliveryIssueRequestDTO {
    private Integer purchaseRequestNumber;
    private Integer productNumber;
    private String reportedBy; // UUID
    private String issueType; // SHORTAGE, OVER_DELIVERY, DAMAGED, OTHER
    private BigDecimal quantity;
    private String description;
}
