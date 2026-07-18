package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.PromotionSummaryDTO;
import com.supermarket.backend.service.PromotionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/promotions")
@RequiredArgsConstructor
public class PromotionController {

    private final PromotionService promotionService;

    @GetMapping
    public ResponseEntity<ApiResponse<PromotionSummaryDTO>> getPromotions(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status", required = false) String status) {
        try {
            PromotionSummaryDTO data = promotionService.getPromotionsSummary(keyword, status);
            return ResponseEntity.ok(ApiResponse.success("Promotions list loaded successfully.", data));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load promotion data: " + e.getMessage()));
        }
    }
}
