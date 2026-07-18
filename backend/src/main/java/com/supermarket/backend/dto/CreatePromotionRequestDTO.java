package com.supermarket.backend.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreatePromotionRequestDTO {

    @NotBlank(message = "Promotion name is required.")
    private String promotionName;

    @NotNull(message = "Discount value is required.")
    @DecimalMin(value = "0.01", message = "Discount value must be greater than zero.")
    private Double discountValue;

    @NotNull(message = "Start date is required.")
    private LocalDate startDate;

    @NotNull(message = "End date is required.")
    private LocalDate endDate;

    private String status = "ACTIVE";

    private String promoCode;

    private String category;

    private String description;
}
