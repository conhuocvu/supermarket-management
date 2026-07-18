package com.supermarket.backend.service;

import com.supermarket.backend.dto.CreatePromotionRequestDTO;
import com.supermarket.backend.dto.PromotionDTO;
import com.supermarket.backend.dto.PromotionDetailDTO;
import com.supermarket.backend.dto.PromotionSummaryDTO;
import com.supermarket.backend.dto.UpdatePromotionRequestDTO;
import com.supermarket.backend.entity.Promotion;
import com.supermarket.backend.repository.PromotionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PromotionService {

    private final PromotionRepository promotionRepository;

    public PromotionSummaryDTO getPromotionsSummary(String keyword, String status, Pageable pageable) {
        String filterStatus = (status == null || "ALL".equalsIgnoreCase(status)) ? null : status;
        
        Page<Promotion> promotionsPage;
        if (keyword != null && !keyword.trim().isEmpty()) {
            if (filterStatus != null) {
                promotionsPage = promotionRepository.findByStatusIgnoreCaseAndPromotionNameContainingIgnoreCaseOrStatusIgnoreCaseAndPromoCodeContainingIgnoreCase(
                        filterStatus, keyword, filterStatus, keyword, pageable);
            } else {
                promotionsPage = promotionRepository.findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(
                        keyword, keyword, pageable);
            }
        } else {
            if (filterStatus != null) {
                promotionsPage = promotionRepository.findByStatusIgnoreCase(filterStatus, pageable);
            } else {
                promotionsPage = promotionRepository.findAll(pageable);
            }
        }

        List<Promotion> allPromotions = promotionRepository.findAll();

        long active = allPromotions.stream().filter(p -> "ACTIVE".equalsIgnoreCase(p.getStatus())).count();
        long scheduled = allPromotions.stream().filter(p -> "SCHEDULED".equalsIgnoreCase(p.getStatus())).count();
        long expired = allPromotions.stream().filter(p -> "EXPIRED".equalsIgnoreCase(p.getStatus())).count();

        double avgDiscount = 0.0;
        if (!allPromotions.isEmpty()) {
            double totalDiscount = allPromotions.stream()
                    .mapToDouble(p -> p.getDiscountValue() != null ? p.getDiscountValue() : 0.0)
                    .sum();
            double avg = totalDiscount / allPromotions.size();
            avgDiscount = BigDecimal.valueOf(avg).setScale(1, RoundingMode.HALF_UP).doubleValue();
        }

        List<PromotionDTO> dtoList = promotionsPage.getContent().stream().map(this::mapToDTO).collect(Collectors.toList());

        return PromotionSummaryDTO.builder()
                .promotions(dtoList)
                .activeCount(active)
                .scheduledCount(scheduled)
                .expiredCount(expired)
                .avgDiscount(avgDiscount)
                .currentPage(promotionsPage.getNumber())
                .totalPages(promotionsPage.getTotalPages())
                .totalElements(promotionsPage.getTotalElements())
                .build();
    }

    private PromotionDTO mapToDTO(Promotion entity) {
        return PromotionDTO.builder()
                .id(entity.getId())
                .promotionNumber(entity.getPromotionNumber())
                .promotionName(entity.getPromotionName())
                .discountValue(entity.getDiscountValue())
                .status(entity.getStatus())
                .startDate(entity.getStartDate())
                .endDate(entity.getEndDate())
                .description(entity.getDescription())
                .imageUrl(entity.getImageUrl())
                .visibility(entity.getVisibility())
                .promoCode(entity.getPromoCode())
                .category(entity.getCategory())
                .isFeatured(entity.getIsFeatured())
                .build();
    }

    public PromotionDetailDTO getPromotionDetail(Integer promotionNumber) {
        Promotion promotion = promotionRepository.findByPromotionNumber(promotionNumber)
                .orElseThrow(() -> new RuntimeException("Promotion not found with number: " + promotionNumber));

        List<Object[]> productRows = promotionRepository.findAssociatedProducts(promotionNumber);
        List<PromotionDetailDTO.ProductDTO> products = productRows.stream().map(row -> 
            PromotionDetailDTO.ProductDTO.builder()
                    .productName((String) row[0])
                    .barcode((String) row[1])
                    .sellingPrice((BigDecimal) row[2])
                    .build()
        ).collect(Collectors.toList());

        return PromotionDetailDTO.builder()
                .promotionNumber(promotion.getPromotionNumber())
                .promotionName(promotion.getPromotionName())
                .discountValue(promotion.getDiscountValue())
                .status(promotion.getStatus())
                .startDate(promotion.getStartDate())
                .endDate(promotion.getEndDate())
                .promoCode(promotion.getPromoCode())
                .description(promotion.getDescription())
                .products(products)
                .build();
    }

    @Transactional
    public PromotionDTO createPromotion(CreatePromotionRequestDTO request) {
        if (request.getEndDate() != null && request.getStartDate() != null
                && !request.getEndDate().isAfter(request.getStartDate())) {
            throw new IllegalArgumentException("End date must be after start date.");
        }

        Integer maxNumber = promotionRepository.findMaxPromotionNumber();
        int nextNumber = (maxNumber == null ? 0 : maxNumber) + 1;

        String status = request.getStatus() != null ? request.getStatus() : "ACTIVE";

        Promotion promotion = Promotion.builder()
                .promotionNumber(nextNumber)
                .promotionName(request.getPromotionName())
                .discountValue(request.getDiscountValue())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(status)
                .promoCode(request.getPromoCode() != null ? request.getPromoCode() : "")
                .category(request.getCategory() != null ? request.getCategory() : "")
                .description(request.getDescription())
                .isFeatured(false)
                .build();

        Promotion saved = promotionRepository.save(promotion);
        return mapToDTO(saved);
    }

    @Transactional
    public PromotionDTO updatePromotion(Integer promotionNumber, UpdatePromotionRequestDTO request) {
        Promotion promotion = promotionRepository.findByPromotionNumber(promotionNumber)
                .orElseThrow(() -> new RuntimeException("Promotion not found with number: " + promotionNumber));

        if (request.getPromotionName() != null && !request.getPromotionName().isBlank()) {
            promotion.setPromotionName(request.getPromotionName());
        }
        if (request.getDiscountValue() != null) {
            promotion.setDiscountValue(request.getDiscountValue());
        }
        if (request.getStartDate() != null) {
            promotion.setStartDate(request.getStartDate());
        }
        if (request.getEndDate() != null) {
            promotion.setEndDate(request.getEndDate());
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            promotion.setStatus(request.getStatus());
        }
        if (request.getPromoCode() != null) {
            promotion.setPromoCode(request.getPromoCode());
        }
        if (request.getCategory() != null) {
            promotion.setCategory(request.getCategory());
        }
        if (request.getDescription() != null) {
            promotion.setDescription(request.getDescription());
        }

        // Validate dates after applying updates
        if (promotion.getStartDate() != null && promotion.getEndDate() != null
                && !promotion.getEndDate().isAfter(promotion.getStartDate())) {
            throw new IllegalArgumentException("End date must be after start date.");
        }

        Promotion saved = promotionRepository.save(promotion);
        return mapToDTO(saved);
    }

    @Transactional
    public void deactivatePromotion(Integer promotionNumber) {
        Promotion promotion = promotionRepository.findByPromotionNumber(promotionNumber)
                .orElseThrow(() -> new RuntimeException("Promotion not found with number: " + promotionNumber));

        promotion.setStatus("INACTIVE");
        promotionRepository.save(promotion);
    }

    @Transactional
    public PromotionDTO updatePromotionImageUrl(Integer promotionNumber, String imageUrl) {
        Promotion promotion = promotionRepository.findByPromotionNumber(promotionNumber)
                .orElseThrow(() -> new RuntimeException("Promotion not found with number: " + promotionNumber));
        promotion.setImageUrl(imageUrl);
        Promotion saved = promotionRepository.save(promotion);
        return mapToDTO(saved);
    }
}
