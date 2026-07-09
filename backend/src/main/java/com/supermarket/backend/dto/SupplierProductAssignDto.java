package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SupplierProductAssignDto {

    @NotNull(message = "Product ID is required")
    private Long productId;

    @NotNull(message = "Import price is required")
    private Double importPrice;
}
