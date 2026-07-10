package com.supermarket.backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity(name = "SupplierFeatureProduct")
@Table(name = "products_v2")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String sku;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String category; // e.g., Produce, Dairy, Bakery

    @Column(nullable = false)
    private Double basePrice;

    @Column(nullable = false)
    private String unit; // e.g., lb, unit, box

    private String imageUrl;
}
