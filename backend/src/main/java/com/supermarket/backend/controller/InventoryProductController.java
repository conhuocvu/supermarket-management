package com.supermarket.backend.controller;

import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.dto.InventoryProductDTO;
import com.supermarket.backend.dto.ProductCreateUpdateDTO;
import com.supermarket.backend.dto.PurchaseRequestCreateDTO;
import com.supermarket.backend.dto.UnitDTO;
import com.supermarket.backend.service.InventoryProductService;
import com.supermarket.backend.service.SupabaseStorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
@CrossOrigin
public class InventoryProductController {

    private final InventoryProductService inventoryProductService;
    private final SupabaseStorageService supabaseStorageService;

    @GetMapping("/products")
    public ResponseEntity<Map<String, Object>> getProducts(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "categoryNumber", required = false) Integer categoryNumber,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        
        // Sort by product name alphabetically by default
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("productName").ascending());
        Page<InventoryProductDTO> products = inventoryProductService.getProducts(keyword, categoryNumber, pageRequest);
        
        Map<String, Object> data = new HashMap<>();
        data.put("items", products.getContent());
        data.put("page", products.getNumber());
        data.put("size", products.getSize());
        data.put("totalItems", products.getTotalElements());
        data.put("totalPages", products.getTotalPages());

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Product list loaded successfully.");
        response.put("data", data);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/categories")
    public ResponseEntity<Map<String, Object>> getCategories() {
        List<CategoryDTO> categories = inventoryProductService.getActiveCategories();
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Categories loaded successfully.");
        response.put("data", categories);

        return ResponseEntity.ok(response);
    }

    @PatchMapping("/products/{id}/status")
    public ResponseEntity<Map<String, Object>> updateProductStatus(
            @PathVariable("id") Integer productNumber,
            @RequestParam("status") String status) {
        
        try {
            inventoryProductService.updateProductStatus(productNumber, status);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Product status updated successfully.");
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Internal server error: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/purchase-requests")
    public ResponseEntity<Map<String, Object>> createPurchaseRequest(
            @RequestBody PurchaseRequestCreateDTO dto) {
        
        try {
            inventoryProductService.createPurchaseRequest(dto.getProductNumbers());
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Purchase request created successfully.");
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to create purchase request: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/units")
    public ResponseEntity<Map<String, Object>> getUnits() {
        List<UnitDTO> units = inventoryProductService.getActiveUnits();
        
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Units loaded successfully.");
        response.put("data", units);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/products/upload")
    public ResponseEntity<Map<String, Object>> uploadProductImage(
            @RequestParam("file") MultipartFile file) {
        try {
            String imageUrl = supabaseStorageService.uploadFile(file);
            
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("url", imageUrl);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "File uploaded successfully.");
            response.put("data", responseData);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Upload failed: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/products")
    public ResponseEntity<Map<String, Object>> createProduct(
            @Valid @RequestBody ProductCreateUpdateDTO dto) {
        try {
            inventoryProductService.createProduct(dto);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Product created successfully.");
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to create product: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PutMapping("/products/{id}")
    public ResponseEntity<Map<String, Object>> updateProduct(
            @PathVariable("id") Integer productNumber,
            @Valid @RequestBody ProductCreateUpdateDTO dto) {
        try {
            inventoryProductService.updateProduct(productNumber, dto);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Product updated successfully.");
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to update product: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/products/search")
    public ResponseEntity<Map<String, Object>> searchInventoryProducts(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "categoryNumber", required = false) Integer categoryNumber,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        
        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("productName").ascending());
        Page<InventoryProductDTO> products = inventoryProductService.searchInventoryProducts(keyword, categoryNumber, pageRequest);
        
        Map<String, Object> data = new HashMap<>();
        data.put("items", products.getContent());
        data.put("page", products.getNumber());
        data.put("size", products.getSize());
        data.put("totalItems", products.getTotalElements());
        data.put("totalPages", products.getTotalPages());

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Search results loaded successfully.");
        response.put("data", data);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/products/{id}")
    public ResponseEntity<Map<String, Object>> softDeleteProduct(
            @PathVariable("id") Integer productNumber) {
        try {
            inventoryProductService.softDeleteProduct(productNumber);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Product soft deleted successfully.");
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to delete product: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/products/warnings")
    public ResponseEntity<Map<String, Object>> getProductsByWarning(
            @RequestParam("warningType") String warningType) {
        
        List<InventoryProductDTO> products = inventoryProductService.getProductsByWarning(warningType);
        
        Map<String, Object> data = new HashMap<>();
        data.put("items", products);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Warning products loaded successfully.");
        response.put("data", data);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/products/{productNumber}")
    public ResponseEntity<Map<String, Object>> getProductDetails(@PathVariable int productNumber) {
        try {
            com.supermarket.backend.dto.InventoryProductDetailDTO dto = inventoryProductService.getProductDetails(productNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Product details loaded successfully.");
            response.put("data", dto);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to load product details: " + e.getMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
}

