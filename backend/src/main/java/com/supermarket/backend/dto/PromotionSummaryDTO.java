package com.supermarket.backend.dto;

import lombok.*;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromotionSummaryDTO {
    private List<PromotionDTO> promotions;
    private long activeCount;
    private long scheduledCount;
    private long expiredCount;
    private double avgDiscount;
    private int currentPage;
    private int totalPages;
    private long totalElements;
}
