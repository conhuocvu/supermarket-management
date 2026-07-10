package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "stock_in_details")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockInDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stock_in_detail_number")
    private Integer stockInDetailNumber;

    @Column(name = "stock_in_number")
    private Integer stockInNumber;

    @Column(name = "product_number")
    private Integer productNumber;

    @Column(name = "batch_number")
    private String batchNumber;

    @Column(name = "quantity")
    private BigDecimal quantity;

    @Column(name = "remaining_quantity")
    private BigDecimal remainingQuantity;

    @Column(name = "import_price")
    private BigDecimal importPrice;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Column(name = "manufacturing_date")
    private LocalDate manufacturingDate;
}
