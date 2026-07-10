package com.supermarket.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class PurchaseRequestItemsDTO {
    private String userId;
    private List<Integer> productNumbers;
}
