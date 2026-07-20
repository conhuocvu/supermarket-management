package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestAdjustDTO {
    private LocalDate expectedDeliveryDate;
    private String status;
    private List<PurchaseRequestAdjustItemDTO> items;
}
