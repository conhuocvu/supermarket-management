package com.supermarket.backend.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SupplierDto {
    private Long id;
    private String code;
    private String name;
    private String category;
    private String nextDelivery;
    private String status;
    private String contactType;
    private String contactValue;
    private Double onTimeDeliveryRate;
    private Double averageRating;
    private String notes;
    private String certification;
    private Integer activeSkus;
}
