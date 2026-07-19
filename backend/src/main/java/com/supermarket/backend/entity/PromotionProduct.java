package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "promotion_products")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PromotionProduct {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "promotion_product_number")
    private Integer promotionProductNumber;

    @Column(name = "promotion_number")
    private Integer promotionNumber;

    @Column(name = "product_number")
    private Integer productNumber;

    @Column(name = "stock_in_detail_number")
    private Integer stockInDetailNumber;

    @Column(name = "status")
    private String status;

    @Column(name = "product")
    private String product;
}
