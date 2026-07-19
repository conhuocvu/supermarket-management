package com.supermarket.backend.service;

import com.supermarket.backend.dto.SalesDTO;
import com.supermarket.backend.dto.SalesRequest;
import com.supermarket.backend.exception.ModuleException;
import com.supermarket.backend.repository.SalesRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
public class SalesService {
    private static final BigDecimal REWARD_POINT_VALUE = BigDecimal.valueOf(100);
    private static final BigDecimal EARN_POINT_DIVISOR = BigDecimal.valueOf(10_000);
    private static final Set<String> PAYMENT_METHODS = Set.of("CASH", "CARD", "BANK_TRANSFER");
    private static final Set<String> INVOICE_STATUSES = Set.of("ALL", "UNPAID", "PAID", "CANCELLED");
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final SalesRepository repository;

    public SalesService(SalesRepository repository) {
        this.repository = repository;
    }

    public SalesDTO.Dashboard dashboard(UUID cashierId) {
        requireCashierId(cashierId);
        SalesDTO.Shift shift = currentShift(cashierId);
        return new SalesDTO.Dashboard(
                repository.countInvoices(cashierId, shift.startDateTime(), shift.endDateTime()),
                repository.sumRevenue(cashierId, shift.startDateTime(), shift.endDateTime()),
                repository.countUnpaidInvoices(cashierId, shift.startDateTime(), shift.endDateTime()), shift,
                repository.findInvoiceSummaries(cashierId, shift.startDateTime(), shift.endDateTime(),
                        "", "ALL", 5, 0),
                repository.findAlerts());
    }

    public List<SalesDTO.Product> products(String keyword, Integer categoryNumber) {
        return repository.findProducts(keyword == null ? "" : keyword.trim(), categoryNumber);
    }

    public List<SalesDTO.Category> categories() {
        return repository.findCategories();
    }

    public SalesDTO.Invoice createInvoice(SalesRequest.CreateInvoice request) {
        if (request == null) throw badRequest("Invoice information is required.");
        requireCashierId(request.cashierId());
        throw badRequest("Select the first product before creating an invoice.");
    }

    @Transactional
    public SalesDTO.Invoice startInvoice(SalesRequest.StartInvoice request) {
        if (request == null || request.productNumber() == null) {
            throw badRequest("Cashier and first product are required.");
        }
        requireCashierId(request.cashierId());
        BigDecimal quantity = positiveQuantity(request.quantity());
        SalesRepository.ProductSaleData product = sellableProduct(request.productNumber());
        ensureStock(product, quantity);

        int invoiceNumber = repository.createInvoice(request.cashierId());
        if (invoiceNumber <= 0) {
            throw new ModuleException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Unable to create invoice. Please try again.");
        }
        repository.upsertItem(invoiceNumber, request.productNumber(), quantity, product.price());
        repository.recalculateInvoice(invoiceNumber);
        return getInvoice(invoiceNumber);
    }

    public SalesDTO.Invoice getInvoice(int invoiceNumber) {
        return repository.findInvoice(invoiceNumber).orElseThrow(() ->
                new ModuleException(HttpStatus.NOT_FOUND, "Invoice not found."));
    }

    @Transactional
    public SalesDTO.Invoice addItem(int invoiceNumber, SalesRequest.InvoiceItem request) {
        if (request == null || request.productNumber() == null) throw badRequest("Product is required.");
        BigDecimal addQuantity = positiveQuantity(request.quantity());
        ensureUnpaidLocked(invoiceNumber);
        SalesRepository.ProductSaleData product = sellableProduct(request.productNumber());
        BigDecimal current = repository.currentItemQuantity(invoiceNumber, request.productNumber());
        BigDecimal target = current.add(addQuantity);
        ensureStock(product, target);
        repository.upsertItem(invoiceNumber, request.productNumber(), target, product.price());
        repository.recalculateInvoice(invoiceNumber);
        return getInvoice(invoiceNumber);
    }

    @Transactional
    public SalesDTO.Invoice updateItem(int invoiceNumber, int detailId, SalesRequest.InvoiceItem request) {
        if (request == null) throw badRequest("Quantity is required.");
        BigDecimal quantity = positiveQuantity(request.quantity());
        ensureUnpaidLocked(invoiceNumber);
        SalesRepository.InvoiceDetailIdentity detail = repository.findDetail(detailId);
        if (detail == null || detail.invoiceNumber() != invoiceNumber) {
            throw new ModuleException(HttpStatus.NOT_FOUND, "Invoice item not found.");
        }
        SalesRepository.ProductSaleData product = sellableProduct(detail.productNumber());
        ensureStock(product, quantity);
        repository.updateDetailQuantity(detailId, quantity);
        repository.recalculateInvoice(invoiceNumber);
        return getInvoice(invoiceNumber);
    }

