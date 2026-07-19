package com.supermarket.backend.exception;

import org.springframework.http.HttpStatus;

public class ModuleException extends RuntimeException {
    private final HttpStatus status;

    public ModuleException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
