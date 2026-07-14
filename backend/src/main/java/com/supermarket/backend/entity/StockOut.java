package com.supermarket.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "stock_outs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockOut {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stock_out_number")
    private Integer stockOutNumber;

    @Column(name = "created_by")
    private UUID createdBy;

    @Column(name = "reason")
    private String reason;

    @Column(name = "created_date")
    private LocalDateTime createdDate;
}
