package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "stock_ins")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockIn {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stock_in_number")
    private Integer stockInNumber;

    @Column(name = "purchase_request_number")
    private Integer purchaseRequestNumber;

    @Column(name = "supplier_number")
    private Integer supplierNumber;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "stock_in_date")
    private LocalDateTime stockInDate;

    @Column(name = "status")
    private String status;
}
