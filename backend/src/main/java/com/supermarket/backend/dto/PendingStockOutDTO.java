package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PendingStockOutDTO {
    private Integer reportNumber;
    private String productName;
    private BigDecimal quantity;
    private String unitName;
    private String location;
    private LocalDateTime createdAt;
}
