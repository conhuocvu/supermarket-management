package com.supermarket.backend.controller;

import com.supermarket.backend.dto.StockOutFormDataDTO;
import com.supermarket.backend.dto.StockOutRequestDTO;
import com.supermarket.backend.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/stock-outs")
@RequiredArgsConstructor
public class StockOutController {

    private final InventoryService inventoryService;

    @GetMapping("/form-data")
    public ResponseEntity<Map<String, Object>> getFormData(@RequestParam("reportNumber") Integer reportNumber) {
        try {
            StockOutFormDataDTO data = inventoryService.getStockOutFormData(reportNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Stock-Out form data loaded successfully.");
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
    public ResponseEntity<Map<String, Object>> recordStockOut(@RequestBody StockOutRequestDTO request) {
        try {
            inventoryService.recordStockOut(request);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Stock-Out has been recorded successfully.");
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error while saving stock-out: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
