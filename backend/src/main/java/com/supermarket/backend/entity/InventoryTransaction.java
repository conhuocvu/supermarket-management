package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "inventory_transactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventoryTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transaction_number")
    private Integer transactionNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_number", referencedColumnName = "product_number")
    private Product product;

    @Column(name = "stock_in_detail_number")
    private Integer stockInDetailNumber;

    @Column(name = "type")
    private String type;

    @Column(name = "quantity")
    private BigDecimal quantity;

    @Column(name = "reference_type")
    private String referenceType;

    @Column(name = "reference_id")
    private Integer referenceId;

    @Column(name = "reason")
    private String reason;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
