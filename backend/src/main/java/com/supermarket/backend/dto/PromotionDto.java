package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PromotionDto {
    private Long id;
    private String name;
    private String code;
    private String description;
    private String priority;
    private String discountType;
    private Double discountValue;
    private List<String> targetCategories;
    private List<String> targetProducts;
    private LocalDate startDate;
    private LocalDate endDate;
    private String imageUrl;
    private String visibility;
    
    // Computed fields
    private String status; // PENDING, ACTIVE, EXPIRED
    private Integer productsCount;

    // Analytics / Performance Mock Data for wow factor UI
    private String estRevenueIncrease;
    private Integer productsSold;
    private Integer usageRate;
    private List<Integer> dailyEngagement;
}
