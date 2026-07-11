package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompareQuantitiesRequestDTO {
    private Integer purchaseRequestNumber;
    private Map<Integer, BigDecimal> deliveredQuantities; // key: productNumber, value: quantity
}