    @Transactional
    public SalesDTO.Invoice removeItem(int invoiceNumber, int detailId) {
        ensureUnpaidLocked(invoiceNumber);
        SalesRepository.InvoiceDetailIdentity detail = repository.findDetail(detailId);
        if (detail == null || detail.invoiceNumber() != invoiceNumber) {
            throw new ModuleException(HttpStatus.NOT_FOUND, "Invoice item not found.");
        }
        if (repository.countInvoiceItems(invoiceNumber) <= 1) {
            throw badRequest("An invoice must contain at least one product. Cancel the invoice instead.");
        }
        repository.deleteDetail(detailId);
        repository.recalculateInvoice(invoiceNumber);
        return getInvoice(invoiceNumber);
    }

    @Transactional
    public SalesDTO.Invoice cancelInvoice(int invoiceNumber) {
        ensureUnpaidLocked(invoiceNumber);
        repository.cancelInvoice(invoiceNumber);
        return getInvoice(invoiceNumber);
    }

    public SalesDTO.Customer findCustomer(String phone) {
        String normalized = normalizePhone(phone);
        return repository.findCustomerByPhone(normalized).orElseThrow(() ->
                new ModuleException(HttpStatus.NOT_FOUND, "Customer not found."));
    }

    public SalesDTO.Customer registerCustomer(SalesRequest.RegisterCustomer request) {
        if (request == null || request.fullName() == null || request.fullName().isBlank()) {
            throw badRequest("Customer name is required.");
        }
        String phone = normalizePhone(request.phone());
        if (repository.findCustomerByPhone(phone).isPresent()) {
            throw new ModuleException(HttpStatus.CONFLICT, "A customer with this phone number already exists.");
        }
        try {
            return repository.createCustomer(request.fullName().trim(), phone);
        } catch (DataIntegrityViolationException exception) {
            throw new ModuleException(HttpStatus.CONFLICT, "A customer with this phone number already exists.");
        }
    }

    @Transactional
    public SalesDTO.Invoice linkCustomer(int invoiceNumber, SalesRequest.LinkCustomer request) {
        ensureUnpaidLocked(invoiceNumber);
        Integer customerNumber = request == null ? null : request.customerNumber();
        if (customerNumber != null) customer(customerNumber);
        repository.linkCustomer(invoiceNumber, customerNumber);
        return getInvoice(invoiceNumber);
    }

    public List<SalesDTO.Promotion> eligiblePromotions(int invoiceNumber) {
        SalesDTO.Invoice invoice = getInvoice(invoiceNumber);
        ensureUnpaid(invoice);
        return repository.findEligiblePromotions(invoiceNumber);
    }

    public SalesDTO.CheckoutPreview checkoutPreview(int invoiceNumber, SalesRequest.Checkout request) {
        SalesDTO.Invoice invoice = getInvoice(invoiceNumber);
        ensureUnpaid(invoice);
        if (invoice.items().isEmpty()) throw badRequest("Add at least one product before checkout.");
        Integer customerNumber = request == null ? null : request.customerNumber();
        if (customerNumber == null && invoice.customer() != null) customerNumber = invoice.customer().customerNumber();
        SalesDTO.Customer customer = customerNumber == null ? null : customer(customerNumber);
        Integer promotionNumber = request == null ? null : request.promotionNumber();
        int rewardPoints = request == null || request.rewardPoints() == null ? 0 : request.rewardPoints();
        if (rewardPoints < 0) throw badRequest("Reward points cannot be negative.");
        if (rewardPoints > 0 && customer == null) throw badRequest("Please select a customer before using reward points.");
        if (customer != null && rewardPoints > customer.point()) throw badRequest("Not enough reward points.");

        SalesDTO.Promotion promotion = selectedPromotion(invoiceNumber, promotionNumber);
        BigDecimal promotionDiscount = promotion == null ? BigDecimal.ZERO : promotion.discountAmount();
        BigDecimal rewardDiscount = money(REWARD_POINT_VALUE.multiply(BigDecimal.valueOf(rewardPoints)));
        BigDecimal finalAmount = money(invoice.totalAmount().subtract(promotionDiscount).subtract(rewardDiscount));
        if (finalAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw badRequest("The final invoice amount must be greater than 0.");
        }
        int earned = earnPoints(finalAmount);
        return new SalesDTO.CheckoutPreview(invoice, promotion, rewardPoints, rewardDiscount,
                finalAmount, customer == null ? 0 : customer.point(), earned);
    }

