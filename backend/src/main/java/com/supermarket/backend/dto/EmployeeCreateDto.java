package com.supermarket.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeCreateDto {

    @NotBlank(message = "Name is required")
    private String name;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^\\+?[0-9\\s\\-()]{8,20}$", message = "Invalid phone number format")
    private String phone;

    @NotBlank(message = "Branch or location is required")
    private String location;

    @NotBlank(message = "Role is required")
    private String role; // MANAGER, CASHIER, INVENTORY_STAFF, SALES_ASSOCIATE

    private String imageUrl;
}
