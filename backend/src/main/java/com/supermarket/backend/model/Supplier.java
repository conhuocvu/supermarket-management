package com.supermarket.backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "suppliers_v2")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Supplier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String category; // e.g., FRESH PRODUCE, DAIRY & COLD, DRY GOODS, ORGANIC

    private String nextDelivery; // e.g., Thursday, 06:00 AM

    @Column(nullable = false)
    private String status; // e.g., Reliable, Warning, Deactivated

    private String contactType; // e.g., email, phone
    private String contactValue;

    private Double onTimeDeliveryRate;
    private Double averageRating;

    @Column(length = 1000)
    private String notes;

    private String certification; // e.g., Certified Organic
}
