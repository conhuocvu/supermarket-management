package com.supermarket.backend.controller;

import com.supermarket.backend.dto.DashboardDataDTO;
import com.supermarket.backend.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
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
}
