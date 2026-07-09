package com.supermarket.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Entity
@Table(name = "promotions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Promotion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false)
    private String priority; // LOW, MEDIUM, HIGH

    @Column(nullable = false)
    private String discountType; // PERCENTAGE, FIXED_AMOUNT

    @Column(nullable = false)
    private Double discountValue;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "promotion_categories", joinColumns = @JoinColumn(name = "promotion_id"))
    @Column(name = "category")
    private List<String> targetCategories;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "promotion_products", joinColumns = @JoinColumn(name = "promotion_id"))
    @Column(name = "product")
    private List<String> targetProducts;

    @Column(nullable = false)
    private LocalDate startDate;

    @Column(nullable = false)
    private LocalDate endDate;

    private String imageUrl;

    private String visibility; // e.g. Storewide & Online, Storewide, Online
}
