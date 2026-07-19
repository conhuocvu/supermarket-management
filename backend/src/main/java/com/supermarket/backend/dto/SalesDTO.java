package com.supermarket.backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public final class SalesDTO {
    private SalesDTO() {}

    public record Shift(String name, LocalDateTime startDateTime, LocalDateTime endDateTime) {}

    public record InvoiceSummary(Integer invoiceNumber, String customerName,
            BigDecimal totalAmount, BigDecimal finalAmount, String status,
            String paymentMethod, LocalDateTime createdDate) {}

    public record Dashboard(int invoiceCount, BigDecimal revenue, int unpaidInvoiceCount,
            Shift currentShift, List<InvoiceSummary> recentInvoices, List<String> alerts) {}

    public record Product(Integer productNumber, Integer categoryNumber, String categoryName,
            String productName, String barcode, BigDecimal sellingPrice,
            BigDecimal availableQuantity, String imageUrl, boolean expired) {}

    public record Category(Integer categoryNumber, String categoryName) {}

    public record Customer(Integer customerNumber, String fullName, String phone, Integer point) {}

    public record Promotion(Integer promotionNumber, String promotionName,
            BigDecimal discountPercent, BigDecimal eligibleAmount, BigDecimal discountAmount) {}

    public record InvoiceLine(Integer invoiceDetailNumber, Integer productNumber,
            String productName, String barcode, BigDecimal quantity,
            BigDecimal unitPrice, BigDecimal lineTotal, String imageUrl) {}

    public record Invoice(Integer invoiceNumber, UUID cashierId, String cashierName,
            Customer customer, BigDecimal totalAmount, BigDecimal finalAmount,
            String status, LocalDateTime createdDate, String paymentMethod,
            BigDecimal paidAmount, List<InvoiceLine> items) {}

    public record CheckoutPreview(Invoice invoice, Promotion promotion,
            Integer rewardPointsUsed, BigDecimal rewardDiscount,
            BigDecimal finalAmount, Integer availableCustomerPoints,
            int estimatedPointsEarned) {}

    public record Receipt(Invoice invoice, Promotion promotion,
            Integer rewardPointsUsed, BigDecimal rewardDiscount,
            Integer pointsEarned, BigDecimal paidAmount, BigDecimal changeAmount,
            LocalDateTime paymentDate) {}
}
