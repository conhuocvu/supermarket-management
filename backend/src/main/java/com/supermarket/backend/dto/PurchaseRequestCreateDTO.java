package com.supermarket.backend.dto;

import lombok.*;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseRequestCreateDTO {
    private List<Integer> productNumbers;
}
