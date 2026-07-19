package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.SupplierDTO;
import com.supermarket.backend.service.SupplierService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/suppliers")
@RequiredArgsConstructor
public class SupplierController {

    private final SupplierService supplierService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSuppliers(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("supplierName").ascending());
        Page<SupplierDTO> suppliers = supplierService.getSuppliers(keyword, status, pageRequest);

        Map<String, Object> data = new HashMap<>();
        data.put("items", suppliers.getContent());
        data.put("page", suppliers.getNumber());
        data.put("size", suppliers.getSize());
        data.put("totalItems", suppliers.getTotalElements());
        data.put("totalPages", suppliers.getTotalPages());

        return ResponseEntity.ok(ApiResponse.success("Supplier list loaded successfully.", data));
    }

    @GetMapping("/{supplierNumber}")
    public ResponseEntity<ApiResponse<SupplierDTO>> getSupplier(@PathVariable Integer supplierNumber) {
        try {
            SupplierDTO supplier = supplierService.getSupplierById(supplierNumber);
            return ResponseEntity.ok(ApiResponse.success("Supplier retrieved successfully.", supplier));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SupplierDTO>> createSupplier(@Valid @RequestBody SupplierDTO supplierDTO) {
        try {
            SupplierDTO newSupplier = supplierService.createSupplier(supplierDTO);
            return ResponseEntity.status(201).body(ApiResponse.success("Supplier has been saved successfully.", newSupplier));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Supplier cannot be saved. " + e.getMessage()));
        }
    }

    @PutMapping("/{supplierNumber}")
    public ResponseEntity<ApiResponse<SupplierDTO>> updateSupplier(
            @PathVariable Integer supplierNumber,
            @Valid @RequestBody SupplierDTO supplierDTO) {
        try {
            SupplierDTO updatedSupplier = supplierService.updateSupplier(supplierNumber, supplierDTO);
            return ResponseEntity.ok(ApiResponse.success("Supplier has been updated successfully.", updatedSupplier));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Supplier cannot be updated. " + e.getMessage()));
        }
    }

    @PatchMapping("/{supplierNumber}/status")
    public ResponseEntity<ApiResponse<SupplierDTO>> updateSupplierStatus(
            @PathVariable Integer supplierNumber,
            @RequestBody Map<String, String> request) {
        
        String newStatus = request.get("status");
        
        try {
            SupplierDTO updatedSupplier = supplierService.updateSupplierStatus(supplierNumber, newStatus);
            return ResponseEntity.ok(ApiResponse.success("Supplier status updated successfully.", updatedSupplier));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
