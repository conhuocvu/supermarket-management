package com.supermarket.backend.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductDto {
    private Long id;
    private String sku;
    private String name;
    private String category;
    private Double basePrice;
    private String unit;
    private String imageUrl;
}
