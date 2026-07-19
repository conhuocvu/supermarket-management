package com.supermarket.backend.dto;

public enum RoleNumber {
    ADMIN(1),
    MANAGER(2),
    STOCK_CONTROLLER(3),
    SALES_ASSOCIATE(4),
    CASHIER(5);

    private final int value;

    RoleNumber(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }

    public static boolean isValid(Integer value) {
        if (value == null) return false;
        for (RoleNumber role : values()) {
            if (role.value == value) {
                return true;
            }
        }
        return false;
    }
}
