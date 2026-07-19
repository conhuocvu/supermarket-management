package com.supermarket.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierDTO {
    private Integer supplierNumber;
    private String supplierName;
    private String phone;
    private String email;
    private String status;
    private String contactPerson;
    private String address;
    private String category;
    private String notes;
}
