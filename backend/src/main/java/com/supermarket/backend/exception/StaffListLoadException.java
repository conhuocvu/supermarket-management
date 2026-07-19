package com.supermarket.backend.exception;

public class StaffListLoadException extends RuntimeException {
    public StaffListLoadException(String message) {
        super(message);
    }
    public StaffListLoadException(String message, Throwable cause) {
        super(message, cause);
    }
}
