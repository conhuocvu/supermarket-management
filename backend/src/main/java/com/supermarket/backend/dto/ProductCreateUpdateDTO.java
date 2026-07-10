package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductCreateUpdateDTO {
    @NotBlank(message = "Tên sản phẩm không được để trống")
    private String productName;
    
    @NotBlank(message = "Mã vạch không được để trống")
    private String barcode;
    
    @NotNull(message = "Danh mục không được để trống")
    private Integer categoryNumber;
    
    @NotNull(message = "Đơn vị tính không được để trống")
    private Integer inventoryUnitNumber;
    
    @NotNull(message = "Giá bán không được để trống")
    private BigDecimal sellingPrice;
    
    @NotNull(message = "Mức báo động tồn kho không được để trống")
    private BigDecimal reorderLevel;
    
    private String status; // Default ACTIVE
    private String description;
    private String imageUrl;
    private Integer expiryWarningDays; // Default 30
    private BigDecimal initialQuantity; // Starting stock quantity (for creation)
}
