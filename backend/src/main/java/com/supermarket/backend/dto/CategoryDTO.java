package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryDTO {
    private Integer categoryNumber;
    private Integer parentCategoryNumber;
    private String parentCategoryName;
    
    @NotBlank(message = "Category name cannot be empty")
    private String categoryName;
    
    private String status;
    private String description;
    private String internalNotes;
}
