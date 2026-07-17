package com.supermarket.backend.dto;

import lombok.Data;

@Data
public class SetRoleRequestDTO {
    private Integer roleNumber;
    private String reason;
}
