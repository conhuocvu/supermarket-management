package com.supermarket.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "employees")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, unique = true)
    private String email;

    private String phone;

    private String location;

    private LocalDate joinedDate;

    private String role; // e.g., MANAGER, CASHIER, INVENTORY_STAFF, SALES_ASSOCIATE

    private String status; // e.g., ON_DUTY, OFF_DUTY, ON_LEAVE

    private Double attendanceRate; // e.g., 98.0

    private Integer completedShifts; // e.g., 124

    private Double performanceScore; // e.g., 4.8

    @Column(length = 1000)
    private String managersNote;

    private LocalDate returnsDate; // For employees on leave

    private String imageUrl;
}
