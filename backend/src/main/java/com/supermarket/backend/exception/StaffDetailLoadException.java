package com.supermarket.backend.exception;

public class StaffDetailLoadException extends RuntimeException {
    public StaffDetailLoadException(String message) {
        super(message);
    }
    public StaffDetailLoadException(String message, Throwable cause) {
        super(message, cause);
    }
}
