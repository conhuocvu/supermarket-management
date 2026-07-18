package com.supermarket.backend.dto;

import lombok.*;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PromotionDTO {
    private Long id;
    private Integer promotionNumber;
    private String promotionName;
    private Double discountValue;
    private String status;
    private LocalDate startDate;
    private LocalDate endDate;
    private String description;
    private String imageUrl;
    private String visibility;
    private String promoCode;
    private String category;
    private Boolean isFeatured;
}
