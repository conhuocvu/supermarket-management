package com.supermarket.backend.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SetRoleRequestDTO {
    @NotNull(message = "Please select a new role.")
    @Min(value = 1, message = "Invalid role number.")
    @Max(value = 5, message = "Invalid role number.")
    private Integer roleNumber;
}
