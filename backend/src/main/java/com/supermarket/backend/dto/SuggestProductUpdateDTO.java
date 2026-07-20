package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Request to suggest product parameter changes (price, name, etc.) from the
 * Sales Associate workspace. Persisted to product_reports with
 * report_type = 'UPDATE_SUGGESTION'; the suggested fields go into description
 * so no new columns are needed.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SuggestProductUpdateDTO {
    private Integer productNumber;
    private String suggestedName;
    private BigDecimal suggestedSellingPrice;
    private String reason;
}
