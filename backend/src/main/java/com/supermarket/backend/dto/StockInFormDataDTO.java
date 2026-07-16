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
public class StockInFormDataDTO {
    private Integer purchaseRequestNumber;
    private String supplierName;
    private Integer supplierNumber;
    private LocalDateTime createdDate;
    private String status;
    private List<StockInItemDTO> items;
}
