package com.supermarket.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DisposalRequestDTO {

    @NotNull(message = "Stock in detail number is required.")
    private Integer stockInDetailNumber;

    @NotNull(message = "Product number is required.")
    private Integer productNumber;

    @NotNull(message = "Disposal quantity is required.")
    @DecimalMin(value = "0.01", message = "Disposal quantity must be greater than zero.")
    private BigDecimal quantity;

    @NotBlank(message = "Disposal reason is required.")
    private String reason;

    private String observations;
}
