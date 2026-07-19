package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestDetailDTO {
    private Integer purchaseRequestNumber;
    private String createdBy;
    private LocalDateTime createdDate;
    private String approvedBy;
    private LocalDateTime approvedDate;
    private String status;
    private java.time.LocalDate expectedDeliveryDate;
    private List<PurchaseRequestItemDTO> items;
}
