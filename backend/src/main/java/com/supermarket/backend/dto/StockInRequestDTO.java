package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockInRequestDTO {
    private Integer purchaseRequestNumber;
    private Integer supplierNumber;
    private String createdBy; // UUID string
    private List<StockInDetailRequestDTO> items;
}
