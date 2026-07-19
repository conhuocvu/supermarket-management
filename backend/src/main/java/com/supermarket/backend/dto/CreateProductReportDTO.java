package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Request to file an inventory issue report from the Sales Associate workspace.
 * Persisted to product_reports with report_type = 'INVENTORY_ISSUE'.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateProductReportDTO {
    private Integer productNumber;
    private String issueType;
    private BigDecimal quantity;
    private String description;
}
