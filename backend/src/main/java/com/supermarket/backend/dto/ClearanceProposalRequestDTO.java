package com.supermarket.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClearanceProposalRequestDTO {

    @NotNull(message = "Stock in detail number is required.")
    private Integer stockInDetailNumber;

    @NotNull(message = "Product number is required.")
    private Integer productNumber;

    @NotNull(message = "Discount percentage is required.")
    @Min(value = 1, message = "Discount percentage must be at least 1%.")
    @Max(value = 100, message = "Discount percentage must not exceed 100%.")
    private Double discountPercentage;

    private String reason;
}
