package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "product_suppliers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductSupplier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "product_supplier_number")
    private Integer productSupplierNumber;

    @Column(name = "product_number")
    private Integer productNumber;

    @Column(name = "supplier_number")
    private Integer supplierNumber;

    @Column(name = "import_price")
    private BigDecimal importPrice;

    @Column(name = "minimum_order_quantity")
    private BigDecimal minimumOrderQuantity;
}
