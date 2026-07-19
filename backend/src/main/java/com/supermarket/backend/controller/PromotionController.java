package com.supermarket.backend.controller;

import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.CreatePromotionRequestDTO;
import com.supermarket.backend.dto.PromotionDTO;
import com.supermarket.backend.dto.PromotionDetailDTO;
import com.supermarket.backend.dto.PromotionSummaryDTO;
import com.supermarket.backend.dto.UpdatePromotionRequestDTO;
import com.supermarket.backend.service.PromotionService;
import com.supermarket.backend.service.SupabaseStorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/promotions")
@RequiredArgsConstructor
public class PromotionController {

    private final PromotionService promotionService;
    private final SupabaseStorageService supabaseStorageService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PromotionSummaryDTO>> getPromotions(
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        try {
            org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page, size);
            PromotionSummaryDTO data = promotionService.getPromotionsSummary(keyword, status, pageable);
            return ResponseEntity.ok(ApiResponse.success("Promotions list loaded successfully.", data));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load promotion data: " + e.getMessage()));
        }
    }

    @GetMapping("/{promotionNumber}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PromotionDetailDTO>> getPromotionDetail(
            @PathVariable("promotionNumber") Integer promotionNumber) {
        try {
            PromotionDetailDTO data = promotionService.getPromotionDetail(promotionNumber);
            return ResponseEntity.ok(ApiResponse.success("Promotion detail loaded successfully.", data));
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(e.getMessage()));
            }
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load promotion detail: " + e.getMessage()));
        }
    }

    @PostMapping
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<PromotionDTO>> createPromotion(
            @Valid @RequestBody CreatePromotionRequestDTO request) {
        try {
            PromotionDTO created = promotionService.createPromotion(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Promotion created successfully.", created));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to create promotion: " + e.getMessage()));
        }
    }

    @PutMapping("/{promotionNumber}")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<PromotionDTO>> updatePromotion(
            @PathVariable("promotionNumber") Integer promotionNumber,
            @Valid @RequestBody UpdatePromotionRequestDTO request) {
        try {
            PromotionDTO updated = promotionService.updatePromotion(promotionNumber, request);
            return ResponseEntity.ok(ApiResponse.success("Promotion updated successfully.", updated));
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(e.getMessage()));
            }
            if (e instanceof IllegalArgumentException) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error(e.getMessage()));
            }
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to update promotion: " + e.getMessage()));
        }
    }

    @PatchMapping("/{promotionNumber}/deactivate")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<Void>> deactivatePromotion(
            @PathVariable("promotionNumber") Integer promotionNumber) {
        try {
            promotionService.deactivatePromotion(promotionNumber);
            return ResponseEntity.ok(ApiResponse.success("Promotion deactivated successfully.", null));
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(e.getMessage()));
            }
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to deactivate promotion: " + e.getMessage()));
        }
    }

    @PostMapping("/{promotionNumber}/upload-image")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<ApiResponse<PromotionDTO>> uploadImage(
            @PathVariable("promotionNumber") Integer promotionNumber,
            @RequestParam("file") MultipartFile file) {
        try {
            String imageUrl = supabaseStorageService.uploadFile(file);
            PromotionDTO updated = promotionService.updatePromotionImageUrl(promotionNumber, imageUrl);
            return ResponseEntity.ok(ApiResponse.success("Image uploaded successfully.", updated));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to upload image: " + e.getMessage()));
        }
    }

    @GetMapping("/clearance-proposals/{stockInDetailNumber}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<com.supermarket.backend.dto.ClearanceProposalDataDTO>> getClearanceProposalData(
            @PathVariable("stockInDetailNumber") Integer stockInDetailNumber) {
        try {
            com.supermarket.backend.dto.ClearanceProposalDataDTO data = promotionService.loadClearanceProposalData(stockInDetailNumber);
            return ResponseEntity.ok(ApiResponse.success("Clearance proposal data loaded successfully.", data));
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(e.getMessage()));
            }
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Clearance proposal data cannot be loaded."));
        }
    }

    @PostMapping("/clearance-proposals")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Void>> submitClearanceProposal(
            @Valid @RequestBody com.supermarket.backend.dto.ClearanceProposalRequestDTO request) {
        try {
            promotionService.submitClearanceProposal(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Clearance proposal has been submitted successfully.", null));
        } catch (RuntimeException e) {
            if (e.getMessage() != null && e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error(e.getMessage()));
            }
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Clearance proposal cannot be submitted."));
        }
    }

    @GetMapping("/clearance-proposals/submitted")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<java.util.List<PromotionDTO>>> getSubmittedClearanceProposals() {
        try {
            java.util.List<PromotionDTO> data = promotionService.getSubmittedClearanceProposals();
            return ResponseEntity.ok(ApiResponse.success("Submitted clearance proposals loaded successfully.", data));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Unable to load submitted clearance proposals: " + e.getMessage()));
        }
    }
}

