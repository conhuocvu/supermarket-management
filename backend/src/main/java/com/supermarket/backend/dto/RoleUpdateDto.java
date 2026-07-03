package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoleUpdateDto {

    @NotBlank(message = "Role is required")
    private String role;
}
