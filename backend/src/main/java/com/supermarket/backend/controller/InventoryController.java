package com.supermarket.backend.controller;

import com.supermarket.backend.dto.DashboardDataDTO;
import com.supermarket.backend.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
}
