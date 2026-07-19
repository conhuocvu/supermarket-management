package com.supermarket.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ProfileUpdateDTO {

    @NotBlank(message = "Full name is required.")
    @Size(min = 2, max = 100, message = "Full name must be between 2 and 100 characters.")
    @Pattern(
        regexp = "^[\\p{L}\\s.'\\-]+$",
        flags = Pattern.Flag.UNICODE_CASE,
        message = "Full name contains invalid characters."
    )
    private String fullName;

    @NotBlank(message = "Phone number is required.")
    @Pattern(
        regexp = "^(\\+84|0)\\d{9,10}$",
        message = "Enter a valid phone number (e.g. 0912345678 or +84912345678)."
    )
    private String phone;

    @Size(max = 255, message = "Address must be under 255 characters.")
    private String address;
}
