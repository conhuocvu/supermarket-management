package com.supermarket.backend.dto;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductReportDTO {
    private Integer reportNumber;
    private UUID reportedBy;
    private String reporterName;
    private Integer productNumber;
    private String productName;
    private String barcode;
    private String categoryName;
    private Integer stockInDetailNumber;
    private String reportType;
    private String issueType;
    private BigDecimal quantity;
    private String unitName;
    private String description;
    private String status;
    private LocalDateTime createdAt;
    private UUID resolvedBy;
    private String resolverName;
    private LocalDateTime resolvedAt;
    private BigDecimal discountRate;
}
