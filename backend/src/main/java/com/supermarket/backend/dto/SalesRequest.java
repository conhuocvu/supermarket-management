package com.supermarket.backend.dto;

import java.math.BigDecimal;
import java.util.UUID;

public final class SalesRequest {
    private SalesRequest() {}

    public record CreateInvoice(UUID cashierId) {}
    public record StartInvoice(UUID cashierId, Integer productNumber, BigDecimal quantity) {}
    public record InvoiceItem(Integer productNumber, BigDecimal quantity) {}
    public record RegisterCustomer(String fullName, String phone) {}
    public record LinkCustomer(Integer customerNumber) {}
    public record Checkout(Integer customerNumber, Integer promotionNumber, Integer rewardPoints) {}
    public record Payment(Integer customerNumber, Integer promotionNumber, Integer rewardPoints,
            String paymentMethod, BigDecimal paidAmount) {}
}
