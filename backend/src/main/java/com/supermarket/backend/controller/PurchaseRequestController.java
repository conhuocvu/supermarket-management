package com.supermarket.backend.controller;

import com.supermarket.backend.dto.PurchaseRequestItemsDTO;
import com.supermarket.backend.entity.PurchaseRequest;
import com.supermarket.backend.service.InventoryProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/purchase-requests")
@RequiredArgsConstructor
@CrossOrigin
public class PurchaseRequestController {

    private final InventoryProductService inventoryProductService;

    @PostMapping("/items")
    public ResponseEntity<Map<String, Object>> addProductsToPurchaseRequest(
            @RequestBody PurchaseRequestItemsDTO dto) {
        
        try {
            UUID userId = null;
            if (dto.getUserId() != null && !dto.getUserId().trim().isEmpty()) {
                userId = UUID.fromString(dto.getUserId());
            }

            PurchaseRequest pr = inventoryProductService.addProductsToPurchaseRequest(userId, dto.getProductNumbers());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Products added to the purchase request successfully.");
            response.put("data", pr);

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to add products: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
