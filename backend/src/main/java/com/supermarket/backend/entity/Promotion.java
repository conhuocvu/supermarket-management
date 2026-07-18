package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

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
    @Column(name = "id")
    private Long id;

    @Column(name = "promotion_number", unique = true)
    private Integer promotionNumber;

    @Column(name = "promotion_name", nullable = false)
    private String promotionName;

    @Column(name = "discount_value")
    private Double discountValue;

    @Column(name = "status")
    private String status;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "description")
    private String description;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "visibility")
    private String visibility;

    @Column(name = "promo_code")
    private String promoCode;

    @Column(name = "category")
    private String category;

    @Column(name = "is_featured")
    private Boolean isFeatured;
}
