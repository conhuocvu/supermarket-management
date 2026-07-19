package com.supermarket.backend.controller;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/stock-ins")
@RequiredArgsConstructor
public class StockInController {

    private final InventoryService inventoryService;

    @GetMapping("/form-data")
    public ResponseEntity<Map<String, Object>> getFormData(
            @RequestParam("purchaseRequestNumber") Integer prNumber,
            @RequestParam(value = "supplierNumber", required = false) Integer supplierNumber) {
        try {
            StockInFormDataDTO data = inventoryService.getPurchaseRequestDetail(prNumber, supplierNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Stock-In form data loaded successfully.");
            response.put("data", data);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error while loading form data: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> recordStockIn(@RequestBody StockInRequestDTO request) {
        try {
            inventoryService.recordStockIn(request);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Stock-In has been recorded successfully.");
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error while saving stock-in: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/compare-quantities")
    public ResponseEntity<Map<String, Object>> compareQuantities(@RequestBody CompareQuantitiesRequestDTO request) {
        try {
            CompareQuantitiesResultDTO result = inventoryService.compareQuantities(request);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", result.isMatched() ? "Delivered quantities match requested quantities." : "Quantity discrepancy detected.");
            response.put("data", result);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error comparing quantities: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
