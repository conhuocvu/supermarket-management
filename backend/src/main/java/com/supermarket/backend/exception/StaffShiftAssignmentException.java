package com.supermarket.backend.exception;

public class StaffShiftAssignmentException extends RuntimeException {
    public StaffShiftAssignmentException(String message) {
        super(message);
    }
    public StaffShiftAssignmentException(String message, Throwable cause) {
        super(message, cause);
    }
}