    @Transactional
    public SalesDTO.Receipt processPayment(int invoiceNumber, SalesRequest.Payment request) {
        if (request == null) throw badRequest("Payment information is required.");
        ensureUnpaidLocked(invoiceNumber);
        SalesDTO.CheckoutPreview preview = checkoutPreview(invoiceNumber,
                new SalesRequest.Checkout(request.customerNumber(), request.promotionNumber(), request.rewardPoints()));
        String method = normalizePaymentMethod(request.paymentMethod());
        BigDecimal paidAmount = request.paidAmount() == null ? BigDecimal.ZERO : money(request.paidAmount());
        if (paidAmount.compareTo(preview.finalAmount()) < 0) {
            throw badRequest("Paid amount must be greater than or equal to the invoice total.");
        }

        SalesDTO.Invoice beforePayment = preview.invoice();
        for (SalesDTO.InvoiceLine line : beforePayment.items()) {
            BigDecimal available = repository.lockInventory(line.productNumber());
            if (available.compareTo(line.quantity()) < 0) {
                throw new ModuleException(HttpStatus.CONFLICT,
                        line.productName() + " no longer has enough stock.");
            }
            repository.deductInventory(line.productNumber(), line.quantity());
            allocateBatches(line, beforePayment.invoiceNumber(), beforePayment.cashierId());
        }

        Integer customerNumber = request.customerNumber();
        if (customerNumber == null && beforePayment.customer() != null) {
            customerNumber = beforePayment.customer().customerNumber();
        }
        if (customerNumber != null) {
            SalesDTO.Customer lockedCustomer = repository.lockCustomerById(customerNumber)
                    .orElseThrow(() -> new ModuleException(HttpStatus.NOT_FOUND, "Customer not found."));
            if (preview.rewardPointsUsed() > lockedCustomer.point()) {
                throw new ModuleException(HttpStatus.CONFLICT,
                        "The customer's reward point balance has changed. Please recalculate checkout.");
            }
        }
        repository.updateInvoiceForPayment(invoiceNumber, customerNumber,
                beforePayment.totalAmount(), preview.finalAmount());
        LocalDateTime paymentDate = repository.insertPayment(invoiceNumber, method, paidAmount);
        if (customerNumber != null) {
            repository.updateCustomerPoints(customerNumber, preview.rewardPointsUsed(), preview.estimatedPointsEarned());
        }
        SalesDTO.Invoice paidInvoice = getInvoice(invoiceNumber);
        return new SalesDTO.Receipt(paidInvoice, preview.promotion(), preview.rewardPointsUsed(),
                preview.rewardDiscount(), preview.estimatedPointsEarned(), paidAmount,
                money(paidAmount.subtract(preview.finalAmount())), paymentDate);
    }

    public SalesDTO.Receipt receipt(int invoiceNumber) {
        SalesDTO.Invoice invoice = getInvoice(invoiceNumber);
        if (!"PAID".equalsIgnoreCase(invoice.status())) {
            throw badRequest("Only paid invoices can be printed.");
        }
        BigDecimal combinedDiscount = money(invoice.totalAmount().subtract(invoice.finalAmount()));
        SalesDTO.Promotion discount = combinedDiscount.signum() > 0
                ? new SalesDTO.Promotion(null, "Applied discounts", BigDecimal.ZERO,
                        invoice.totalAmount(), combinedDiscount)
                : null;
        BigDecimal paid = invoice.paidAmount().signum() > 0 ? invoice.paidAmount() : invoice.finalAmount();
        return new SalesDTO.Receipt(invoice, discount, 0, BigDecimal.ZERO,
                earnPoints(invoice.finalAmount()), paid, money(paid.subtract(invoice.finalAmount())),
                repository.findLatestPaymentDate(invoiceNumber));
    }

    public Map<String, Object> shiftInvoices(UUID cashierId, Integer page, Integer size,
            String keyword, String status) {
        requireCashierId(cashierId);
        int safePage = page == null || page < 0 ? 0 : page;
        int safeSize = size == null || size <= 0 ? 10 : Math.min(size, 100);
        String safeKeyword = keyword == null ? "" : keyword.trim();
        String safeStatus = status == null ? "ALL" : status.trim().toUpperCase(Locale.ROOT);
        if (!INVOICE_STATUSES.contains(safeStatus)) safeStatus = "ALL";
        SalesDTO.Shift shift = currentShift(cashierId);
        List<SalesDTO.InvoiceSummary> items = repository.findInvoiceSummaries(cashierId,
                shift.startDateTime(), shift.endDateTime(), safeKeyword, safeStatus, safeSize, safePage * safeSize);
        long total = repository.countInvoiceSummaries(cashierId, shift.startDateTime(),
                shift.endDateTime(), safeKeyword, safeStatus);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("items", items);
        result.put("page", safePage);
        result.put("size", safeSize);
        result.put("totalItems", total);
        result.put("totalPages", total == 0 ? 0 : (int) Math.ceil((double) total / safeSize));
        result.put("shift", shift);
        return result;
    }

