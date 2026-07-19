package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Read model for a product report shown in the Sales Associate report-status
 * and problem-product-details screens.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductReportDTO {
    private Integer reportNumber;
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String reportType;
    private String issueType;
    private BigDecimal quantity;
    private String description;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime resolvedAt;
}
