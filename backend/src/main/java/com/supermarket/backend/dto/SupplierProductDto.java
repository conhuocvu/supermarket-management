package com.supermarket.backend.dto;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SupplierProductDto {
    private Long id;
    private Long productId;
    private String sku;
    private String name;
    private String category;
    private Double basePrice;
    private Double importPrice;
    private String unit;
    private String imageUrl;
    private Boolean assigned;
}
