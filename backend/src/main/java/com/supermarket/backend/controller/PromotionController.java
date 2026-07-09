package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.PromotionCreateDto;
import com.supermarket.backend.dto.PromotionDto;
import com.supermarket.backend.service.PromotionService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/promotions")
public class PromotionController {

    private final PromotionService promotionService;

    @Autowired
    public PromotionController(PromotionService promotionService) {
        this.promotionService = promotionService;
    }

    @GetMapping
    public ApiResponse<List<PromotionDto>> getPromotions(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category) {
        List<PromotionDto> list = promotionService.getAllPromotions(search, category);
        return ApiResponse.success("Fetched promotions successfully.", list);
    }

    @GetMapping("/{id}")
    public ApiResponse<PromotionDto> getPromotionById(@PathVariable Long id) {
        PromotionDto promotion = promotionService.getPromotionById(id);
        return ApiResponse.success("Fetched promotion details successfully.", promotion);
    }

    @PostMapping
    public ApiResponse<PromotionDto> createPromotion(
            @Valid @RequestBody PromotionCreateDto dto) {
        PromotionDto created = promotionService.createPromotion(dto);
        return ApiResponse.success("Promotion created successfully.", created);
    }

    @PutMapping("/{id}")
    public ApiResponse<PromotionDto> updatePromotion(
            @PathVariable Long id,
            @Valid @RequestBody PromotionCreateDto dto) {
        PromotionDto updated = promotionService.updatePromotion(id, dto);
        return ApiResponse.success("Promotion updated successfully.", updated);
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> deletePromotion(@PathVariable Long id) {
        promotionService.deletePromotion(id);
        return ApiResponse.success("Promotion deleted successfully.", null);
    }
}
