package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PromotionCreateDto {

    @NotBlank(message = "Promotion name is required")
    private String name;

    @NotBlank(message = "Promotion code is required")
    private String code;

    private String description;

    @NotBlank(message = "Priority is required")
    private String priority; // LOW, MEDIUM, HIGH

    @NotBlank(message = "Discount type is required")
    private String discountType; // PERCENTAGE, FIXED_AMOUNT

    @NotNull(message = "Discount value is required")
    @PositiveOrZero(message = "Discount value must be zero or positive")
    private Double discountValue;

    private List<String> targetCategories;

    private List<String> targetProducts;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
    private LocalDate endDate;

    private String imageUrl;

    private String visibility; // e.g. Storewide & Online, Storewide, Online
}