    private SalesDTO.Shift currentShift(UUID cashierId) {
        return repository.findCurrentShift(cashierId).orElseGet(() -> {
            LocalDate today = LocalDate.now(VIETNAM_ZONE);
            return new SalesDTO.Shift("No active shift - today", today.atStartOfDay(), today.plusDays(1).atStartOfDay());
        });
    }

    private void allocateBatches(SalesDTO.InvoiceLine line, int invoiceNumber, UUID cashierId) {
        BigDecimal remaining = line.quantity();
        for (SalesRepository.StockBatch batch : repository.lockSellableBatches(line.productNumber())) {
            if (remaining.signum() <= 0) break;
            BigDecimal used = remaining.min(batch.remainingQuantity());
            repository.deductBatch(batch.stockInDetailNumber(), used);
            repository.insertSaleTransaction(line.productNumber(), batch.stockInDetailNumber(), used,
                    invoiceNumber, cashierId);
            remaining = remaining.subtract(used);
        }
        if (remaining.signum() > 0) {
            repository.insertSaleTransaction(line.productNumber(), null, remaining, invoiceNumber, cashierId);
        }
    }

    private SalesDTO.Promotion selectedPromotion(int invoiceNumber, Integer promotionNumber) {
        if (promotionNumber == null) return null;
        return repository.findEligiblePromotions(invoiceNumber).stream()
                .filter(p -> p.promotionNumber().equals(promotionNumber)).findFirst()
                .orElseThrow(() -> badRequest("The selected promotion is not valid for this invoice."));
    }

    private SalesDTO.Customer customer(int customerNumber) {
        return repository.findCustomerById(customerNumber).orElseThrow(() ->
                new ModuleException(HttpStatus.NOT_FOUND, "Customer not found."));
    }

    private SalesRepository.ProductSaleData sellableProduct(int productNumber) {
        SalesRepository.ProductSaleData product = repository.productForSale(productNumber);
        if (product == null) throw new ModuleException(HttpStatus.NOT_FOUND, "Product not found.");
        if (!"ACTIVE".equalsIgnoreCase(product.status())) throw badRequest("Inactive products cannot be sold.");
        if (product.expired()) throw badRequest("Expired product cannot be sold.");
        return product;
    }

    private void ensureStock(SalesRepository.ProductSaleData product, BigDecimal quantity) {
        if (product.availableQuantity().compareTo(quantity) < 0) {
            throw badRequest("Quantity cannot exceed available stock.");
        }
    }

    private void ensureUnpaidLocked(int invoiceNumber) {
        String status = repository.lockInvoiceStatus(invoiceNumber);
        if (status == null) throw new ModuleException(HttpStatus.NOT_FOUND, "Invoice not found.");
        if (!"UNPAID".equalsIgnoreCase(status)) {
            throw new ModuleException(HttpStatus.CONFLICT, "Only unpaid invoices can be edited.");
        }
    }

    private void ensureUnpaid(SalesDTO.Invoice invoice) {
        if (!"UNPAID".equalsIgnoreCase(invoice.status())) {
            throw new ModuleException(HttpStatus.CONFLICT, "Only unpaid invoices can be edited.");
        }
    }

    private BigDecimal positiveQuantity(BigDecimal quantity) {
        if (quantity == null || quantity.compareTo(BigDecimal.ZERO) <= 0) {
            throw badRequest("Quantity must be greater than zero.");
        }
        return money(quantity);
    }

    private String normalizePhone(String phone) {
        if (phone == null) throw badRequest("Phone number is required.");
        String value = phone.replaceAll("\\s+", "").trim();
        if (!value.matches("^[0-9+]{8,20}$")) throw badRequest("Enter a valid phone number.");
        return value;
    }

    private String normalizePaymentMethod(String method) {
        String value = method == null ? "" : method.trim().toUpperCase(Locale.ROOT);
        if (!PAYMENT_METHODS.contains(value)) throw badRequest("Unsupported payment method.");
        return value;
    }

    private void requireCashierId(UUID cashierId) {
        if (cashierId == null) throw badRequest("Cashier ID is required.");
    }

    private int earnPoints(BigDecimal finalAmount) {
        return finalAmount.divide(EARN_POINT_DIVISOR, 0, RoundingMode.DOWN).intValue();
    }

    private BigDecimal money(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value.setScale(2, RoundingMode.HALF_UP);
    }

    private ModuleException badRequest(String message) {
        return new ModuleException(HttpStatus.BAD_REQUEST, message);
    }
}
