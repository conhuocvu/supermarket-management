package com.supermarket.backend.dto;

import lombok.*;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestFormDataDTO {
    private List<SupplierDTO> suppliers;
    private List<PurchaseRequestFormProductDTO> products;
}
