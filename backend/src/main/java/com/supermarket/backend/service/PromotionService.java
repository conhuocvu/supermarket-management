package com.supermarket.backend.service;

import com.supermarket.backend.dto.PromotionDTO;
import com.supermarket.backend.dto.PromotionSummaryDTO;
import com.supermarket.backend.entity.Promotion;
import com.supermarket.backend.repository.PromotionRepository;
import lombok.RequiredArgsConstructor;
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

    public PromotionSummaryDTO getPromotionsSummary(String keyword, String status) {
        String filterStatus = (status == null || "ALL".equalsIgnoreCase(status)) ? null : status;
        
        List<Promotion> promotionsList;
        if (keyword != null && !keyword.trim().isEmpty()) {
            if (filterStatus != null) {
                promotionsList = promotionRepository.findByStatusIgnoreCaseAndPromotionNameContainingIgnoreCaseOrStatusIgnoreCaseAndPromoCodeContainingIgnoreCase(
                        filterStatus, keyword, filterStatus, keyword);
            } else {
                promotionsList = promotionRepository.findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(
                        keyword, keyword);
            }
        } else {
            if (filterStatus != null) {
                promotionsList = promotionRepository.findByStatusIgnoreCase(filterStatus);
            } else {
                promotionsList = promotionRepository.findAll();
            }
        }

        // Fetch all promotions (unfiltered by query parameters) to compute global statistics correctly,
        // or compute them from the database globally to keep dashboard stats consistent.
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

        List<PromotionDTO> dtoList = promotionsList.stream().map(this::mapToDTO).collect(Collectors.toList());

        return PromotionSummaryDTO.builder()
                .promotions(dtoList)
                .activeCount(active)
                .scheduledCount(scheduled)
                .expiredCount(expired)
                .avgDiscount(avgDiscount)
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
}
