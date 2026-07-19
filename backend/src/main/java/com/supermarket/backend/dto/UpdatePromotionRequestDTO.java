package com.supermarket.backend.dto;

import jakarta.validation.constraints.DecimalMin;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdatePromotionRequestDTO {

    private String promotionName;

    @DecimalMin(value = "0.01", message = "Discount value must be greater than zero.")
    private Double discountValue;

    private LocalDate startDate;

    private LocalDate endDate;

    private String status;

    private String promoCode;

    private String category;

    private String description;
}
