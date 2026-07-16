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
public class CompareQuantitiesResultDTO {
    private boolean hasDiscrepancy;
    private Map<Integer, BigDecimal> differences; // key: productNumber, value: requested - delivered
    private boolean matched;
}
