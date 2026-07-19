package com.supermarket.backend.service;

import com.supermarket.backend.dto.ClearanceProposalDataDTO;
import com.supermarket.backend.dto.ClearanceProposalRequestDTO;
import com.supermarket.backend.dto.CreatePromotionRequestDTO;
import com.supermarket.backend.dto.PromotionDTO;
import com.supermarket.backend.dto.PromotionDetailDTO;
import com.supermarket.backend.dto.PromotionSummaryDTO;
import com.supermarket.backend.dto.UpdatePromotionRequestDTO;
import com.supermarket.backend.entity.Product;
import com.supermarket.backend.entity.Promotion;
import com.supermarket.backend.entity.PromotionProduct;
import com.supermarket.backend.entity.PromotionStatus;
import com.supermarket.backend.entity.StockInDetail;
import com.supermarket.backend.repository.ProductRepository;
import com.supermarket.backend.repository.PromotionProductRepository;
import com.supermarket.backend.repository.PromotionRepository;
import com.supermarket.backend.repository.StockInDetailRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PromotionService {

    private final PromotionRepository promotionRepository;
    private final PromotionProductRepository promotionProductRepository;
    private final StockInDetailRepository stockInDetailRepository;
    private final ProductRepository productRepository;

    public PromotionSummaryDTO getPromotionsSummary(String keyword, String status, Pageable pageable) {
        PromotionStatus filterStatus = null;
        if (status != null && !"ALL".equalsIgnoreCase(status)) {
            try {
                filterStatus = PromotionStatus.valueOf(status.toUpperCase().trim());
            } catch (IllegalArgumentException e) {
                // Invalid status string, ignore filter
            }
        }
        
        Page<Promotion> promotionsPage;
        if (keyword != null && !keyword.trim().isEmpty()) {
            if (filterStatus != null) {
                promotionsPage = promotionRepository.findByStatusAndPromotionNameContainingIgnoreCaseOrStatusAndPromoCodeContainingIgnoreCase(
                        filterStatus, keyword, filterStatus, keyword, pageable);
            } else {
                promotionsPage = promotionRepository.findByPromotionNameContainingIgnoreCaseOrPromoCodeContainingIgnoreCase(
                        keyword, keyword, pageable);
            }
        } else {
            if (filterStatus != null) {
                promotionsPage = promotionRepository.findByStatus(filterStatus, pageable);
            } else {
                promotionsPage = promotionRepository.findAll(pageable);
            }
        }

        long active = promotionRepository.countByStatus(PromotionStatus.ACTIVE);
        long scheduled = promotionRepository.countByStatus(PromotionStatus.SCHEDULED);
        long expired = promotionRepository.countByStatus(PromotionStatus.EXPIRED)
                + promotionRepository.countByStatus(PromotionStatus.INACTIVE);

        Double avg = promotionRepository.getAverageDiscountValue();
        double avgDiscount = avg != null ? BigDecimal.valueOf(avg).setScale(1, RoundingMode.HALF_UP).doubleValue() : 0.0;

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
                .status(entity.getStatus() != null ? entity.getStatus().name() : null)
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
                .status(promotion.getStatus() != null ? promotion.getStatus().name() : null)
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

        String statusStr = request.getStatus() != null ? request.getStatus() : "ACTIVE";
        PromotionStatus status = PromotionStatus.ACTIVE;
        try {
            status = PromotionStatus.valueOf(statusStr.toUpperCase().trim());
        } catch (IllegalArgumentException e) {
            // Leave as default ACTIVE
        }

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
            try {
                promotion.setStatus(PromotionStatus.valueOf(request.getStatus().toUpperCase().trim()));
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid promotion status: " + request.getStatus());
            }
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

        promotion.setStatus(PromotionStatus.EXPIRED);
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

    @Transactional(readOnly = true)
    public ClearanceProposalDataDTO loadClearanceProposalData(Integer stockInDetailNumber) {
        StockInDetail detail = stockInDetailRepository.findById(stockInDetailNumber)
                .orElseThrow(() -> new RuntimeException("Stock batch not found with number: " + stockInDetailNumber));

        Product product = productRepository.findById(detail.getProductNumber())
                .orElseThrow(() -> new RuntimeException("Product not found with number: " + detail.getProductNumber()));

        return ClearanceProposalDataDTO.builder()
                .stockInDetailNumber(detail.getStockInDetailNumber())
                .productNumber(product.getProductNumber())
                .productName(product.getProductName())
                .barcode(product.getBarcode())
                .batchNumber(detail.getBatchNumber())
                .expiryDate(detail.getExpiryDate())
                .remainingQuantity(detail.getRemainingQuantity())
                .sellingPrice(product.getSellingPrice())
                .importPrice(detail.getImportPrice())
                .build();
    }

    @Transactional
    public void submitClearanceProposal(ClearanceProposalRequestDTO request) {
        StockInDetail detail = stockInDetailRepository.findById(request.getStockInDetailNumber())
                .orElseThrow(() -> new RuntimeException("Stock batch not found."));

        Product product = productRepository.findById(request.getProductNumber())
                .orElseThrow(() -> new RuntimeException("Product not found."));

        Integer maxNumber = promotionRepository.findMaxPromotionNumber();
        int nextNumber = (maxNumber == null ? 0 : maxNumber) + 1;

        String proposalName = "Clearance: " + product.getProductName() + " (" + detail.getBatchNumber() + ")";

        Promotion promotion = Promotion.builder()
                .promotionNumber(nextNumber)
                .promotionName(proposalName)
                .discountValue(request.getDiscountPercentage())
                .status(PromotionStatus.PENDING)
                .startDate(LocalDate.now())
                .endDate(detail.getExpiryDate())
                .description(request.getReason())
                .category("CLEARANCE")
                .isFeatured(false)
                .build();

        Promotion saved = promotionRepository.save(promotion);

        PromotionProduct pp = PromotionProduct.builder()
                .promotionNumber(saved.getPromotionNumber())
                .productNumber(product.getProductNumber())
                .stockInDetailNumber(detail.getStockInDetailNumber())
                .status("PENDING")
                .product(product.getProductName())
                .build();

        promotionProductRepository.save(pp);
    }
}
