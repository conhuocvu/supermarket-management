package com.supermarket.backend.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDTO {
    private Integer categoryNumber;
    private Integer parentCategoryNumber;
    private String parentCategoryName;
    private String categoryName;
    private String status;
    private String description;
}
