package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.service.CategoryService;
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
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCategories(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("categoryName").ascending());
        Page<CategoryDTO> categories = categoryService.getCategories(keyword, pageRequest);

        Map<String, Object> data = new HashMap<>();
        data.put("items", categories.getContent());
        data.put("page", categories.getNumber());
        data.put("size", categories.getSize());
        data.put("totalItems", categories.getTotalElements());
        data.put("totalPages", categories.getTotalPages());

        return ResponseEntity.ok(ApiResponse.success("Category list loaded successfully.", data));
    }

    @GetMapping("/{categoryNumber}")
    public ResponseEntity<ApiResponse<CategoryDTO>> getCategory(@PathVariable Integer categoryNumber) {
        try {
            CategoryDTO category = categoryService.getCategoryById(categoryNumber);
            return ResponseEntity.ok(ApiResponse.success("Category retrieved successfully.", category));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CategoryDTO>> createCategory(@Valid @RequestBody CategoryDTO categoryDTO) {
        try {
            CategoryDTO newCategory = categoryService.createCategory(categoryDTO);
            return ResponseEntity.status(201).body(ApiResponse.success("Category has been saved successfully.", newCategory));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Category cannot be saved. " + e.getMessage()));
        }
    }

    @PutMapping("/{categoryNumber}")
    public ResponseEntity<ApiResponse<CategoryDTO>> updateCategory(
            @PathVariable Integer categoryNumber,
            @Valid @RequestBody CategoryDTO categoryDTO) {
        try {
            CategoryDTO updatedCategory = categoryService.updateCategory(categoryNumber, categoryDTO);
            return ResponseEntity.ok(ApiResponse.success("Category has been updated successfully.", updatedCategory));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Category cannot be updated. " + e.getMessage()));
        }
    }

    @PatchMapping("/{categoryNumber}/status")
    public ResponseEntity<ApiResponse<CategoryDTO>> updateCategoryStatus(
            @PathVariable Integer categoryNumber,
            @RequestBody Map<String, String> request) {
        
        String newStatus = request.get("status");
        
        try {
            CategoryDTO updatedCategory = categoryService.updateCategoryStatus(categoryNumber, newStatus);
            return ResponseEntity.ok(ApiResponse.success("Category status updated successfully.", updatedCategory));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}

