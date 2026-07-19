package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.SalesDTO;
import com.supermarket.backend.dto.SalesRequest;
import com.supermarket.backend.service.SalesService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/cashier")
public class SalesController {
    private final SalesService service;

    public SalesController(SalesService service) {
        this.service = service;
    }

    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<SalesDTO.Dashboard>> dashboard(@RequestParam UUID cashierId) {
        return ok("Cashier dashboard loaded successfully.", service.dashboard(cashierId));
    }

    @GetMapping("/products")
    public ResponseEntity<ApiResponse<List<SalesDTO.Product>>> products(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer categoryNumber) {
        return ok("Products loaded successfully.", service.products(keyword, categoryNumber));
    }

    @GetMapping("/categories")
    public ResponseEntity<ApiResponse<List<SalesDTO.Category>>> categories() {
        return ok("Categories loaded successfully.", service.categories());
    }

    @PostMapping("/invoices")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> createInvoice(@RequestBody SalesRequest.CreateInvoice request) {
        return ok("Invoice created successfully.", service.createInvoice(request));
    }

    @PostMapping("/invoices/start")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> startInvoice(@RequestBody SalesRequest.StartInvoice request) {
        return ok("Invoice started successfully.", service.startInvoice(request));
    }

    @GetMapping("/invoices/{invoiceNumber}")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> invoice(@PathVariable int invoiceNumber) {
        return ok("Invoice loaded successfully.", service.getInvoice(invoiceNumber));
    }

    @PostMapping("/invoices/{invoiceNumber}/items")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> addItem(@PathVariable int invoiceNumber,
            @RequestBody SalesRequest.InvoiceItem request) {
        return ok("Product added successfully.", service.addItem(invoiceNumber, request));
    }

    @PatchMapping("/invoices/{invoiceNumber}/items/{detailId}")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> updateItem(@PathVariable int invoiceNumber,
            @PathVariable int detailId, @RequestBody SalesRequest.InvoiceItem request) {
        return ok("Product quantity updated successfully.", service.updateItem(invoiceNumber, detailId, request));
    }

    @DeleteMapping("/invoices/{invoiceNumber}/items/{detailId}")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> removeItem(@PathVariable int invoiceNumber,
            @PathVariable int detailId) {
        return ok("Product removed successfully.", service.removeItem(invoiceNumber, detailId));
    }

    @PatchMapping("/invoices/{invoiceNumber}/cancel")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> cancelInvoice(@PathVariable int invoiceNumber) {
        return ok("Invoice cancelled successfully.", service.cancelInvoice(invoiceNumber));
    }

    @GetMapping("/customers/search")
    public ResponseEntity<ApiResponse<SalesDTO.Customer>> customer(@RequestParam String phone) {
        return ok("Customer found.", service.findCustomer(phone));
    }

    @PostMapping("/customers")
    public ResponseEntity<ApiResponse<SalesDTO.Customer>> registerCustomer(
            @RequestBody SalesRequest.RegisterCustomer request) {
        return ok("Customer registered successfully.", service.registerCustomer(request));
    }

    @PatchMapping("/invoices/{invoiceNumber}/customer")
    public ResponseEntity<ApiResponse<SalesDTO.Invoice>> linkCustomer(@PathVariable int invoiceNumber,
            @RequestBody SalesRequest.LinkCustomer request) {
        return ok("Customer linked successfully.", service.linkCustomer(invoiceNumber, request));
    }

    @GetMapping("/invoices/{invoiceNumber}/promotions")
    public ResponseEntity<ApiResponse<List<SalesDTO.Promotion>>> promotions(@PathVariable int invoiceNumber) {
        return ok("Eligible promotions loaded successfully.", service.eligiblePromotions(invoiceNumber));
    }

    @PostMapping("/invoices/{invoiceNumber}/checkout-preview")
    public ResponseEntity<ApiResponse<SalesDTO.CheckoutPreview>> checkout(@PathVariable int invoiceNumber,
            @RequestBody SalesRequest.Checkout request) {
        return ok("Checkout information calculated successfully.", service.checkoutPreview(invoiceNumber, request));
    }

    @PostMapping("/invoices/{invoiceNumber}/payment")
    public ResponseEntity<ApiResponse<SalesDTO.Receipt>> payment(@PathVariable int invoiceNumber,
            @RequestBody SalesRequest.Payment request) {
        return ok("Payment processed successfully.", service.processPayment(invoiceNumber, request));
    }

    @GetMapping("/invoices/{invoiceNumber}/receipt")
    public ResponseEntity<ApiResponse<SalesDTO.Receipt>> receipt(@PathVariable int invoiceNumber) {
        return ok("Receipt loaded successfully.", service.receipt(invoiceNumber));
    }

    @GetMapping("/shift-invoices")
    public ResponseEntity<ApiResponse<Map<String, Object>>> shiftInvoices(
            @RequestParam UUID cashierId,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status) {
        return ok("Shift invoices loaded successfully.",
                service.shiftInvoices(cashierId, page, size, keyword, status));
    }

    private <T> ResponseEntity<ApiResponse<T>> ok(String message, T data) {
        return ResponseEntity.ok(ApiResponse.success(message, data));
    }
}
