package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "suppliers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Supplier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "supplier_number")
    private Integer supplierNumber;

    @Column(name = "supplier_name")
    private String supplierName;

    @Column(name = "phone")
    private String phone;

    @Column(name = "email")
    private String email;

    @Column(name = "status")
    private String status;

    @Column(name = "contact_person")
    private String contactPerson;

    @Column(name = "address")
    private String address;

    @Column(name = "category")
    private String category;

    @Column(name = "notes")
    private String notes;
}
