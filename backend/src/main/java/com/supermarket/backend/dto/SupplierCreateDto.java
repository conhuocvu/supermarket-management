package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SupplierCreateDto {

    @NotBlank(message = "Supplier code is required")
    private String code;

    @NotBlank(message = "Supplier name is required")
    private String name;

    @NotBlank(message = "Category is required")
    private String category;

    private String nextDelivery;
    private String status;
    private String contactType;
    private String contactValue;
    private Double onTimeDeliveryRate;
    private Double averageRating;
    private String notes;
    private String certification;
}
