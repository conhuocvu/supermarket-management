package com.supermarket.backend.exception;

public class StaffMetaLoadException extends RuntimeException {
    public StaffMetaLoadException(String message) {
        super(message);
    }
    public StaffMetaLoadException(String message, Throwable cause) {
        super(message, cause);
    }
}
