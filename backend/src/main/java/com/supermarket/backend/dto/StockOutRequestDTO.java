package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockOutRequestDTO {
    private Integer reportNumber;
    private BigDecimal quantity; // transfer quantity
    private String reason; // transfer reason
    private String notes; // message/description
    private String createdBy; // UUID of stock controller (optional)
}
