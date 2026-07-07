package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "inventories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Inventory {

    @Id
    @Column(name = "product_number")
    private Integer productNumber;

    @OneToOne(fetch = FetchType.LAZY)
    @PrimaryKeyJoinColumn(name = "product_number", referencedColumnName = "product_number")
    private Product product;

    @Column(name = "total_quantity")
    private BigDecimal totalQuantity;

    @Column(name = "available_quantity")
    private BigDecimal availableQuantity;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;
}
