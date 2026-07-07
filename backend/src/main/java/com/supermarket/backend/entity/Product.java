package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "products")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "product_number")
    private Integer productNumber;

    @Column(name = "category_number")
    private Integer categoryNumber;

    @Column(name = "inventory_unit_number")
    private Integer inventoryUnitNumber;

    @Column(name = "product_name")
    private String productName;

    @Column(name = "barcode")
    private String barcode;

    @Column(name = "selling_price")
    private BigDecimal sellingPrice;

    @Column(name = "reorder_level")
    private BigDecimal reorderLevel;

    @Column(name = "status")
    private String status;

    @Column(name = "description")
    private String description;

    @Column(name = "image_url")
    private String imageUrl;
}
