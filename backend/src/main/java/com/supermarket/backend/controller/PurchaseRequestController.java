package com.supermarket.backend.controller;

import com.supermarket.backend.dto.PurchaseRequestItemsDTO;
import com.supermarket.backend.entity.PurchaseRequest;
import com.supermarket.backend.service.InventoryProductService;
import com.supermarket.backend.service.InventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/purchase-requests")
@RequiredArgsConstructor
public class PurchaseRequestController {

    private final InventoryProductService inventoryProductService;
    private final InventoryService inventoryService;

    @PostMapping("/items")
    public ResponseEntity<Map<String, Object>> addProductsToPurchaseRequest(
            @RequestBody PurchaseRequestItemsDTO dto) {
        
        try {
            UUID userId = null;
            if (dto.getUserId() != null && !dto.getUserId().trim().isEmpty()) {
                userId = UUID.fromString(dto.getUserId());
            }

            PurchaseRequest pr = inventoryProductService.addProductsToPurchaseRequest(userId, dto.getProductNumbers());
            com.supermarket.backend.dto.PurchaseRequestDetailDTO details = inventoryService.getPurchaseRequestDetails(pr.getPurchaseRequestNumber());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Products added to the purchase request successfully.");
            response.put("data", details);

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

    @GetMapping
    public ResponseEntity<Map<String, Object>> getPurchaseRequests() {
        try {
            java.util.List<com.supermarket.backend.dto.PurchaseRequestListDTO> list = inventoryService.getPurchaseRequests();
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Purchase requests loaded successfully.");
            response.put("data", list);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error while loading purchase requests: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getPurchaseRequestDetails(@PathVariable("id") Integer prNumber) {
        try {
            com.supermarket.backend.dto.PurchaseRequestDetailDTO details = inventoryService.getPurchaseRequestDetails(prNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Purchase request details loaded successfully.");
            response.put("data", details);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error while loading purchase request details: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/{id}/submit")
    public ResponseEntity<Map<String, Object>> submitPurchaseRequest(@PathVariable("id") Integer prNumber) {
        try {
            inventoryService.submitPurchaseRequest(prNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Purchase request has been submitted for approval successfully.");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "System error while submitting purchase request: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}
