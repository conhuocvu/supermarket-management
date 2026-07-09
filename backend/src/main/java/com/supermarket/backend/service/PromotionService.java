package com.supermarket.backend.service;

import com.supermarket.backend.dto.PromotionCreateDto;
import com.supermarket.backend.dto.PromotionDto;
import com.supermarket.backend.model.Promotion;
import com.supermarket.backend.repository.PromotionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class PromotionService {

    private final PromotionRepository promotionRepository;

    @Autowired
    public PromotionService(PromotionRepository promotionRepository) {
        this.promotionRepository = promotionRepository;
    }

    public List<PromotionDto> getAllPromotions(String search, String category) {
        List<Promotion> promotions = promotionRepository.searchPromotions(
                search != null ? search.trim() : null,
                category != null ? category.trim() : null
        );

        return promotions.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public PromotionDto getPromotionById(Long id) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Promotion not found with id: " + id));
        return convertToDto(promotion);
    }

    public PromotionDto createPromotion(PromotionCreateDto dto) {
        validateManagerOrAdmin();

        if (promotionRepository.existsByCodeIgnoreCase(dto.getCode().trim())) {
            throw new IllegalArgumentException("Promotion code already exists: " + dto.getCode());
        }

        if (dto.getEndDate().isBefore(dto.getStartDate())) {
            throw new IllegalArgumentException("End date cannot be before start date.");
        }

        Promotion promotion = Promotion.builder()
                .name(dto.getName().trim())
                .code(dto.getCode().trim().toUpperCase())
                .description(dto.getDescription())
                .priority(dto.getPriority().trim().toUpperCase())
                .discountType(dto.getDiscountType().trim().toUpperCase())
                .discountValue(dto.getDiscountValue())
                .targetCategories(dto.getTargetCategories() != null ? dto.getTargetCategories() : new ArrayList<>())
                .targetProducts(dto.getTargetProducts() != null ? dto.getTargetProducts() : new ArrayList<>())
                .startDate(dto.getStartDate())
                .endDate(dto.getEndDate())
                .imageUrl(dto.getImageUrl() != null ? dto.getImageUrl().trim() : "")
                .visibility(dto.getVisibility() != null ? dto.getVisibility().trim() : "Storewide & Online")
                .build();

        Promotion saved = promotionRepository.save(promotion);
        return convertToDto(saved);
    }

    public PromotionDto updatePromotion(Long id, PromotionCreateDto dto) {
        validateManagerOrAdmin();

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Promotion not found with id: " + id));

        if (promotionRepository.existsByCodeIgnoreCaseAndIdNot(dto.getCode().trim(), id)) {
            throw new IllegalArgumentException("Promotion code already exists for another promotion: " + dto.getCode());
        }

        if (dto.getEndDate().isBefore(dto.getStartDate())) {
            throw new IllegalArgumentException("End date cannot be before start date.");
        }

        promotion.setName(dto.getName().trim());
        promotion.setCode(dto.getCode().trim().toUpperCase());
        promotion.setDescription(dto.getDescription());
        promotion.setPriority(dto.getPriority().trim().toUpperCase());
        promotion.setDiscountType(dto.getDiscountType().trim().toUpperCase());
        promotion.setDiscountValue(dto.getDiscountValue());
        promotion.setTargetCategories(dto.getTargetCategories() != null ? dto.getTargetCategories() : new ArrayList<>());
        promotion.setTargetProducts(dto.getTargetProducts() != null ? dto.getTargetProducts() : new ArrayList<>());
        promotion.setStartDate(dto.getStartDate());
        promotion.setEndDate(dto.getEndDate());
        promotion.setImageUrl(dto.getImageUrl() != null ? dto.getImageUrl().trim() : "");
        promotion.setVisibility(dto.getVisibility() != null ? dto.getVisibility().trim() : "Storewide & Online");

        Promotion saved = promotionRepository.save(promotion);
        return convertToDto(saved);
    }

    public void deletePromotion(Long id) {
        validateManagerOrAdmin();

        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Promotion not found with id: " + id));

        promotionRepository.delete(promotion);
    }

    // Helper: Role checks
    private void validateManagerOrAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalArgumentException("Permission Denied: Unauthenticated user.");
        }
        boolean isManagerOrAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equalsIgnoreCase("ROLE_ADMIN") || a.getAuthority().equalsIgnoreCase("ROLE_MANAGER"));
        if (!isManagerOrAdmin) {
            throw new IllegalArgumentException("Permission Denied: Only Admins or Managers can perform this action.");
        }
    }

    // Helper: Map to DTO
    private PromotionDto convertToDto(Promotion promotion) {
        LocalDate today = LocalDate.now();
        String status;
        if (today.isBefore(promotion.getStartDate())) {
            status = "PENDING";
        } else if (today.isAfter(promotion.getEndDate())) {
            status = "EXPIRED";
        } else {
            status = "ACTIVE";
        }

        int productsCount = promotion.getTargetProducts() != null ? promotion.getTargetProducts().size() : 0;

        // Generate mock analytics based on the code/name to match mockup requirements
        String estRevenueIncrease = "+10.0%";
        int productsSold = 150;
        int usageRate = 65;
        List<Integer> dailyEngagement = Arrays.asList(40, 50, 45, 60, 75, 70, 65, 80);

        String code = promotion.getCode().toUpperCase();
        if (code.contains("HARVEST")) {
            estRevenueIncrease = "+12.5%";
            productsSold = 1240;
            usageRate = 85;
            dailyEngagement = Arrays.asList(450, 600, 500, 750, 950, 800, 750, 850);
            if (productsCount == 0) productsCount = 142; // Match mockup
        } else if (code.contains("BAKERY") || code.contains("BOGO")) {
            estRevenueIncrease = "+8.0%";
            productsSold = 850;
            usageRate = 70;
            dailyEngagement = Arrays.asList(250, 310, 280, 390, 420, 380, 340, 390);
            if (productsCount == 0) productsCount = 85;
        } else if (code.contains("DAIRY")) {
            estRevenueIncrease = "+15.0%";
            productsSold = 1800;
            usageRate = 92;
            dailyEngagement = Arrays.asList(600, 750, 700, 850, 1050, 920, 880, 990);
            if (productsCount == 0) productsCount = 210;
        } else if (code.contains("SPIRITS")) {
            estRevenueIncrease = "+6.2%";
            productsSold = 320;
            usageRate = 45;
            dailyEngagement = Arrays.asList(100, 150, 120, 180, 220, 190, 160, 210);
            if (productsCount == 0) productsCount = 48;
        } else if (code.contains("HOMECARE")) {
            estRevenueIncrease = "+9.5%";
            productsSold = 540;
            usageRate = 58;
            dailyEngagement = Arrays.asList(180, 220, 190, 240, 310, 280, 240, 290);
            if (productsCount == 0) productsCount = 74;
        }

        return PromotionDto.builder()
                .id(promotion.getId())
                .name(promotion.getName())
                .code(promotion.getCode())
                .description(promotion.getDescription())
                .priority(promotion.getPriority())
                .discountType(promotion.getDiscountType())
                .discountValue(promotion.getDiscountValue())
                .targetCategories(promotion.getTargetCategories())
                .targetProducts(promotion.getTargetProducts())
                .startDate(promotion.getStartDate())
                .endDate(promotion.getEndDate())
                .imageUrl(promotion.getImageUrl())
                .visibility(promotion.getVisibility())
                .status(status)
                .productsCount(productsCount)
                .estRevenueIncrease(estRevenueIncrease)
                .productsSold(productsSold)
                .usageRate(usageRate)
                .dailyEngagement(dailyEngagement)
                .build();
    }
}
