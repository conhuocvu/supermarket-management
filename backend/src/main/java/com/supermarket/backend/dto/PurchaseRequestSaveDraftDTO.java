package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestSaveDraftDTO {
    private String userId;
    private LocalDate expectedDeliveryDate;
    private List<PurchaseRequestSaveDraftItemDTO> items;
}
