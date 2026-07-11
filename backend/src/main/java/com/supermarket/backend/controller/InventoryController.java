package com.supermarket.backend.controller;

import com.supermarket.backend.dto.DashboardDataDTO;
import com.supermarket.backend.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    @GetMapping("/dashboard")
    public ResponseEntity<Map<String, Object>> getDashboardData() {
        DashboardDataDTO dashboardData = inventoryService.getDashboardData();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Dashboard data loaded successfully.");
        response.put("data", dashboardData);
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/transactions")
    public ResponseEntity<Map<String, Object>> getTransactions() {
        java.util.List<com.supermarket.backend.dto.InventoryTransactionDTO> transactions = inventoryService.getInventoryTransactions();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Transactions retrieved successfully.");
        response.put("data", transactions);
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/pending-tasks")
    public ResponseEntity<Map<String, Object>> getPendingTasks() {
        com.supermarket.backend.dto.PendingTasksDTO pendingTasks = inventoryService.getPendingTasks();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Pending tasks retrieved successfully.");
        response.put("data", pendingTasks);
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/delivery-issues")
    public ResponseEntity<Map<String, Object>> saveDeliveryIssue(@RequestBody com.supermarket.backend.dto.DeliveryIssueRequestDTO request) {
        try {
            inventoryService.validateAndSaveDeliveryIssue(request);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Delivery issue has been reported successfully.");
            return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Delivery issue cannot be saved.");
            return ResponseEntity.status(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}
