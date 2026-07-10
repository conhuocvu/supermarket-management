package com.supermarket.backend.controller;

import com.supermarket.backend.dto.CategoryDTO;
import com.supermarket.backend.service.CategoryService;
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
    public ResponseEntity<Map<String, Object>> getCategories(
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

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Category list loaded successfully.");
        response.put("data", data);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{categoryNumber}")
    public ResponseEntity<Map<String, Object>> getCategory(@PathVariable Integer categoryNumber) {
        try {
            CategoryDTO category = categoryService.getCategoryById(categoryNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Category retrieved successfully.");
            response.put("data", category);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> createCategory(@RequestBody CategoryDTO categoryDTO) {
        try {
            CategoryDTO newCategory = categoryService.createCategory(categoryDTO);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Category has been saved successfully.");
            response.put("data", newCategory);
            return ResponseEntity.status(201).body(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Category cannot be saved. " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PutMapping("/{categoryNumber}")
    public ResponseEntity<Map<String, Object>> updateCategory(
            @PathVariable Integer categoryNumber,
            @RequestBody CategoryDTO categoryDTO) {
        try {
            CategoryDTO updatedCategory = categoryService.updateCategory(categoryNumber, categoryDTO);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Category has been updated successfully.");
            response.put("data", updatedCategory);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Category cannot be updated. " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PatchMapping("/{categoryNumber}/status")
    public ResponseEntity<Map<String, Object>> updateCategoryStatus(
            @PathVariable Integer categoryNumber,
            @RequestBody Map<String, String> request) {
        
        String newStatus = request.get("status");
        
        try {
            CategoryDTO updatedCategory = categoryService.updateCategoryStatus(categoryNumber, newStatus);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Category status updated successfully.");
            response.put("data", updatedCategory);
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }
}
