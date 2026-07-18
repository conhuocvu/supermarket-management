package com.supermarket.backend.exception;

public class StaffRoleUpdateException extends RuntimeException {
    public StaffRoleUpdateException(String message) {
        super(message);
    }
    public StaffRoleUpdateException(String message, Throwable cause) {
        super(message, cause);
    }
}
