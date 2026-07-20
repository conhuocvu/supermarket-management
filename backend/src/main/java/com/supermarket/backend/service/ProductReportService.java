package com.supermarket.backend.service;

import com.supermarket.backend.dto.CreateProductReportDTO;
import com.supermarket.backend.dto.ProductReportDTO;
import com.supermarket.backend.dto.RoleNumber;
import com.supermarket.backend.dto.SuggestProductUpdateDTO;
import com.supermarket.backend.entity.Notification;
import com.supermarket.backend.entity.Product;
import com.supermarket.backend.entity.ProductReport;
import com.supermarket.backend.repository.NotificationRepository;
import com.supermarket.backend.repository.ProductReportRepository;
import com.supermarket.backend.repository.ProductRepository;
import com.supermarket.backend.repository.ProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Sales Associate product reports: inventory issue reports and product update
 * suggestions. Backed by the existing product_reports table — issues are
 * report_type = 'INVENTORY_ISSUE', suggestions are 'UPDATE_SUGGESTION'. These
 * are kept distinct from the manager stock-out report types
 * (DAMAGED/NEAR_EXPIRY/QUALITY_ISSUE/DELIVERY_DISCREPANCY) so existing flows
 * are unaffected.
 */
@Service
@RequiredArgsConstructor
public class ProductReportService {

    public static final String TYPE_INVENTORY_ISSUE = "INVENTORY_ISSUE";
    public static final String TYPE_UPDATE_SUGGESTION = "UPDATE_SUGGESTION";
    public static final String STATUS_PENDING = "PENDING";

    private final ProductReportRepository productReportRepository;
    private final ProductRepository productRepository;
    private final ProfileRepository profileRepository;
    private final NotificationRepository notificationRepository;

    @Transactional
    public ProductReportDTO createInventoryIssue(CreateProductReportDTO request, UUID reportedBy) {
        if (request.getProductNumber() == null) {
            throw new IllegalArgumentException("Product is required.");
        }
        if (request.getIssueType() == null || request.getIssueType().trim().isEmpty()) {
            throw new IllegalArgumentException("Issue type is required.");
        }
        if (request.getQuantity() == null || request.getQuantity().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Quantity must be greater than zero.");
        }

        Product product = productRepository.findById(request.getProductNumber())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Product not found: " + request.getProductNumber()));

        ProductReport report = ProductReport.builder()
                .reportedBy(reportedBy)
                .productNumber(product.getProductNumber())
                .reportType(TYPE_INVENTORY_ISSUE)
                .issueType(request.getIssueType().trim().toUpperCase())
                .quantity(request.getQuantity().abs())
                .description(request.getDescription() != null ? request.getDescription().trim() : null)
                .status(STATUS_PENDING)
                .createdAt(LocalDateTime.now())
                .build();

        report = productReportRepository.save(report);

        // Inventory issues go to the Stock Controllers for handling.
        notifyRole(RoleNumber.STOCK_CONTROLLER,
                "New Inventory Issue Report",
                "Report #" + report.getReportNumber() + ": " + report.getIssueType()
                        + " x" + report.getQuantity().stripTrailingZeros().toPlainString()
                        + " - " + product.getProductName());

        return toDTO(report, product);
    }

    @Transactional
    public ProductReportDTO createUpdateSuggestion(SuggestProductUpdateDTO request, UUID reportedBy) {
        if (request.getProductNumber() == null) {
            throw new IllegalArgumentException("Product is required.");
        }

        Product product = productRepository.findById(request.getProductNumber())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Product not found: " + request.getProductNumber()));

        // The suggested changes are encoded in the description so no schema
        // change is needed; a manager reviews them before applying.
        StringBuilder desc = new StringBuilder();
        if (request.getSuggestedName() != null && !request.getSuggestedName().trim().isEmpty()) {
            desc.append("Name: ").append(request.getSuggestedName().trim()).append("; ");
        }
        if (request.getSuggestedSellingPrice() != null) {
            desc.append("Selling price: ").append(request.getSuggestedSellingPrice()).append("; ");
        }
        if (request.getReason() != null && !request.getReason().trim().isEmpty()) {
            desc.append("Reason: ").append(request.getReason().trim());
        }
        if (desc.length() == 0) {
            throw new IllegalArgumentException("At least one suggested change or a reason is required.");
        }

        ProductReport report = ProductReport.builder()
                .reportedBy(reportedBy)
                .productNumber(product.getProductNumber())
                .reportType(TYPE_UPDATE_SUGGESTION)
                .issueType("PRICE_OR_INFO")
                .description(desc.toString())
                .status(STATUS_PENDING)
                .createdAt(LocalDateTime.now())
                .build();

        report = productReportRepository.save(report);

        // Update suggestions go to the Managers for review.
        notifyRole(RoleNumber.MANAGER,
                "New Product Update Suggestion",
                "Suggestion #" + report.getReportNumber() + " for "
                        + product.getProductName() + ": " + desc);

        return toDTO(report, product);
    }

    @Transactional(readOnly = true)
    public List<ProductReportDTO> getUserReports(UUID reportedBy, String reportType) {
        List<ProductReport> reports = (reportType == null || reportType.trim().isEmpty())
                ? productReportRepository.findByReportedByOrderByCreatedAtDesc(reportedBy)
                : productReportRepository.findByReportedByAndReportTypeOrderByCreatedAtDesc(
                        reportedBy, reportType.trim().toUpperCase());

        return reports.stream()
                .map(r -> toDTO(r, productRepository.findById(r.getProductNumber()).orElse(null)))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ProductReportDTO getReport(Integer reportNumber, UUID reportedBy) {
        ProductReport report = productReportRepository.findById(reportNumber)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Product report not found: " + reportNumber));
        if (report.getReportedBy() == null || !report.getReportedBy().equals(reportedBy)) {
            throw new SecurityException("You are not authorised to view this report.");
        }
        return toDTO(report, productRepository.findById(report.getProductNumber()).orElse(null));
    }

    /** Inserts an in-app notification for every active user with the given role. */
    private void notifyRole(RoleNumber role, String title, String content) {
        // Truncate to fit the varchar column comfortably
        String safeContent = content.length() > 250 ? content.substring(0, 247) + "..." : content;
        profileRepository.findActiveByRoleNumber(role.getValue()).forEach(profile ->
                notificationRepository.save(Notification.builder()
                        .userId(profile.getUserId())
                        .title(title)
                        .content(safeContent)
                        .isRead(false)
                        .createdDate(LocalDateTime.now())
                        .build()));
    }

    private ProductReportDTO toDTO(ProductReport report, Product product) {
        return ProductReportDTO.builder()
                .reportNumber(report.getReportNumber())
                .productNumber(report.getProductNumber())
                .productName(product != null ? product.getProductName() : null)
                .barcode(product != null ? product.getBarcode() : null)
                .reportType(report.getReportType())
                .issueType(report.getIssueType())
                .quantity(report.getQuantity())
                .description(report.getDescription())
                .status(report.getStatus())
                .createdAt(report.getCreatedAt())
                .resolvedAt(report.getResolvedAt())
                .build();
    }
}
