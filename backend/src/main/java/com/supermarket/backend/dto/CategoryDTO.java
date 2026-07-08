package com.supermarket.backend.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDTO {
    private Integer categoryNumber;
    private String categoryName;
    private String status;
}
