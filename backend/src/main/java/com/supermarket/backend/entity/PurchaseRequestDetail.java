package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "purchase_request_details")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PurchaseRequestDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "purchase_request_detail_number")
    private Integer purchaseRequestDetailNumber;

    @Column(name = "purchase_request_number")
    private Integer purchaseRequestNumber;

    @Column(name = "product_supplier_number")
    private Integer productSupplierNumber;

    @Column(name = "requested_quantity")
    private BigDecimal requestedQuantity;
}
