package com.supermarket.backend.controller;

import com.supermarket.backend.dto.*;
import com.supermarket.backend.service.SupplierService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/suppliers")
public class SupplierController {

    private final SupplierService supplierService;

    @Autowired
    public SupplierController(SupplierService supplierService) {
        this.supplierService = supplierService;
    }


    @GetMapping
    public ApiResponse<List<SupplierDto>> getSuppliers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category) {
        List<SupplierDto> list = supplierService.getAllSuppliers(search, category);
        return ApiResponse.success("Fetched suppliers successfully.", list);
    }

    @GetMapping("/{id}")
    public ApiResponse<SupplierDto> getSupplierById(@PathVariable Long id) {
        SupplierDto supplier = supplierService.getSupplierById(id);
        return ApiResponse.success("Fetched supplier details successfully.", supplier);
    }

    @PostMapping
    public ApiResponse<SupplierDto> createSupplier(@Valid @RequestBody SupplierCreateDto dto) {
        SupplierDto created = supplierService.createSupplier(dto);
        return ApiResponse.success("Supplier created successfully.", created);
    }

    @PutMapping("/{id}")
    public ApiResponse<SupplierDto> updateSupplier(
            @PathVariable Long id,
            @Valid @RequestBody SupplierCreateDto dto) {
        SupplierDto updated = supplierService.updateSupplier(id, dto);
        return ApiResponse.success("Supplier updated successfully.", updated);
    }

    @PatchMapping("/{id}/status")
    public ApiResponse<SupplierDto> updateSupplierStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String status = body.get("status");
        if (status == null || status.trim().isEmpty()) {
            throw new IllegalArgumentException("Status is required");
        }
        SupplierDto updated = supplierService.updateSupplierStatus(id, status);
        return ApiResponse.success("Supplier status updated successfully.", updated);
    }

    @GetMapping("/{id}/products")
    public ApiResponse<List<SupplierProductDto>> getSupplierProducts(@PathVariable Long id) {
        List<SupplierProductDto> list = supplierService.getSupplierProducts(id);
        return ApiResponse.success("Fetched supplier products successfully.", list);
    }

    @PostMapping("/{id}/products")
    public ApiResponse<List<SupplierProductDto>> assignProducts(
            @PathVariable Long id,
            @Valid @RequestBody List<SupplierProductAssignDto> assignments) {
        List<SupplierProductDto> list = supplierService.assignProducts(id, assignments);
        return ApiResponse.success("Products assigned successfully.", list);
    }
}
