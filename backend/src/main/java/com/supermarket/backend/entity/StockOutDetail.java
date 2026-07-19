package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "stock_out_details")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockOutDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stock_out_detail_number")
    private Integer stockOutDetailNumber;

    @Column(name = "stock_out_number")
    private Integer stockOutNumber;

    @Column(name = "stock_in_detail_number")
    private Integer stockInDetailNumber;

    @Column(name = "product_number")
    private Integer productNumber;

    @Column(name = "quantity")
    private BigDecimal quantity;
}
