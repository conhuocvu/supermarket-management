package com.supermarket.backend.service;

import com.supermarket.backend.dto.StaffRequestDTO;
import com.supermarket.backend.entity.Promotion;
import com.supermarket.backend.entity.PromotionProduct;
import com.supermarket.backend.entity.PromotionStatus;
import com.supermarket.backend.entity.PurchaseRequest;
import com.supermarket.backend.repository.PromotionProductRepository;
import com.supermarket.backend.repository.PromotionRepository;
import com.supermarket.backend.repository.PurchaseRequestRepository;
import com.supermarket.backend.repository.StaffRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * Handles filtering, pagination and manager decisions
 * for staff leave, shift change, clearance, and purchase requests.
 */
@Service
public class StaffRequestService {

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 10;
    private static final int MAX_SIZE = 100;

    private static final Set<String> ALLOWED_REQUEST_TYPES = Set.of(
            "ALL",
            "LEAVE",
            "SHIFT_CHANGE",
            "CLEARANCE",
            "PURCHASE");

    private static final Set<String> ALLOWED_STATUSES = Set.of(
            "ALL",
            "PENDING",
            "APPROVED",
            "REJECTED");

    private static final Set<String> ACTION_REQUEST_TYPES = Set.of(
            "LEAVE",
            "SHIFT_CHANGE",
            "CLEARANCE",
            "PURCHASE");

    private static final Set<String> ACTION_STATUSES = Set.of(
            "APPROVED",
            "REJECTED");

    private final StaffRequestRepository staffRequestRepository;
    private final PromotionRepository promotionRepository;
    private final PromotionProductRepository promotionProductRepository;
    private final PurchaseRequestRepository purchaseRequestRepository;

    public StaffRequestService(
            StaffRequestRepository staffRequestRepository,
            PromotionRepository promotionRepository,
            PromotionProductRepository promotionProductRepository,
            PurchaseRequestRepository purchaseRequestRepository) {
        this.staffRequestRepository = staffRequestRepository;
        this.promotionRepository = promotionRepository;
        this.promotionProductRepository = promotionProductRepository;
        this.purchaseRequestRepository = purchaseRequestRepository;
    }

    public Map<String, Object> getStaffRequests(
            Integer page,
            Integer size,
            String requestType,
            String status,
            String keyword) {

        int safePage = normalizePage(page);
        int safeSize = normalizeSize(size);

        String safeRequestType = normalizeRequestType(requestType);
        String safeStatus = normalizeStatus(status);
        String safeKeyword = normalizeKeyword(keyword);

        int offset = safePage * safeSize;

        List<StaffRequestDTO> items = staffRequestRepository.findStaffRequests(
                safeRequestType,
                safeStatus,
                safeKeyword,
                safeSize,
                offset);

        long totalItems = staffRequestRepository.countStaffRequests(
                safeRequestType,
                safeStatus,
                safeKeyword);

        int totalPages = totalItems == 0
                ? 0
                : (int) Math.ceil((double) totalItems / safeSize);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("items", items);
        result.put("page", safePage);
        result.put("size", safeSize);
        result.put("totalItems", totalItems);
        result.put("totalPages", totalPages);

        return result;
    }

    @Transactional
    public Map<String, Object> updateStaffRequestStatus(
            Integer requestNumber,
            String requestType,
            String status) {

        if (requestNumber == null || requestNumber <= 0) {
            throw new IllegalArgumentException(
                    "Request number must be greater than zero.");
        }

        String safeRequestType = normalizeUppercaseValue(requestType);
        String safeStatus = normalizeUppercaseValue(status);

        if (!ACTION_REQUEST_TYPES.contains(safeRequestType)) {
            throw new IllegalArgumentException(
                    "Request type must be LEAVE, SHIFT_CHANGE, CLEARANCE, or PURCHASE.");
        }

        if (!ACTION_STATUSES.contains(safeStatus)) {
            throw new IllegalArgumentException(
                    "Status must be APPROVED or REJECTED.");
        }

        if ("CLEARANCE".equals(safeRequestType)) {
            Promotion promotion = promotionRepository.findByPromotionNumber(requestNumber)
                    .orElseThrow(() -> new IllegalStateException("Clearance request not found."));

            if (promotion.getStatus() != PromotionStatus.PENDING) {
                throw new IllegalStateException("Request has already been processed.");
            }

            PromotionStatus targetStatus = "APPROVED".equals(safeStatus)
                    ? PromotionStatus.ACTIVE
                    : PromotionStatus.INACTIVE;
            promotion.setStatus(targetStatus);
            promotionRepository.save(promotion);

            String ppStatus = "APPROVED".equals(safeStatus) ? "ACTIVE" : "REJECTED";
            List<PromotionProduct> pps = promotionProductRepository.findByPromotionNumber(requestNumber);
            for (PromotionProduct pp : pps) {
                pp.setStatus(ppStatus);
                promotionProductRepository.save(pp);
            }

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("requestNumber", requestNumber);
            result.put("requestType", safeRequestType);
            result.put("status", safeStatus);

            return result;
        }

        if ("PURCHASE".equals(safeRequestType)) {
            PurchaseRequest pr = purchaseRequestRepository.findById(requestNumber)
                    .orElseThrow(() -> new IllegalStateException("Purchase request not found."));

            if (!"PENDING".equals(pr.getStatus())) {
                throw new IllegalStateException("Request has already been processed.");
            }

            pr.setStatus("APPROVED".equals(safeStatus) ? "APPROVED" : "REJECTED");
            pr.setApprovedDate(LocalDateTime.now());
            purchaseRequestRepository.save(pr);

            Map<String, Object> result = new LinkedHashMap<>();
            result.put("requestNumber", requestNumber);
            result.put("requestType", safeRequestType);
            result.put("status", safeStatus);

            return result;
        }

        int updatedRows = staffRequestRepository.updateRequestStatus(
                safeRequestType,
                requestNumber,
                safeStatus);

        if (updatedRows == 0) {
            throw new IllegalStateException(
                    "Request was not found or has already been processed.");
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("requestNumber", requestNumber);
        result.put("requestType", safeRequestType);
        result.put("status", safeStatus);

        return result;
    }

    private int normalizePage(Integer page) {
        if (page == null || page < 0) {
            return DEFAULT_PAGE;
        }

        return page;
    }

    private int normalizeSize(Integer size) {
        if (size == null || size <= 0) {
            return DEFAULT_SIZE;
        }

        return Math.min(size, MAX_SIZE);
    }

    private String normalizeRequestType(String requestType) {
        String normalized = normalizeUppercaseValue(requestType);

        if (!ALLOWED_REQUEST_TYPES.contains(normalized)) {
            return "ALL";
        }

        return normalized;
    }

    private String normalizeStatus(String status) {
        String normalized = normalizeUppercaseValue(status);

        if (!ALLOWED_STATUSES.contains(normalized)) {
            return "ALL";
        }

        return normalized;
    }

    private String normalizeUppercaseValue(String value) {
        if (value == null || value.isBlank()) {
            return "ALL";
        }

        return value.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeKeyword(String keyword) {
        if (keyword == null) {
            return "";
        }

        return keyword.trim();
    }
}
