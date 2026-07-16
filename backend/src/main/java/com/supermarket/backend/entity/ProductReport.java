package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "product_reports")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "report_number")
    private Integer reportNumber;

    @Column(name = "reported_by")
    private UUID reportedBy;

    @Column(name = "product_number")
    private Integer productNumber;

    @Column(name = "stock_in_detail_number")
    private Integer stockInDetailNumber;

    @Column(name = "report_type")
    private String reportType;

    @Column(name = "issue_type")
    private String issueType;

    @Column(name = "quantity")
    private BigDecimal quantity;

    @Column(name = "description")
    private String description;

    @Column(name = "status")
    private String status;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "resolved_by")
    private UUID resolvedBy;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;
}
