package com.supermarket.backend.controller;

import com.auth0.jwt.JWT;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.supermarket.backend.dto.ApiResponse;
import com.supermarket.backend.dto.CreateProductReportDTO;
import com.supermarket.backend.dto.ProductReportDTO;
import com.supermarket.backend.dto.SuggestProductUpdateDTO;
import com.supermarket.backend.service.ProductReportService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Sales Associate product reports: inventory issue reports, product update
 * suggestions, and report-status listing. Ownership is enforced from the JWT
 * subject (same decode-only approach as NotificationController).
 */
@RestController
@RequestMapping("/api/product-reports")
@RequiredArgsConstructor
public class ProductReportController {

    private final ProductReportService productReportService;

    /** Files an inventory issue report for the authenticated user. */
    @PostMapping("/issues")
    public ResponseEntity<ApiResponse<ProductReportDTO>> createIssue(
            @RequestBody CreateProductReportDTO body,
            HttpServletRequest request) {
        try {
            UUID userId = currentUserId(request);
            ProductReportDTO created = productReportService.createInventoryIssue(body, userId);
            return ResponseEntity.ok(ApiResponse.success("Inventory issue reported successfully.", created));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to report inventory issue: " + e.getMessage()));
        }
    }

    /** Files a product update suggestion for the authenticated user. */
    @PostMapping("/suggestions")
    public ResponseEntity<ApiResponse<ProductReportDTO>> createSuggestion(
            @RequestBody SuggestProductUpdateDTO body,
            HttpServletRequest request) {
        try {
            UUID userId = currentUserId(request);
            ProductReportDTO created = productReportService.createUpdateSuggestion(body, userId);
            return ResponseEntity.ok(ApiResponse.success("Update suggestion submitted successfully.", created));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to submit suggestion: " + e.getMessage()));
        }
    }

    /**
     * Reports filed by the authenticated user, newest first.
     * Optional reportType filter (INVENTORY_ISSUE / UPDATE_SUGGESTION).
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<ProductReportDTO>>> getMyReports(
            @RequestParam(value = "reportType", required = false) String reportType,
            HttpServletRequest request) {
        try {
            UUID userId = currentUserId(request);
            List<ProductReportDTO> reports = productReportService.getUserReports(userId, reportType);
            return ResponseEntity.ok(ApiResponse.success("Reports loaded successfully.", reports));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load reports: " + e.getMessage()));
        }
    }

    /** A single report owned by the authenticated user. */
    @GetMapping("/{reportNumber}")
    public ResponseEntity<ApiResponse<ProductReportDTO>> getReport(
            @PathVariable Integer reportNumber,
            HttpServletRequest request) {
        try {
            UUID userId = currentUserId(request);
            ProductReportDTO report = productReportService.getReport(reportNumber, userId);
            return ResponseEntity.ok(ApiResponse.success("Report loaded successfully.", report));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(ApiResponse.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.error("Failed to load report: " + e.getMessage()));
        }
    }

    /** Extracts the user id from the JWT subject (decode only). */
    private UUID currentUserId(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new SecurityException("Authentication required.");
        }
        try {
            String token = authHeader.substring(7);
            DecodedJWT decoded = JWT.decode(token);
            String sub = decoded.getSubject();
            if (sub == null || sub.isEmpty()) {
                throw new SecurityException("Invalid authentication token.");
            }
            return UUID.fromString(sub);
        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("Invalid authentication token: " + e.getMessage());
        }
    }
}
